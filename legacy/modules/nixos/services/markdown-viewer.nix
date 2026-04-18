{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.markdown-viewer;

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.flask
    ps.markdown
    ps.pygments
  ]);

  appScript = pkgs.writeScript "markdown-viewer.py" ''
    #!/usr/bin/env python3
    import os
    import markdown
    import functools
    from pathlib import Path
    from flask import Flask, render_template_string, request, abort, Response
    from pygments.formatters import HtmlFormatter

    app = Flask(__name__)
    DATA_DIR = os.environ.get("DATA_DIR", "/mnt/appdata/second-brain")
    AUTH_PASSWORD = os.environ.get("AUTH_PASSWORD", "")

    def check_auth(password):
        return password == AUTH_PASSWORD

    def authenticate():
        return Response(
            "Authentication required", 401,
            {"WWW-Authenticate": 'Basic realm="Notes"'}
        )

    def requires_auth(f):
        @functools.wraps(f)
        def decorated(*args, **kwargs):
            if not AUTH_PASSWORD:
                return f(*args, **kwargs)
            auth = request.authorization
            if not auth or not check_auth(auth.password):
                return authenticate()
            return f(*args, **kwargs)
        return decorated

    HTML_TEMPLATE = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
        <title>{{ title }} - Notes</title>
        <style>
            :root {
                --bg: #1a1a2e;
                --bg-secondary: #16213e;
                --text: #eee;
                --text-muted: #aaa;
                --accent: #4a9eff;
                --border: #333;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            html { font-size: 18px; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                background: var(--bg);
                color: var(--text);
                line-height: 1.6;
                min-height: 100vh;
            }
            .container { max-width: 900px; margin: 0 auto; padding: 1rem; }
            header {
                background: var(--bg-secondary);
                padding: 1rem;
                position: sticky;
                top: 0;
                z-index: 100;
                border-bottom: 1px solid var(--border);
            }
            .breadcrumb {
                display: flex;
                flex-wrap: wrap;
                gap: 0.5rem;
                align-items: center;
                font-size: 0.9rem;
            }
            .breadcrumb a {
                color: var(--accent);
                text-decoration: none;
                padding: 0.25rem 0.5rem;
                border-radius: 4px;
            }
            .breadcrumb a:hover { background: var(--border); }
            .breadcrumb span { color: var(--text-muted); }
            .search-box {
                margin-top: 0.75rem;
            }
            .search-box input {
                width: 100%;
                padding: 0.75rem 1rem;
                font-size: 1rem;
                border: 1px solid var(--border);
                border-radius: 8px;
                background: var(--bg);
                color: var(--text);
            }
            .search-box input:focus {
                outline: none;
                border-color: var(--accent);
            }
            .file-list { list-style: none; margin-top: 1rem; }
            .file-list li {
                border-bottom: 1px solid var(--border);
            }
            .file-list a {
                display: flex;
                align-items: center;
                gap: 0.75rem;
                padding: 1rem 0.5rem;
                color: var(--text);
                text-decoration: none;
                font-size: 1rem;
            }
            .file-list a:hover { background: var(--bg-secondary); }
            .file-list .icon { font-size: 1.5rem; }
            .file-list .folder .icon { color: #ffd43b; }
            .file-list .file .icon { color: var(--accent); }
            .file-list .meta {
                margin-left: auto;
                color: var(--text-muted);
                font-size: 0.8rem;
            }
            .content {
                padding: 1.5rem 0;
            }
            .content h1, .content h2, .content h3, .content h4 {
                margin: 1.5rem 0 0.75rem;
                color: var(--text);
            }
            .content h1 { font-size: 1.8rem; border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; }
            .content h2 { font-size: 1.4rem; }
            .content h3 { font-size: 1.2rem; }
            .content p { margin: 0.75rem 0; }
            .content ul, .content ol { margin: 0.75rem 0; padding-left: 1.5rem; }
            .content li { margin: 0.25rem 0; }
            .content a { color: var(--accent); }
            .content code {
                background: var(--bg-secondary);
                padding: 0.2rem 0.4rem;
                border-radius: 4px;
                font-size: 0.9rem;
            }
            .content pre {
                background: var(--bg-secondary);
                padding: 1rem;
                border-radius: 8px;
                overflow-x: auto;
                margin: 1rem 0;
            }
            .content pre code {
                background: none;
                padding: 0;
            }
            .content blockquote {
                border-left: 3px solid var(--accent);
                padding-left: 1rem;
                margin: 1rem 0;
                color: var(--text-muted);
            }
            .content table {
                width: 100%;
                border-collapse: collapse;
                margin: 1rem 0;
            }
            .content th, .content td {
                border: 1px solid var(--border);
                padding: 0.5rem;
                text-align: left;
            }
            .content th { background: var(--bg-secondary); }
            .content input[type="checkbox"] {
                margin-right: 0.5rem;
            }
            .section-title {
                font-size: 0.9rem;
                color: var(--text-muted);
                text-transform: uppercase;
                letter-spacing: 0.05em;
                margin: 1.5rem 0 0.5rem;
                padding: 0 0.5rem;
            }
            {{ pygments_css }}
        </style>
    </head>
    <body>
        <header>
            <nav class="breadcrumb">
                <a href="/">Home</a>
                {% for crumb in breadcrumbs %}
                <span>/</span>
                <a href="{{ crumb.path }}">{{ crumb.name }}</a>
                {% endfor %}
            </nav>
            <div class="search-box">
                <form action="/search" method="get">
                    <input type="search" name="q" placeholder="Search files..." value="{{ query or ''' }}">
                </form>
            </div>
        </header>
        <main class="container">
            {{ content | safe }}
        </main>
    </body>
    </html>
    """

    def get_breadcrumbs(path):
        parts = path.strip("/").split("/") if path.strip("/") else []
        breadcrumbs = []
        current = ""
        for part in parts:
            current += "/" + part
            breadcrumbs.append({"name": part, "path": current})
        return breadcrumbs

    def get_file_list(dir_path):
        items = []
        try:
            for entry in sorted(os.scandir(dir_path), key=lambda e: (not e.is_dir(), e.name.lower())):
                if entry.name.startswith("."):
                    continue
                rel_path = os.path.relpath(entry.path, DATA_DIR)
                if entry.is_dir():
                    items.append({
                        "name": entry.name,
                        "path": "/" + rel_path,
                        "is_dir": True,
                        "icon": "📁"
                    })
                elif entry.name.endswith(".md"):
                    stat = entry.stat()
                    items.append({
                        "name": entry.name[:-3],
                        "path": "/" + rel_path,
                        "is_dir": False,
                        "icon": "📄",
                        "size": stat.st_size
                    })
        except PermissionError:
            pass
        return items

    def get_recent_files(limit=10):
        files = []
        for root, dirs, filenames in os.walk(DATA_DIR):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for fname in filenames:
                if fname.endswith(".md") and not fname.startswith("."):
                    fpath = os.path.join(root, fname)
                    stat = os.stat(fpath)
                    rel_path = os.path.relpath(fpath, DATA_DIR)
                    files.append({
                        "name": fname[:-3],
                        "path": "/" + rel_path,
                        "mtime": stat.st_mtime,
                        "icon": "📄"
                    })
        files.sort(key=lambda x: x["mtime"], reverse=True)
        return files[:limit]

    def render_markdown(content):
        md = markdown.Markdown(extensions=[
            "fenced_code",
            "codehilite",
            "tables",
            "toc",
            "nl2br",
            "sane_lists"
        ], extension_configs={
            "codehilite": {"css_class": "highlight", "guess_lang": False}
        })
        return md.convert(content)

    @app.route("/")
    @requires_auth
    def index():
        items = get_file_list(DATA_DIR)
        recent = get_recent_files()
        
        content = '<p class="section-title">Folders & Files</p>'
        content += '<ul class="file-list">'
        for item in items:
            cls = "folder" if item["is_dir"] else "file"
            content += f'<li><a href="{item["path"]}" class="{cls}"><span class="icon">{item["icon"]}</span>{item["name"]}</a></li>'
        content += "</ul>"
        
        content += '<p class="section-title">Recent Files</p>'
        content += '<ul class="file-list">'
        for item in recent:
            content += f'<li><a href="{item["path"]}" class="file"><span class="icon">{item["icon"]}</span>{item["name"]}</a></li>'
        content += "</ul>"
        
        formatter = HtmlFormatter(style="monokai")
        return render_template_string(
            HTML_TEMPLATE,
            title="Home",
            breadcrumbs=[],
            content=content,
            pygments_css=formatter.get_style_defs(".highlight"),
            query=""
        )

    @app.route("/search")
    @requires_auth
    def search():
        query = request.args.get("q", "").lower()
        if not query:
            return render_template_string(
                HTML_TEMPLATE,
                title="Search",
                breadcrumbs=[],
                content='<p class="section-title">Enter a search term</p>',
                pygments_css="",
                query=""
            )
        
        results = []
        for root, dirs, filenames in os.walk(DATA_DIR):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for fname in filenames:
                if fname.endswith(".md") and not fname.startswith("."):
                    if query in fname.lower():
                        rel_path = os.path.relpath(os.path.join(root, fname), DATA_DIR)
                        results.append({
                            "name": fname[:-3],
                            "path": "/" + rel_path,
                            "icon": "📄"
                        })
        
        content = f'<p class="section-title">Results for "{query}"</p>'
        content += '<ul class="file-list">'
        for item in results:
            content += f'<li><a href="{item["path"]}" class="file"><span class="icon">{item["icon"]}</span>{item["name"]}</a></li>'
        content += "</ul>"
        if not results:
            content += "<p>No files found.</p>"
        
        return render_template_string(
            HTML_TEMPLATE,
            title="Search",
            breadcrumbs=[],
            content=content,
            pygments_css="",
            query=query
        )

    @app.route("/<path:filepath>")
    @requires_auth
    def view(filepath):
        full_path = os.path.join(DATA_DIR, filepath)
        full_path = os.path.normpath(full_path)
        
        if not full_path.startswith(DATA_DIR):
            abort(403)
        
        if not os.path.exists(full_path):
            abort(404)
        
        formatter = HtmlFormatter(style="monokai")
        breadcrumbs = get_breadcrumbs(filepath)
        
        if os.path.isdir(full_path):
            items = get_file_list(full_path)
            content = '<ul class="file-list">'
            for item in items:
                cls = "folder" if item["is_dir"] else "file"
                content += f'<li><a href="{item["path"]}" class="{cls}"><span class="icon">{item["icon"]}</span>{item["name"]}</a></li>'
            content += "</ul>"
            if not items:
                content = "<p>This folder is empty.</p>"
            
            return render_template_string(
                HTML_TEMPLATE,
                title=os.path.basename(full_path),
                breadcrumbs=breadcrumbs,
                content=content,
                pygments_css=formatter.get_style_defs(".highlight"),
                query=""
            )
        
        if full_path.endswith(".md"):
            with open(full_path, "r", encoding="utf-8") as f:
                md_content = f.read()
            html_content = render_markdown(md_content)
            content = f'<article class="content">{html_content}</article>'
            
            return render_template_string(
                HTML_TEMPLATE,
                title=os.path.basename(full_path)[:-3],
                breadcrumbs=breadcrumbs,
                content=content,
                pygments_css=formatter.get_style_defs(".highlight"),
                query=""
            )
        
        abort(404)

    if __name__ == "__main__":
        port = int(os.environ.get("PORT", 8585))
        app.run(host="0.0.0.0", port=port)
  '';
in
{
  options.plusultra.services.markdown-viewer = with types; {
    enable = mkBoolOpt false "Whether to enable the markdown viewer service.";
    port = mkOpt int 8585 "Port for the web server.";
    dataDir = mkOpt str "/mnt/appdata/second-brain" "Directory containing markdown files.";
    openFirewall = mkBoolOpt true "Whether to open the firewall for the service.";
    passwordFile =
      mkOpt (nullOr path) null
        "Path to file containing the password. If null, no auth required.";
  };

  config = mkIf cfg.enable {
    systemd.services.markdown-viewer = {
      description = "Markdown file viewer web service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      restartIfChanged = false;
      stopIfChanged = false;

      environment = {
        DATA_DIR = cfg.dataDir;
        PORT = toString cfg.port;
        PYTHONUNBUFFERED = "1";
      };

      script = ''
        ${lib.optionalString (cfg.passwordFile != null) ''
          if [ -f "$CREDENTIALS_DIRECTORY/password" ]; then
            export AUTH_PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/password")"
          fi
        ''}
        exec ${pythonEnv}/bin/python3 -u ${appScript}
      '';

      serviceConfig = {
        Type = "exec";
        Restart = "always";
        RestartSec = "10s";
        TimeoutStartSec = "5s";
        DynamicUser = true;
        BindReadOnlyPaths = [ cfg.dataDir ];
        NoNewPrivileges = true;
      }
      // lib.optionalAttrs (cfg.passwordFile != null) {
        LoadCredential = "password:${cfg.passwordFile}";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
