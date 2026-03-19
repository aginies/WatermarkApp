import http.server
import socketserver
import os

# Configuration
PORT = 8000
DIRECTORY = "build/app/outputs/flutter-apk/"  # The folder you want to share

# Create the directory if it doesn't exist
if not os.path.exists(DIRECTORY):
    os.makedirs(DIRECTORY)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Tell the handler to serve files from our specific directory
        super().__init__(*args, directory=DIRECTORY, **kwargs)

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving files from '{DIRECTORY}' at http://10.0.1.78:{PORT}")
    print("Press Ctrl+C to stop.")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
