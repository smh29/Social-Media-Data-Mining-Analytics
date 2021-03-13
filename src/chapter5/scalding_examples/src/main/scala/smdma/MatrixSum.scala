package smdma

import com.twitter.scalding._
import ExecutionContext._

/**
 * Here is a simple job that computes the sum of two matrices
 *
 * Run this with:
 *
 * ./sbt "run --local -Dsmdma.left=data/small_matrix1.tsv -Dsmdma.right=data/small_matrix2.tsv -Dsmdma.output=test"
 *
 * scalding functions used:
 * map, ++ (merge), sumByKey
 */
object MatrixSum extends ExecutionApp {
  def job: Execution[Unit] = Execution.getConfig.flatMap { config =>
    /* This gives an input by looking up from the config:
     * This is a sparse representation of a matrix:
     * row_id <tab> column_id <tab> value
     * missing rows, columns are assumed to be 0.0
     */
    def input(name: String) =
      TypedPipe.from(TypedTsv[(Long, Long, Double)](config.get(name).get))

    val leftInput = input("smdma.left")
    val rightInput = input("smdma.right")
    val output = TypedTsv[(Long, Long, Double)](config.get("smdma.output").get)
    /*
     * We just need to merge (written as ++) everything,
     * group by the row and column
     * then sum the values up
     */
    (leftInput ++ rightInput)
      /*
       * get the data in (key, value) format, where
       * the key is (row, col) and the value is just the value
       * at that position
       */
      .map { case (row, col, value) => ((row, col), value) }
      /*
       * do a key grouping, and for each key, sum all the values
       */
      .sumByKey
      /*
       * here we flatten the tuple structure before writing
       */
      .map { case ((row, col), value) => (row, col, value) }
      .writeExecution(output)
  }
}
