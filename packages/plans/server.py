"""Single-owner HTML publishing service; persistent state lives in SQLite."""

import hmac
import json
import os
import re
import secrets
import sqlite3
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_HTML_BYTES = 5 * 1024 * 1024
DRAFT_PATH = r"/d/([a-f0-9]{32})(?:/v/([1-9][0-9]*))?(/raw)?"
CSP = (
    "sandbox allow-scripts; default-src 'none'; script-src 'unsafe-inline'; "
    "style-src 'unsafe-inline'; img-src data: https:; font-src data:; "
    "connect-src 'none'; form-action 'none'; base-uri 'none'; frame-ancestors 'none'"
)


class Server(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, address, data_dir, key_file, public_url):
        self.database = Path(data_dir) / "plans.sqlite3"
        self.key = Path(key_file).read_text().strip()
        if len(self.key) < 32:
            raise ValueError("Publishing key must contain at least 32 characters")
        self.public_url = public_url.rstrip("/")
        with self.connect() as db:
            db.executescript("""
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS drafts (
                    id TEXT PRIMARY KEY, title TEXT NOT NULL,
                    updated TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
                );
                CREATE TABLE IF NOT EXISTS versions (
                    draft_id TEXT NOT NULL REFERENCES drafts(id),
                    version INTEGER NOT NULL, html BLOB NOT NULL,
                    PRIMARY KEY (draft_id, version)
                );
            """)
        super().__init__(address, Handler)

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.database, timeout=30)
        try:
            db.execute("PRAGMA foreign_keys=ON")
            with db:
                yield db
        finally:
            db.close()


class Handler(BaseHTTPRequestHandler):
    def setup(self):
        super().setup()
        self.connection.settimeout(15)

    def log_message(self, format, *args):
        # Draft paths are bearer links; keep them out of access logs.
        pass

    def respond(self, status, body, content_type="application/json", headers=None):
        if isinstance(body, dict) or isinstance(body, list):
            body = json.dumps(body).encode()
        elif isinstance(body, str):
            body = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Robots-Tag", "noindex, nofollow, noarchive")
        self.send_header("Content-Security-Policy", CSP)
        for name, value in (headers or {}).items():
            self.send_header(name, str(value))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def authorized(self):
        supplied = self.headers.get("Authorization", "").encode()
        expected = f"Bearer {self.server.key}".encode()
        if hmac.compare_digest(supplied, expected):
            return True
        self.respond(401, {"error": "Publishing key required"})
        return False

    def do_HEAD(self):
        self.do_GET()

    def do_GET(self):
        if self.path == "/healthz":
            return self.respond(200, {"status": "ok"})
        if self.path == "/":
            return self.respond(200, """<!doctype html><html lang="en">
<meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Plans · jugi.cc</title><style>
:root{color-scheme:light dark;font:18px/1.6 system-ui}body{max-width:680px;margin:15vh auto;padding:24px}
h1{font-size:56px;letter-spacing:-3px;margin:0}p{opacity:.75}code{display:block;padding:20px;
border:1px solid #8886;border-radius:12px;font-size:15px}small{opacity:.6}
</style><main><small>JUGI.CC / DRAFTS</small><h1>A place for plans.</h1>
<p>HTML drafts, published by your agents. Open a shared link to read a plan.</p>
<code>publish-plan upload ./plan.html --title "My plan"</code>
<p>Publish from Claude Code, Pi, or Codex with the <b>publish-plan</b> skill.</p>
<small>Links are unlisted. Anyone with a link can view that draft.</small></main></html>""", "text/html; charset=utf-8")
        if self.path == "/api/drafts":
            if not self.authorized():
                return
            with self.server.connect() as db:
                rows = db.execute("""SELECT d.id, d.title, d.updated, MAX(v.version)
                    FROM drafts d JOIN versions v ON v.draft_id=d.id
                    GROUP BY d.id ORDER BY d.updated DESC""").fetchall()
            return self.respond(200, [dict(id=id, title=title, updated=updated,
                                          version=version, url=f"{self.server.public_url}/d/{id}")
                                      for id, title, updated, version in rows])
        match = re.fullmatch(DRAFT_PATH, self.path)
        if match:
            draft_id, version, _ = match.groups()
            with self.server.connect() as db:
                row = db.execute("""SELECT version, html FROM versions WHERE draft_id=?
                    AND (? IS NULL OR version=?) ORDER BY version DESC LIMIT 1""",
                                 (draft_id, version, version)).fetchone()
            if row:
                return self.respond(200, row[1], "text/html; charset=utf-8",
                                    {"X-Plan-Version": row[0], "X-Plan-Id": draft_id})
        self.respond(404, {"error": "Not found"})

    def do_POST(self):
        self.publish()

    def do_PUT(self):
        self.publish()

    def publish(self):
        if not self.authorized():
            return
        match = re.fullmatch(r"/api/drafts/([a-f0-9]{32})", self.path)
        create = self.command == "POST" and self.path == "/api/drafts"
        if not create and not (self.command == "PUT" and match):
            return self.respond(404, {"error": "Not found"})
        if self.headers.get("Transfer-Encoding"):
            return self.respond(400, {"error": "Use Content-Length"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if not 0 < length <= MAX_HTML_BYTES:
            return self.respond(413, {"error": "Upload must be between 1 byte and 5 MiB"})
        if self.headers.get_content_type() != "text/html":
            return self.respond(415, {"error": "Expected text/html"})
        html = self.rfile.read(length)
        try:
            html.decode("utf-8")
        except UnicodeDecodeError:
            return self.respond(400, {"error": "HTML must be UTF-8"})
        if len(html) != length:
            return self.respond(400, {"error": "Incomplete upload"})
        title = self.headers.get("X-Plan-Title", "Untitled plan")[:200]
        draft_id = secrets.token_hex(16) if create else match[1]
        with self.server.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            if create:
                db.execute("INSERT INTO drafts(id,title) VALUES (?,?)", (draft_id, title))
            elif not db.execute("SELECT 1 FROM drafts WHERE id=?", (draft_id,)).fetchone():
                return self.respond(404, {"error": "Draft not found"})
            version = db.execute("SELECT COALESCE(MAX(version),0)+1 FROM versions WHERE draft_id=?",
                                 (draft_id,)).fetchone()[0]
            db.execute("INSERT INTO versions VALUES (?,?,?)", (draft_id, version, html))
            db.execute("UPDATE drafts SET updated=strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE id=?",
                       (draft_id,))
            if "X-Plan-Title" in self.headers:
                db.execute("UPDATE drafts SET title=? WHERE id=?", (title, draft_id))
        url = f"{self.server.public_url}/d/{draft_id}"
        self.respond(201, {"id": draft_id, "version": version, "url": url,
                           "versionUrl": f"{url}/v/{version}", "rawUrl": f"{url}/raw"})


if __name__ == "__main__":
    Server(("127.0.0.1", int(os.environ.get("PORT", "8092"))),
           os.environ["DATA_DIR"], os.environ["KEY_FILE"],
           os.environ.get("PUBLIC_URL", "https://plans.jugi.cc")).serve_forever()
