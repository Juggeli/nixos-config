"""Publish self-contained HTML without exposing credentials in command arguments."""

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api-url", default=os.environ.get("PLANS_API_URL", "https://plans.jugi.cc"))
    parser.add_argument("--key-file", default=os.environ.get("PLANS_KEY_FILE"))
    commands = parser.add_subparsers(dest="command", required=True)
    upload = commands.add_parser("upload")
    upload.add_argument("file", type=Path)
    upload.add_argument("--title", help="Short ASCII label")
    upload.add_argument("--id", help="Existing draft ID; appends a version and preserves its URL")
    commands.add_parser("list")
    args = parser.parse_args()
    if not args.key_file:
        parser.error("Use the configured publish-plan command or provide --key-file")
    url = args.api_url.rstrip("/")
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https" and not (parsed.scheme == "http" and parsed.hostname in ("127.0.0.1", "localhost")):
        parser.error("API URL must use HTTPS (except localhost)")
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        parser.error("API URL must be a plain origin")
    key = Path(args.key_file).read_text().strip()
    headers = {"Authorization": f"Bearer {key}", "User-Agent": "publish-plan/1.0"}
    data = None
    method = "GET"
    path = "/api/drafts"
    if args.command == "upload":
        data = args.file.read_bytes()
        if not 0 < len(data) <= 5 * 1024 * 1024:
            parser.error("HTML must be between 1 byte and 5 MiB")
        data.decode("utf-8")
        headers["Content-Type"] = "text/html; charset=utf-8"
        if args.title:
            if not args.title.isascii() or any(ord(c) < 32 or ord(c) == 127 for c in args.title):
                parser.error("Title must be ASCII without control characters")
            headers["X-Plan-Title"] = args.title
        method = "POST"
        if args.id:
            import re
            if not re.fullmatch(r"[a-f0-9]{32}", args.id):
                parser.error("Invalid draft ID")
            method = "PUT"
            path += "/" + args.id
    request = urllib.request.Request(url + path, data=data, headers=headers, method=method)
    opener = urllib.request.build_opener(NoRedirect)
    with opener.open(request, timeout=30) as response:
        print(json.dumps(json.load(response), indent=2))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, urllib.error.URLError) as error:
        print(f"publish-plan: {error}", file=sys.stderr)
        sys.exit(1)
