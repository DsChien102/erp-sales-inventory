"""Một máy chủ cho mọi prototype HTML: phục vụ thư mục specs/, tắt cache, đi qua symlink html/shared.
Dùng: python3 specs/prototype/serve.py [cổng]   (mặc định 8760) → mở http://127.0.0.1:8760/ (mục lục specs/index.html)
Máy chủ riêng của từng theme (8765 / 8766 / 8767) vẫn chạy được như cũ."""
import http.server
import os
import sys


class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8760
print(f"Mục lục: http://127.0.0.1:{port}/")
http.server.ThreadingHTTPServer(("127.0.0.1", port), NoCache).serve_forever()
