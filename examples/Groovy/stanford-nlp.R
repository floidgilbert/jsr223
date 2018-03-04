# Demonstrate the use of Stanford Natural Language Processor via Groovy.
# The last three files in `class.path` can be downloaded from
# Stanford CoreNLP from https://stanfordnlp.github.io/CoreNLP/

class.path <- c(
  "lib/groovy-all-2.4.7.jar",
  "protobuf.jar",
  "stanford-corenlp-3.9.0.jar",
  "stanford-corenlp-3.9.0-models.jar"
)

library("jsr223")
engine <- ScriptEngine$new("Groovy", class.path)
engine %@% '
  import edu.stanford.nlp.simple.*;

  def getPartsOfSpeech(String text) {
    doc = new Document(text);
    list = new ArrayList<Map>(doc.sentences().size());
    for (sentence in doc.sentences()) {
      m = new LinkedHashMap<String, Object>();
      m.put("words", sentence.words());
      m.put("pos.tag", sentence.posTags());
      m.put("offset.begin", sentence.characterOffsetBegin());
      m.put("offset.end", sentence.characterOffsetEnd());
      list.add(m);
    }
    return list;
  }
'

engine$invokeFunction("getPartsOfSpeech", "The jsr223 package makes Java objects easy to use. Download it from CRAN.")

engine$terminate()
