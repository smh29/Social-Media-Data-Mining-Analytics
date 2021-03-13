package io.scalding.approximations

import com.twitter.scalding.Tool
import io.scalding.approximations.BloomFilter.fields.SimpleBFFields
import io.scalding.approximations.CountMinSketch.fields.CMSstackexchangeFields
import io.scalding.approximations.HyperLogLog._
import io.scalding.approximations.BloomFilter._
import io.scalding.approximations.CountMinSketch._
import io.scalding.approximations.HyperLogLog.fields.HLLwikipedia
import org.apache.hadoop.conf.Configuration
import org.apache.hadoop.util.ToolRunner

/**
 * A Scala application that executes HLL - BF - CMS scalding examples in local mode of
 * execution.
 *
 * You can instantiate with just:
 *  $ gradle run
 *
 * @author Antonios Chalkiopoulos - http://scalding.io
 */
object ExamplesRunner extends App {

  // Hyper Log Log Examples
  val timerHLL = Utils.withTimeCalc("Running HLL to count cardinality on two 100K line data-sets") {
    ToolRunner.run(new Configuration, new Tool, (classOf[HLLExampleForTwoHours].getName ::
      List("--local")).toArray)
  }
  println(s"Running HLL took $timerHLL msec")

  val stackExchangePosts = "datasets/stackexchange/posts.tsv"
  val stackexchangeHLL = Utils.withTimeCalc("Running HLL cardinality count on stackexchange data-set") {
    ToolRunner.run(new Configuration, new Tool, (classOf[StackexchangeHLL].getName ::
      List("--local","--input",stackExchangePosts,"--output","results/HLL-stackexchange")).toArray)
  }
  println(s"Running HLL took $timerHLL msec")

  val wikipediaRevisions = "datasets/wikipedia/wikipedia-revisions-sample.tsv"
  val wikipediaHLL = Utils.withTimeCalc("Running HLL cardinality count on wikipedia data-set") {
    ToolRunner.run(new Configuration, new Tool, (classOf[HLLwikipedia].getName ::
      List("--local","--input",wikipediaRevisions,"--output","results/HLL-wikipedia")).toArray)
  }
  println(s"Running HLL took $timerHLL msec")



  // Bloom Filter Examples
  val daily = "datasets/SanFranciscoPoliceDepartment/SFPD_Incidents_Previous_Day.csv"
  val historical = "datasets/SanFranciscoPoliceDepartment/SFPD_Incidents_Previous_Three_Months.csv"
  val similarHistoryWithBF = "results/similar-history-with-BF"
  val similarHistoryWithoutBF = "results/similar-history-without-BF"

  val timerBF = Utils.withTimeCalc("Running Similar history => With BF") {
    val BFjobArgs = classOf[ExtractSimilarHistoryForDailyIncidentsWithBloomFilter].getName ::
      "--local" :: "--output" :: similarHistoryWithBF :: "--historical" ::
      historical :: "--daily" :: daily :: args.toList
    ToolRunner.run(new Configuration, new Tool, BFjobArgs.toArray)
  }
  println(s"Running using BF took $timerBF msec")
  val timerWithoutBF = Utils.withTimeCalc("Running Similar history => Without BF") {
    val withoutBFjobArgs =  classOf[ExtractSimilarHistoryForDailyIncidentsWithNoBloomFilter].getName ::
      "--local" :: "--output" :: similarHistoryWithoutBF :: "--historical" :: historical ::
      "--daily" :: daily :: args.toList
    ToolRunner.run(new Configuration, new Tool, withoutBFjobArgs.toArray)
  }
  println(s"Running without BF took $timerWithoutBF msec")

  println( s"Analysing daily incident file '$daily' matching with historical incidents at '$historical' with and without bloom filter " +
    s"and writing output with bloom filter at '$similarHistoryWithBF' and without at $similarHistoryWithoutBF" )

  val timerBFmillennialls = Utils.withTimeCalc("Running simple BF creation and queries") {
    ToolRunner.run(new Configuration, new Tool, (classOf[SimpleBFFields].getName :: "--local" :: args.toList).toArray)
  }

  val timerBFsimple = Utils.withTimeCalc("Running simple BF creation and queries") {
    RunBFExample.run("results/BF-SimpleExample-serialized.tsv", "results/BF-SimpleExample.tsv", args, "--local")
  }

  // Count-Min Sketch Examples
  val timerCMS = Utils.withTimeCalc("Running Count-Min Sketch on stackexchange dataset") {
    ToolRunner.run(new Configuration, new Tool, (classOf[CMSstackexchangeFields].getName :: "--local" ::
        "--input" :: "datasets/stackexchange/posts.tsv" ::
        "--output":: "results/CMS-stackexchangeFields.tsv" :: args.toList).toArray)
  }
  println( s"Count-Min Sketch example on `stackexchange` took $timerCMS msec")

  val timerCMSstackexchangeTyped = Utils.withTimeCalc("Running Count-Min Sketch on stackexchange dataset") {
    ToolRunner.run(new Configuration, new Tool, (classOf[StackexchangeHistogram].getName :: "--local" ::
      "--input" :: "datasets/stackexchange/posts.tsv" ::
      "--output":: "results/CMS-stackexchangeTyped.tsv" ::
      "--serialized" :: "results/CMS-stackexchangeTyped-serialized.tsv" :: args.toList).toArray)
  }
  println( s"Count-Min Sketch example on `stackexchange` took $timerCMS msec")


}