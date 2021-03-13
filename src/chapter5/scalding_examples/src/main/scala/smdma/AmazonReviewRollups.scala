package smdma

import com.twitter.scalding._

/**
 * This job gives an example of computing a roll-up of review scores
 * in each hourly bucket
 * After you have run "make" in the dataload directory
 * Run it with:
 * ./sbt "run --local -Dsmdma.amazon.reviews=../dataload/finefoods.txt -Dsmdma.output=rollup"
 */
object AmazonReviewRollups extends ExecutionApp {

  def job = Execution.getConfig.flatMap { conf =>
    /*
     * The amazon data set is not partitioned into a format
     * that is easy to read in Hadoop since one record spans
     * several lines. We load it locally, but use
     * standard scalding after that
     * Note, this data file uses a non-standard encoding called
     * ISO-8859-1. Generally these days, UTF-8 is the standard.
     */
    val input = TextLine(conf.get("smdma.amazon.reviews").get, textEncoding = "ISO-8859-1")

    def getData(record: Map[String, String]): Option[(RichDate, Double, String, String)] =
      for {
        dateSeconds <- record.get("review/time")
        // scalding RichDate keeps time in milliseconds since 1970
        date = RichDate(dateSeconds.toLong * 1000L)
        score <- record.get("review/score")
        dscore = score.toDouble // score is a string
        helpful <- record.get("review/helpfulness")
        uid <- record.get("review/userId")
      } yield (date, dscore, helpful, uid)

    // Use the parsing code we have already developed:
    val parsed = TypedPipe.from(input)
      .map { line => AmazonReviewParsing.parse(line) }
      .flatMap { record => getData(record) }

    /**
     * Let's prepare the keys and the values
     */
    val prepared = parsed.map { case (date, score, helpful, uid) =>
      val key = (date, score, helpful)
      // We just count each occurrence of the key
      val value = 1L
      (key, value)
    }
    /*
     * Now we do the data-cubing so we can answer queries faster.
     * We put each item into a year, month bucket and day of week.
     * We rollup with and without the helpfulness rating since
     * often we just want to know distribution of scores on each
     * day.
     */
    val timezone = java.util.TimeZone.getTimeZone("UTC")
    prepared.flatMap { case ((date, score, helpful), value) =>
      val timeBuckets =
        Iterator(date.toString("yyyy")(timezone), // year
          date.toString("yyyy.MM")(timezone), // year and month
          date.toString("EEE")(timezone)) // just day of week, e.g. Mon, Tue, etc...
      for {
        dates <- timeBuckets
        scores <- Iterator(Some(score), None)
        helpfuls <- Iterator(Some(helpful), None)
      } yield ((dates, scores, helpfuls), value)
    }
    .sumByKey // Just add them up for each key
    .writeExecution(TypedTsv(conf.get("smdma.output").get))
  }
}
