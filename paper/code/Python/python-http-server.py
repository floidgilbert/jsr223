# A Python HTTP server adapted from Python Wiki
# https://wiki.python.org/moin/BaseHttpServer
# 
# See "python-http-server.R" for instructions.

import time
import BaseHTTPServer

# HTTP request handler class
class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_HEAD(s):
        s.send_response(200)
        s.send_header("Content-type", "text/html")
        s.end_headers()
    def do_GET(s):
        print time.asctime(), "Received request"
        s.send_response(200)
        s.send_header("Content-type", "text/html")
        s.end_headers()
        s.wfile.write("<html><head><title>R/Python HTTP Server</title></head>")
        html = R.eval('getHtmlTable()') # Get HTML table from R.
        s.wfile.write(html)
        s.wfile.write("</body></html>")

class MyServer:
    def __init__(self, host_name, port_number, timeout):
        self.host_name = host_name
        self.port_number = port_number
        server_class = BaseHTTPServer.HTTPServer
        self.httpd = server_class((self.host_name, self.port_number), MyHandler)
        self.httpd.timeout = timeout
        print time.asctime(), "Server Starts - %s:%s" % (self.host_name, self.port_number)
    def handle_request(self):
        # This method exists only for demonstration purposes. For a production 
        # scenario, see 'SocketServer.serve_forever()'.
        self.httpd.handle_request()
    def close(self):
        self.httpd.server_close()
        print time.asctime(), "Server Stops - %s:%s" % (self.host_name, self.port_number)

