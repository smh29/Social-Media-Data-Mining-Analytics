package smdma

import com.twitter.scalding._
import ExecutionContext._
import com.twitter.scalding.source.TypedSequenceFile

import com.twitter.algebird.monad.Reader
import scala.util.Try
import java.util.UUID
/**
 * Given a list edges, A -> B
 * PageRank is a popular metric for nodes in directed graphs.
 * Imagine you are on any node. With probability alpha you
 * jump to a random node in the network. With probability
 * (1-alpha) you choose a random neighbor that you point to,
 * and jump there. Clearly, the total sum of the probability
 * is 1. Instead of normalizing by 1, we could normalize by N,
 * and so we output N*probability. This will be helpful in
 * comparing PageRank independent of network size as well
 * as being slightly easier to compute.
 *
 * This process is repeated infinitely (in reality, only until
 * the change is not very much).
 *
 * This is a rather advanced example.
 *
 * You can run it in the root of the project directory with:
 * ./sbt "run --hdfs -Dsmdma.pagerank.output=prout -Dsmdma.pagerank.graph=prgraph"
 * where you have supplied a TSV file in prgraph with the pairs of edges
 */

object PageRank extends ExecutionApp {
  /*
   * This is a function that does the main step of page-rank vector propagation.
   * old is the old vector, and we are multiplying that vector by the graph
   * matrix. Compare this code with the Matrix multiplication code
   */
  def doPageRankStep(alpha: Double, graph: TypedPipe[(Long, (Long, Int))],
    oldPR: TypedPipe[(Long, Double)]): Execution[TypedPipe[(Long, Double)]] =
      graph.outerJoin(oldPR)
        .map {
          case (from, (Some((to, fromDegree)), Some(weight))) =>
            (to, weight / fromDegree)
          case (from, (Some((to, fromDegree)), None)) => (to, 0.0)
          // This is the case where from has no out-degrees, AND no one
          // points to from. In that case, the final rank will be alpha,
          // but that that is handled by the mapValues case below
          case (from, (None, _)) => (from, 0.0)
        }
        .sumByKey
        .map { case (node, newWeight) => (node, (1.0 - alpha) * newWeight + alpha) }
        .forceToDiskExecution

  /*
   * This is just |oldPR - newPR|^2
   */
  def computeRMSError(oldPR: TypedPipe[(Long, Double)],
    newPR: TypedPipe[(Long, Double)]): Execution[Double] =
      oldPR.outerJoin(newPR)
        .map { case (node, (oldv, newv)) =>
          val err = (oldv.getOrElse(0.0) - newv.getOrElse(0.0))
          (1L, err * err)
        }
        .sum
        .toOptionExecution
        .map {
          case None => 0.0 // Happens if the input was empty
          case Some((n, err)) => err / n
        }

  def job: Execution[Unit] = Execution.getConfig.flatMap { config =>
    // Set the jump probability
    val alpha = config.get("smdma.pagerank.alpha").getOrElse("0.15").toDouble
    val threshold = config.get("smdma.pagerank.threshold").getOrElse("0.1").toDouble
    val output = TypedTsv[(Long, Double)](
      config.get("smdma.pagerank.output")
        .getOrElse(sys.error("must supply -Dsmdma.pagerank.output=<output>")))

    val edges = TypedPipe.from(TypedTsv[(Long, Long)](
        config.get("smdma.pagerank.graph")
          .getOrElse(sys.error("must supply -Dsmdma.pagerank.graph=<graph>"))))

    // This is a job we run to prepare the graph
    val graphWithDegrees: Execution[TypedPipe[(Long, (Long, Int))]] = {
        // We need to know the out-degree of each edge.
        val outDegree = edges.map { case (from, to) => (from, 1) }.sumByKey
        // now join this to the edges,
        edges.join(outDegree).forceToDiskExecution
      }
    /*
     * This is the initial page rank, which if we have already run
     * this code on a similar graph, we might initialize from that run
     */
    val initPageRank: Execution[TypedPipe[(Long, Double)]] = config.get("smdma.pagerank.init") match {
      case None => // initialize from the graph
        edges
          .flatMap { case (from, to) => List(from, to) }
          .distinct
          .map { node => (node, 1.0) } // initialize all with weight 1.0
          .forceToDiskExecution
      case Some(prev) => Execution.from(TypedPipe.from(TypedTsv[(Long, Double)](prev)))
    }
    /*
     * Here is the main loop expressed in a recursive style.
     * 1) do pagerank step
     * 2) compute the error
     * 3) if the error is low enough, write the result, else recurse
     */
    def run(graph: TypedPipe[(Long, (Long, Int))],
            oldPR: TypedPipe[(Long, Double)]): Execution[Unit] = for {
      newPR <- doPageRankStep(alpha, graph, oldPR)
      err   <- computeRMSError(oldPR, newPR)
      unit  <- if (err < threshold) newPR.writeExecution(output) else run(graph, newPR)
    } yield unit

    for {
      (g, pr) <- graphWithDegrees.zip(initPageRank)
      unit <- run(g, pr)
    } yield unit
  }
}
