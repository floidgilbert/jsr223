/* A web UI for editing R data frames implemented in Groovy and Java. See 
  the following URLs for references.///explain and describe.

  http://docs.oracle.com/javafx/2/webview/jfxpub-webview.htm -- Example 7
  http://www.java2s.com/Tutorials/Java/JavaFX/1500__JavaFX_WebEngine.htm
*/

import groovy.json.JsonOutput;
import groovy.json.JsonSlurper;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.beans.value.ChangeListener;
import javafx.concurrent.Worker;
import javafx.event.EventHandler;
import javafx.geometry.HPos;
import javafx.geometry.VPos;
import javafx.scene.Node;
import javafx.scene.Scene;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Dialog;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.Region;
import javafx.scene.web.WebEngine;
import javafx.scene.web.WebEvent;
import javafx.scene.web.WebView;
import javafx.stage.Stage;
import java.util.concurrent.ArrayBlockingQueue;
import netscape.javascript.JSObject;

class Request {
  
  public String url;
  public String title;
  public List<Map<String, Object>> data;
  
  Request() {}
  
  Request(String url, String title, List<Map<String, Object>> data) {
    this.url = url;
    this.title = title;
    this.data = data;
  }
}

class Response {
  
  public boolean ok;
  public List<Map<String, Object>> data;
  
  Response(boolean ok, List<Map<String, Object>> data) {
    this.ok = ok;
    this.data = data;
  }
}

// Extends Application, the entry point for JavaFX applications.
class View extends Application {
  
  public final ArrayBlockingQueue<Request> queue = new ArrayBlockingQueue<Request>(1);
  
  @Override
  public void init() {
    Global.view = this;
  }

  @Override
  public void start(Stage stage) {
    Platform.setImplicitExit(false);
    Global.controller.queue.put(new Response(false, null)); ///comment or do differently. i'm not a pro.
    handleRequests();
    Platform.exit();
  }
  
  void handleRequests() {
    Stage stage = new Stage();
    Browser browser = new Browser(stage);
    stage.setScene(new Scene(browser, 1024, 768));
    while(true) {
      Request request = queue.take();
      // data == null signals exit.
      if (request.data == null)
        break;
      stage.setTitle(request.title);
      browser.initialize(request);
      // stage.setAlwaysOnTop(true);
      // stage.setMaximized(true);
      stage.showAndWait();
      Global.controller.queue.put(browser.response);
    }
  }

}

// This class represents the browser UI.
class Browser extends Region {
  
  final WebView webView = new WebView();
  final WebEngine webEngine = webView.getEngine();
  Stage stage;
  Request request;
  
  public Response response;
  
  public Browser(Stage stage) {
    this.stage = stage;
    getChildren().add(webView);
    webEngine.setOnAlert({WebEvent<String> event -> showAlert(event.getData())});
    
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

        this.response = new Response(false, null);
        
        // Call the JavaScript function in the web page to load the table.
        webEngine.executeScript("loadTable();");
      }
    }
    
    def listener = [changed: closure] as ChangeListener;
    webEngine.getLoadWorker().stateProperty().addListener(listener);
    
  }

  public void initialize(Request request) {
    this.request = request;
    this.webEngine.load(request.url);
  }
  
  // Positions browser in the scene.
  @Override
  protected void layoutChildren() {
    double w = getWidth(), h = getHeight();
    layoutInArea(webView, 0, 0, w, h, 0, HPos.CENTER, VPos.CENTER);
  }
  
  private void showAlert(String message) {
    Dialog<Void> alert = new Dialog<>();
    alert.setTitle("JavaScript Alert");
    alert.getDialogPane().setContentText(message);
    alert.getDialogPane().getButtonTypes().add(ButtonType.OK);
    alert.showAndWait();
  }  

  // Members of this class will be called by the page's JavaScript.
  public class CallbackToGroovy {
    
    public String getHandsOnTableParameters() {
      Map<String, Object> parms = new LinkedHashMap<String, Object>();
      parms.put("title", Browser.this.request.title);
      parms.put("data", Browser.this.request.data);
      parms.put("constraints", getConstraints());
      return JsonOutput.toJson(parms);
    }

    private List<Map<String, Object>> getConstraints() {
      Map<String, Object> record = Browser.this.request.data[0];
      List<Map<String, Object>> lst = new ArrayList<Map<String, Object>>(record.size());
      String type;
      String format;
      for (Map.Entry<String, Object> entry : record.entrySet()) {
        Class<?> cls = entry.getValue().getClass();
        if (cls.equals(Double.TYPE) || cls.equals(Double.class)) {
          type = "numeric";
          format = "0.00";
        } else if (cls.equals(Integer.TYPE) || cls.equals(Integer.class)) {
          type = "numeric";
          format = "0";
        } else {
          type = "text";
          format = "";
        }
        LinkedHashMap<String, String> m = new LinkedHashMap<String, String>(3);
        m.put("data", entry.getKey());
        m.put("type", type);
        m.put("format", format);
        lst.add(m);
      }
      return lst;
    }

    public void cancel() {
      Browser.this.stage.close();
      Browser.this.request = null;
    }
    
    public void ok() {
      JsonSlurper slurper = new JsonSlurper();
      String jsonData = (String) Browser.this.webEngine.executeScript("JSON.stringify(hot.getSourceData());");
      Browser.this.response = new Response(true, slurper.parseText(jsonData));
      Browser.this.stage.close();
      Browser.this.request = null;
    }

  }

}

///comment
class Global {
  public static View view = null;
  public static Controller controller = null;
}

class Controller {

  public final ArrayBlockingQueue<Response> queue = new ArrayBlockingQueue<Response>(1);

  public List<Map<String, Object>> edit(String url, String title, List<Map<String, Object>> data) throws InterruptedException {
    Global.view.queue.put(new Request(url, title, data));
    Response response = queue.take();
    if (response.ok)
      return response.data;///consider re-ordering here.
    return null;
  }
  
  public void terminate() throws InterruptedException {
    Global.view.queue.put(new Request());
  }
  
}

controller = new Controller();
Global.controller = controller;

// Launch the JavaFX application in a separate thread. ////splain more about the threading.
thread = new Thread(
  {-> Application.launch(View.class)}
);
thread.start();

controller.queue.take(); ///synch/wait for app to start before returning.

