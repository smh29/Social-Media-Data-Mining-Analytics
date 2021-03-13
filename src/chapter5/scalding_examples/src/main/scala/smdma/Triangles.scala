package smdma

import com.twitter.scalding._

/**
 * Given a list edges, A -> B, we want to print all
 * the cycles, A -> B -> C -> A
 *
 * main scalding functions used:
 * map, group, join, filter
 * run this with:
 * ./sbt "run --local -Dsmdma.output=triangles -Dsmdma.edges=data/small_graph_with_triangles.tsv"
 */
object Triangles extends ExecutionApp {
  def job = Execution.getConfig.flatMap { config =>
    /* This gives an input by looking up from the config:
     * The input file looks like:
     * source <tab> destination
     */
    def input(name: String) =
      TypedPipe.from(TypedTsv[(Long, Long)](config.get(name).get))

    val edges = input("smdma.edges")
    val output = TypedTsv[(Long, Long, Long)](config.get("smdma.output").get)

    /*
     * Like in the second neighbor example, we create the list of paths
     * of length 2
     */
    edges.map { case (from, to) => (to, from) }
      // Here is the first map-reduce job to do the first join
      .join(edges)
      /*
       * now join again, this time connect the to end
       */
      .map { case (middle, (start, end)) => (end, (start, middle)) }
      /*
       * so we don't write each triangle three times
       * we choose the representation of this cycle where the
       * end has the highest ID, as a -> b -> c -> a can be written as
       * (a, b, c), (b, c, a) or (c, a, b)
       */
      .filter { case (end, (start, middle)) =>
        (end > middle) && (end > start)
      }
      // Here is the second map-reduce job to do the second join
      .join(edges)
      /*
       * Now, we only keep triples where
       * start1 is actually the same as start
       */
      .filter { case (end, ((start, middle), start1)) =>
        (start1 == start)
      }
      // Now unpack into a triple
      .map { case (end, ((start, middle), start1)) => (start, middle, end) }
      .writeExecution(output)
  }
}
