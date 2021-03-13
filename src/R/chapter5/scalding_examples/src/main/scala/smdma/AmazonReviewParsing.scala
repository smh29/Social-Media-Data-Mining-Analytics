package smdma

object AmazonReviewParsing {

  /**
   * The "fine-foods" data-set has newline separated
   * blocks of "key: value" style
   */
  def parse(input: Stream[String]): Stream[Map[String, String]] =
    input.map(parse)

  def parse(line: String): Map[String, String] = {

    def parseKV(part: String): (String, String) = {
      val pos = part.indexOf(": ")
      val (key, colonValue) = part.splitAt(pos)
      (key, colonValue.drop(": ".size))
    }

    /*
     * The algorithm here is to take until we get to an empty line,
     * parse that block into KV pairs, and then call this function
     * on the rest of the stream
     */
    val firstBlock = line.split("\t")
    /*
     * Note that we don't hold on to input below so the
     * head of stream can be garbage collected
     */
    firstBlock.map(parseKV).toMap
  }

  // Use these wrappers to tell different types of strings apart:
  case class Product(id: String) extends AnyVal
  case class User(id: String) extends AnyVal

  def getEdge(m: Map[String, String]): Option[(Product, User)] =
    for {
      user <- m.get("review/userId")
      product <- m.get("product/productId")
    } yield (Product(product), User(user))

  def edgesFrom(lines: Iterator[String]): Stream[(Product, User)] =
    parse(lines.toStream)
      .map(getEdge)
      .collect { case Some(pu) => pu }

  def edgesFromSource(src: io.Source): Stream[(Product, User)] =
    edgesFrom(src.getLines)

  def edgesFromFile(f: String): Stream[(Product, User)] =
    edgesFromSource(io.Source.fromFile(f)(io.Codec.ISO8859))
}
