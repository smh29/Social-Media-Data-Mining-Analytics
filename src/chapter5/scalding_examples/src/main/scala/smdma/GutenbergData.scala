package smdma

import java.io._
import scala.util.Try

/**
 * This gives cached access to project gutenberg books
 * by caching locally the loaded books
 */
object GutenbergData {
  val cacheDir = "gutencache"

  private def urlFor(book: Int): String =
    "http://www.gutenberg.org/ebooks/%d.txt.utf-8".format(book)

  private def httpLines(book: Int): Iterator[String] =
    io.Source.fromURL(urlFor(book)).getLines

  private def ensureCache: Unit = {
    val cache = new File(cacheDir)
    if(!cache.exists) cache.mkdir
    else assert(cache.isDirectory, "%s exists but is not a directory".format(cacheDir))
  }

  private def fileFor(book: Int): File =
    new File(cacheDir + "/%d.txt".format(book))

  private def fileLines(book: Int): Option[Stream[String]] =
    fileFor(book) match {
      case file if file.exists =>
        Some(io.Source.fromFile(file, "UTF-8").getLines.toStream)
      case _ => None
    }

  private def writeAll(it: Iterator[String], f: File): Unit = {
    val p = new PrintWriter(f)
    val res = Try(it.foreach(p.println))
    if(res.isFailure) {
      f.delete
    }
    p.close
    res.get
  }

  def openBook(book: Int): Try[Stream[String]] =
    Try(fileLines(book)
      .getOrElse {
        val fromWeb = httpLines(book)
        ensureCache
        writeAll(fromWeb, fileFor(book))
        // If the write successed, we go on
        fileLines(book).get
      })

  // Lazy val means only initialize as needed
  lazy val getTopBooks: List[(Int, String)] = {
    val top = io.Source.fromURL("http://www.gutenberg.org/browse/scores/top")
    try {
      val toParse = top.getLines
        // ignore till we get to the top from the last 30 days
        .dropWhile(!_.contains("id=\"books-last30\""))
        // stop parsing when we get to the end of the list marker
        .takeWhile(!_.contains("</ol>"))

      val itemRE = ".*\\/ebooks\\/(\\d+)\">([^<]+)</a>".r

      def getItem(s: String): Option[(Int, String)] = for {
        itemRE(id, title) <- itemRE findFirstIn s
      } yield (id.toInt, title)

      toParse.flatMap(getItem(_).toIterator).toList
    }
    finally { top.close }
  }
}
