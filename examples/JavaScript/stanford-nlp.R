# Demonstrate the use of Stanford Natural Language Processor via JavaScript.
# Download Stanford CoreNLP from https://stanfordnlp.github.io/CoreNLP/
# Set the script's working directory to the installation folder.

class.path <- c(
  "./protobuf.jar",
  "./stanford-corenlp-3.9.0.jar",
  "./stanford-corenlp-3.9.0-models.jar"
)
library("jsr223")

engine <- ScriptEngine$new("JavaScript", class.path)
{
  engine %@% '
    var DocumentClass = Java.type("edu.stanford.nlp.simple.Document");

    function getPartsOfSpeech(text) {
      var doc = new DocumentClass(text);
      var list = [];
      for (i = 0; i < doc.sentences().size(); i++) {
        var sentence = doc.sentences().get(i);
        var o = {
          "words":sentence.words(),
          "pos.tag":sentence.posTags(),
          "offset.begin":sentence.characterOffsetBegin(),
          "offset.end":sentence.characterOffsetEnd()
        }
        list.push(o);
      }
      return list;
    }
  '
}

engine$invokeFunction("getPartsOfSpeech", "The jsr223 package makes Java objects easy to use. Download it from CRAN.")

engine$terminate()
