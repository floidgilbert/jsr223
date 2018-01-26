/* A web UI for editing R data frames implemented in Groovy and Java. See 
  the following URLs for references.///explain and describe.

  http://docs.oracle.com/javafx/2/webview/jfxpub-webview.htm -- Example 7
  http://www.java2s.com/Tutorials/Java/JavaFX/1500__JavaFX_WebEngine.htm
*/

import groovy.json.JsonOutput;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.beans.value.ChangeListener;
import javafx.concurrent.Worker;
import javafx.geometry.HPos;
import javafx.geometry.VPos;
import javafx.scene.Node;
import javafx.scene.Scene;
import javafx.scene.layout.Region;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebView;
import javafx.stage.Stage;
import java.util.concurrent.ArrayBlockingQueue;
import netscape.javascript.JSObject;

// Extends Application, the entry point for JavaFX applications.
class DataFrameEditor extends Application {
  private Stage stage;
  private Browser browser;

  @Override
  public void start(Stage stage) {
    Platform.setImplicitExit(false);
    this.stage = stage;
    this.browser = new Browser();
    stage.setScene(new Scene(browser));
    while(true) {
      Object[] o = Global.queue.take();
      if (o.length == 0)
        break;
      stage.setTitle(o[0]);
///      browser.init(o[1], [2])
///      stage.setAlwaysOnTop(true); ///reconsider
      stage.setMaximized(true);
      stage.showAndWait();
    }
    Platform.exit();
  }

}

// This class represents the browser UI.
class Browser extends Region {
  final WebView webView = new WebView();
  final WebEngine webEngine = webView.getEngine();

  String jsonData;
  
  public Browser() {
    getStyleClass().add("webView");
    getChildren().add(webView);

    // This is an event listener that will add an instance of our
    // class 'CallbackToGroovy' to the active web page that can be called
    // by JavaScript. This expression is a Groovy closure, which
    // can be used in place of a Java lambda expression.
    def closure = {obs, oldState, newState ->
    
      // When the page finishes loading, expose an instance of our
      // custom class that the web page can call.
      if (newState == Worker.State.SUCCEEDED) {
        JSObject jsobj = webEngine.executeScript("window");
        jsobj.setMember("callback", new CallbackToGroovy());
        
        // Call the JavaScript function in the web page to load the table.
        webEngine.executeScript("loadTable();");
      }
    }
    def listener = [changed: closure] as ChangeListener;
    webEngine.getLoadWorker().stateProperty().addListener(listener);
  }

  public init(String url, Map data) {
    this.jsonData = JsonOutput.toJson(data);
    this.webEngine.load(url);
  }

  // Positions browser in the scene.
  @Override
  protected void layoutChildren() {
    double w = getWidth(), h = getHeight();
    layoutInArea(webView, 0, 0, w, h, 0, HPos.CENTER, VPos.CENTER);
  }

  // Members of this class will be called by the page's JavaScript.
  public class CallbackToGroovy {

    public String getData() {
      Browser.this.jsonData;
    }

  }

}

class Global {
  public static ArrayBlockingQueue<Object[]> queue = new ArrayBlockingQueue<Object[]>(1);
}

// Launch the JavaFX application in a separate thread. ////splain more about the threading.
thread = new Thread(
  {-> Application.launch(DataFrameEditor.class)}
);
thread.start();

public void editDataFrame(String title, String url, java.util.Map data) throws InterruptedException {
  Object[] o = [title, url, data];
  Global.queue.put(o);
}

public void exitJavaFx() throws InterruptedException {
  Global.queue.put(new Object[0]);
}
