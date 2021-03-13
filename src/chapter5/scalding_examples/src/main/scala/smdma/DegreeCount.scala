package smdma

import com.twitter.scalding._
import ExecutionContext._

/**
 * Given a list edges, A -> B
 * print the number of edges that point to each node
 * This is really just another kind of word count,
 * which we have seen so many times.
 *
 * ./sbt "run --local -Dsmdma.edges=data/small_graph.tsv -Dsmdma.output=test"
 *
 * main scalding functions used:
 * map, sumByKey
 */
object DegreeCount extends ExecutionApp {
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
     * Just ignore the from, and output a count of 1L for each to
     */
    edges.map { case (from, to) => (to, 1L) }
      // sumByKey is the same thing as .group.sum
      // which does 1 map-reduce job, grouping by the key, and doing the
      // sum for all the values
      .sumByKey
      .writeExecution(output)
  }
}
