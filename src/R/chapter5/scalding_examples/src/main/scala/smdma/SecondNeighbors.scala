package smdma

import com.twitter.scalding._
import ExecutionContext._

/**
 * Given a list edges, A -> B, we want all the pairs
 * of nodes connected by a third: A -> _ -> B, we should emit A, B
 *
 * ./sbt "run --hdfs -Dsmdma.output=test -Dsmdma.edges=data/small_graph.tsv"
 *
 * main scalding functions used:
 * map, group, join, distinct
 */
object SecondNeighbors extends ExecutionApp {
  def job = Execution.getConfig.flatMap { config =>
    /* This gives an input by looking up from the config:
     * The input file looks like:
     * source <tab> destination
     */
    def input(name: String) =
      TypedPipe.from(TypedTsv[(Long, Long)](config.get(name).get))

    val edges = input("smdma.edges")
    val output = TypedTsv[(Long, Long)](config.get("smdma.output").get)

    /*
     * Now, we join with step with itself, but with the edges swaped on the left:
     * We want the key to be the destination on the left, but the source on the right.
     */
    edges
      // reverse each edge. This could also be written as .swap
      .map { case (from, to) => (to, from) }
      .join(edges)
      /*
       * We don't care about the intermediate node, so discard the key:
       * this could also be written as .values
       */
      .map { case (middleNode, (from, to)) => (from, to) }
      /*
       * now we need to de-dup the pairs since there may be more than one path:
       * distinct is the same as a trivial reduce and ignoring the values:
       * data.map { item => (item, None) }.group.reduce { (l, r) => None }.map { case (k, v) => k }
       */
      .distinct
      .writeExecution(output)
  }
}
