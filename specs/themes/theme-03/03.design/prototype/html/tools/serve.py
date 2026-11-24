"""Máy chủ tĩnh cho prototype, tắt cache trình duyệt (sửa JS/CSS xong chỉ cần ⌘R).
Dùng: python3 tools/serve.py [cổng]   (mặc định 8771, chạy từ thư mục html/)"""
import http.server
import os
import sys


class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8771
http.server.ThreadingHTTPServer(("127.0.0.1", port), NoCache).serve_forever()
