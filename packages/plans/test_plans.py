import json
import subprocess
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

from server import MAX_HTML_BYTES, Server


class PublishingTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.key = self.root / "key"
        self.key.write_text("test-key-" * 8)
        self.server = Server(("127.0.0.1", 0), self.root, self.key, "https://plans.example")
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.start()
        self.url = f"http://127.0.0.1:{self.server.server_port}"

    def tearDown(self):
        self.server.shutdown()
        self.thread.join()
        self.server.server_close()
        self.temp.cleanup()

    def request(self, path, data=None, method=None, auth=False, extra=None):
        headers = {"Content-Type": "text/html"}
        if auth:
            headers["Authorization"] = "Bearer " + self.key.read_text()
        headers.update(extra or {})
        request = urllib.request.Request(self.url + path, data=data, method=method, headers=headers)
        try:
            return urllib.request.urlopen(request)
        except urllib.error.HTTPError as error:
            return error

    def upload(self, content, id=None):
        file = self.root / "plan.html"
        file.write_bytes(content)
        command = [sys.executable, str(Path(__file__).with_name("publish.py")),
                   "--api-url", self.url, "--key-file", str(self.key), "upload", str(file)]
        if id:
            command += ["--id", id]
        return json.loads(subprocess.check_output(command))

    def test_publish_update_and_persistent_versions(self):
        first = self.upload(b"<!doctype html><h1>First</h1>")
        second = self.upload(b"<!doctype html><h1>Second</h1>", first["id"])
        self.assertEqual(first["url"], second["url"])
        self.assertEqual(second["version"], 2)
        path = "/d/" + first["id"]
        for suffix, expected in [("", b"Second"), ("/raw", b"Second"), ("/v/1", b"First"), ("/v/1/raw", b"First")]:
            with self.request(path + suffix) as response:
                self.assertIn(expected, response.read())
                self.assertIn("sandbox allow-scripts", response.headers["Content-Security-Policy"])
                self.assertNotIn("allow-same-origin", response.headers["Content-Security-Policy"])
                self.assertEqual(response.headers["X-Robots-Tag"], "noindex, nofollow, noarchive")
        with self.request("/api/drafts", auth=True) as response:
            self.assertEqual(json.load(response)[0]["version"], 2)
        # A fresh server reads the same state, including historical versions.
        restarted = Server(("127.0.0.1", 0), self.root, self.key, "https://plans.example")
        try:
            with restarted.connect() as db:
                self.assertEqual(db.execute("SELECT COUNT(*) FROM versions").fetchone()[0], 2)
        finally:
            restarted.server_close()

    def test_auth_and_invalid_uploads(self):
        for path, data in [("/api/drafts", None), ("/api/drafts", b"hello")]:
            with self.request(path, data) as response:
                self.assertEqual(response.status, 401)
        for data, extra, status in [(b"x", {"Content-Type": "text/plain"}, 415),
                                     (b"\xff", {}, 400),
                                     (b"x", {"Content-Length": str(MAX_HTML_BYTES + 1)}, 413)]:
            with self.request("/api/drafts", data, auth=True, extra=extra) as response:
                self.assertEqual(response.status, status)
        with self.request("/api/drafts/" + "0" * 32, b"hello", method="PUT", auth=True) as response:
            self.assertEqual(response.status, 404)
        with self.request("/d/../../key") as response:
            self.assertEqual(response.status, 404)


if __name__ == "__main__":
    unittest.main()
