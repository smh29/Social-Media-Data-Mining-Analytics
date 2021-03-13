package smdma

import com.twitter.scalding._
import ExecutionContext._

/**
 * Here is a simple job that computes the product of two matrices
 * Note that scalding has a powerful Matrix API that can do this
 * and in an optimized order, but we display the algorithm here
 * as an example of how to program it while thinging in map/reduce
 * style
 *
 * ./sbt "run --local -Dsmdma.left=data/small_matrix1.tsv -Dsmdma.right=data/small_matrix2.tsv -Dsmdma.output=test"
 *
 * scalding functions used: map, group, join, sumByKey
 */
object MatrixProduct extends ExecutionApp {
  def job = Execution.getConfig.flatMap { config =>
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
     * If M = A*B, we know that M_{i, j} = \sum_k A_{i, k} B_{k, j} (1)
     * We use the "outer product" representation: join on k, and
     * do the product, then group by the i, j and do the sum
     */
    val leftByCol = leftInput.map { case (r1, c1, v1) => (c1, (r1, v1)) }
    val rightByRow = rightInput.map { case (r2, c2, v2) => (r2, (c2, v2)) }
    /* Here we do the first map/reduce job.
     * recall that join is actually implemented by a special reducer
     */
    leftByCol.join(rightByRow)
      /*
       * discard the joining key, which is k in the above equation (1)
       * above.
       *
       * output the row and column, and do the product
       */
      .map { case (joiningKey, ((r1, v1), (c2, v2))) => ((r1, c2), v1 * v2) }
      /**
       * now group by (r1, c2) and do basically the same map-reduce job
       * as MatrixSum since this is now the "outer sum" that we are doing
       */
      .sumByKey
      // As in MatrixSum, flatten before writing
      .map { case ((row, col), value) => (row, col, value) }
      .writeExecution(output)
  }
}
