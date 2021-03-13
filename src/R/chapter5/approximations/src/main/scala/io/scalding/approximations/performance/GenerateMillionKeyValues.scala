package io.scalding.approximations.performance

import java.io._

/**
 * This Scala application generates a single Tsv (Tab separated file)
 * with one 10-character string (key) per line and one 200-character string (value) per line
 *
 * It generates :
 *    1 Million keys    -      30 MBytes
 *   10 Million keys    -     300 MBytes
 *   20 Million keys    -     600 MBytes
 *   40 Million keys    -     1,2 GBytes
 *   80 Million keys    -     2,4 GBytes
 *  100 Million keys    -     3,0 GBytes
 *
 * @author Antonios Chalkiopoulos - http://scalding.io
 */
object GenerateMillionKeyValues extends App {

  /**
   *
   * @param filename The filename to store into
   * @param millions Number of million of lines to generate
   * @param percentageUnique % of keys to be unique - by default 100% of the keys are unique
   */
  def generateKeyValues(filename:String, millions: Int, percentageUnique: Int = 100) = {

    assert(percentageUnique>=0 && percentageUnique <=100, "Percentage of unique keys should be an integer between [0..100]")
    assert(millions>=1, "This method works for multimillion keys")

    println(s"Generating '$filename' with $millions million ten-character-long key and 200-char-long value strings - $percentageUnique % unique (one per line)")
    val lineSepartor = util.Properties.lineSeparator
    new File(filename).delete()
    val fw = new FileWriter(filename, true)

    // Generate unique keys
    for (i <- 1 to millions) {
      val chunk =
        (0 to 1000 * 10 * percentageUnique)
          .map(_ => util.Random.nextString(10).replaceAll("[\\p{C}]"," ") +"\t" + util.Random.nextString(200).replaceAll("[\\p{C}]"," ") )
          .mkString(lineSepartor)
      fw.write(chunk)
      println(s"$i million UNIQUE keys generated")
    }

    // Generate non-unique keys
    for (i <- 1 to millions) {
      val value = util.Random.nextInt(50)
      val chunk = (0 to 1000 * 10 *(100-percentageUnique))
        .map(_ => (5000000000L - value) + "\t" + util.Random.nextString(200).replaceAll("[\\p{C}]"," ") )
        .mkString(lineSepartor)
      fw.write(chunk)
      println(s"$i million non-UNIQUE keys generated")
    }

    fw.close()
    println(s" File '$filename' generated ")
  }

  generateKeyValues("datasets/1Million-KV-Unique"  , 1 )
  generateKeyValues("datasets/10Million-KV-Unique" ,10 )
  generateKeyValues("datasets/20Million-KV-Unique" ,20 )
  generateKeyValues("datasets/40Million-KV-Unique" ,40 )
  generateKeyValues("datasets/80Million-KV-Unique" ,800 )

}