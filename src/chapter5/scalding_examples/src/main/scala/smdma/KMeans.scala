package smdma

import com.twitter.scalding._
import com.twitter.scalding.typed.ComputedValue
import Execution._

import com.twitter.algebird.monad.Reader
import com.twitter.algebird.{Group, Monoid, VectorSpace}
import scala.util.Try
import java.util.UUID

/**
 * Given a number of clusters, and a list of points,
 * output a list of points and their cluster
 *
 * This is useful for seeing broad groups in your data
 * that are similar by the distance metric you choose.
 *
 * This is a rather advanced example.
 *
 * You can run it in the root of the project directory with:
 * ./sbt "run --hdfs PageRank -Dsmdma.pagerank.output=prout -Dsmdma.pagerank.graph=prgraph"
 * where you have supplied a TSV file in prgraph with the pairs of edges
 */

object KMeans extends ExecutionApp {
  /**
   * We use a Map[String, Double] to represent a sparse vector
   */
  type Vect = Map[String, Double]
  type LabeledVector = (Int, Vect)
  type ClusterPipe = ValuePipe[List[LabeledVector]]
  type PointPipe = TypedPipe[(String, LabeledVector)]

  /**
   * This is the euclidean norm between two vectors
   */
  def distance(v1: Vect, v2: Vect): Double =
    math.sqrt(Group.minus(v1, v2).map { case (k, v) => v*v}.sum)

  // Just normal vector addition
  def add(v1: Vect, v2: Vect): Vect = Monoid.plus(v1, v2)

  // normal scalar multiplication
  def scale(s: Double, v: Vect): Vect =
    v.mapValues { element => s * element }

  // Here we return the centroid of some vectors
  def centroidOf(vecs: TraversableOnce[Vect]): Vect = {
    val (vec, count) = vecs
      // add a 1 to each value to count the number of vectors in one pass:
      .map { v => (v, 1) }
      // Here we add both the count and the vectors:
      .reduce { (ll, rr) =>
        val (l, lc) = ll
        val (r, rc) = rr
        (add(l, r), lc + rc)
      }
    // Now scale to get the pointwise average
    scale(1.0/count, vec)
  }

  def closest(from: Vect,
    centroids: TraversableOnce[LabeledVector]): LabeledVector =
    centroids
      // compute the distance to each center
      .map { case (id, cent) => (distance(from, cent), (id, cent)) }
      // take the minimum by the distance, ignoring the id and the centroid
      .minBy { case (dist, _) => dist }
      // Just keep the id and the centroid
      ._2

  def kmeansStep(clusters: ClusterPipe,
    points: PointPipe): Execution[(Long, ClusterPipe, PointPipe)] = {

    // Do a cross product to produce all point, cluster pairs
    // in scalding, the smaller pipe should go on the right.
    val next = points.leftCross(clusters)
      // now compute the closest cluster for each vector
      .map {
        // we only handle the case were the cluster
        case ((name, (oldId, vector)), Some(centroids)) =>
          val (id, newcentroid) = closest(vector, centroids)
          (name, id, vector, oldId)

        case (_, None) => sys.error("There were no centoids")
      }
      // this tells scalding not to recompute this part (TODO it is better to use stats here)
      .forceToDiskExecution

    // How many vectors changed?
    val changedVectors: Execution[Long] =
      for {
        pipe <- next
        changes <- (pipe.collect { case (_, newId, _, oldId) if (newId != oldId) => 1L }
        // sum on a pipe adds everything in that pipe
        .sum
        .toOptionExecution)
      } yield (changes.getOrElse(0L))

    // Now update the clusters:
    val nextCluster: Execution[ClusterPipe] =
      for {
        pipe <- next
        clusters = ComputedValue(pipe
          .map { case (name, newId, vector, oldId) => (newId, vector) }
          .group
          .mapValueStream { vectors => Iterator(centroidOf(vectors)) }
          // Now collect them all into one big
          .groupAll
          .toList
          // discard the "all" key used to group them together
          .values)
      } yield clusters

    val nextVectors: Execution[PointPipe] =
      for {
        pipe <- next
        nextVs = pipe.map { case (name, newId, vector, oldId) => (name, (newId, vector)) }
      } yield nextVs
    /**
     * zip combines all these Executions into one
     */
    Execution.zip(changedVectors, nextCluster, nextVectors)
  }

  /**
   * This treats a line like: a: b
   * as the vector with label "a" having 1.0 in the "b" component
   */
  def toEdge(string: String): (String, Vect) =
    string.split(": ").toList match {
      case List(a, b, x) => (a, Map(b -> x.toDouble))
      case List(a, b) => (a, Map(b -> 1.0))
      case _ => sys.error("could not parse: " + string)
    }

  def job: Execution[Unit] = getConfig.flatMap { config =>
    val clusters = config.get("smdma.kmeans.clusters")
      .getOrElse(sys.error("Must give: option smdma.kmeans.clusters as an integer"))
      .toInt

    val output = TypedTsv[(String, Int)](
      config.get("smdma.kmeans.output.vectors")
        .getOrElse(sys.error("must supply -Dsmdma.kmeans.output.vectors=<output>")))

    /**
     * This is a list of named components of the vectors:
     * a: b: x
     * means vector "a" in the "b" component has value x.
     * If there is no : x, : 1 is assumed
     */
    val input = TextLine(config.get("smdma.kmeans.components")
        .getOrElse(sys.error("must supply -Dsmdma.kmeans.components=<input>")))

    val rng = new java.util.Random
    /**
     * First we group all the components and sum up the vectors which
     * were initially just recorded in a sparse, one-component-at-a-time
     * fashion
     */
    val initVectors: Execution[TypedPipe[(String, Vect)]] =
      TypedPipe.from(input)
        .map(toEdge)
        .group
        .sum(implicitly[Group[Vect]])
        .forceToDiskExecution

    /** Now we randomly select a few of the products to be the initial
     * centroids
     */
    val initClusters: Execution[ClusterPipe] = initVectors.map { init =>
      ComputedValue(init
        .map { case (name, vect) => (rng.nextDouble, vect) }
        // After we groupall, there will only be one final value
        // we get: the list of all clusters. We use ComputedValue
        // to signify that there is only one item
        .groupAll
        .sortWithTake(clusters) { case ((rand0, _), (rand1, _) ) => rand0 < rand1 }
        .map { case (_, clusters) =>
          clusters
            // attach the cluster id
            .zipWithIndex
            // put it in the first position
            .map { case ((_, vect), id) => (id, vect) }
            // make sure we have a List
            .toList
        })
    }
    // Attach a random initial cluster id:
    val initVectorsId: Execution[PointPipe] =
      initVectors.map { pipe: TypedPipe[(String, Vect)] =>
        pipe.map { case (name, vect) => (name, (rng.nextInt(clusters), vect)) }
      }

    /**
     * This is the main loop of the program.
     * we take a step, and if we are done, we stop, else
     * we recursively call this program
     */
    def run(step: Int, c: ClusterPipe, v: PointPipe): Execution[Unit] =
      kmeansStep(c, v).flatMap {
        case (0L, _, vects) =>
          // No changes, so we are done:
          println("K-means converged after %d steps".format(step))
          vects.map { case (name, (id, _)) => (name, id) }.writeExecution(output)
        case (x, newCentroids, vects) =>
          // Else there were some vectors that moved:
          println("%d vectors changed".format(x))
          run(step + 1, newCentroids, vects)
      }

    for {
      c <- initClusters
      v <- initVectorsId
      unit <- run(1, c, v)
    } yield unit
  }
}
