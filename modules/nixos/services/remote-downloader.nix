{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.remote-downloader;

  downloaderBrr = pkgs.writeShellApplication {
    name = "downloaderBrr";
    runtimeInputs = [ pkgs.rclone ];
    text = ''
      set -euo pipefail

      if [ $# -ne 2 ]; then
        echo "Usage: $0 <source> <destination>"
        exit 1
      fi

      SOURCE="''${1}"
      DEST="''${2}"

      if [ ! -d "''${DEST}" ]; then
        echo "Error: Destination directory ''${DEST} does not exist"
        exit 1
      fi

      echo "Moving from ''${SOURCE} to ''${DEST}"
      rclone -v move "''${SOURCE}" "''${DEST}" --delete-empty-src-dirs --config "''${RCLONE_CONFIG}"
    '';
  };

  webhookScript = pkgs.writeScript "download-webhook.py" ''
    #!/usr/bin/env python3
    import http.server
    import subprocess
    import json
    import os

    class WebhookHandler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            if self.path == '/trigger-download':
                # Check auth header
                auth = self.headers.get('Authorization')
                expected_token = os.environ.get('WEBHOOK_TOKEN', "")
                if not expected_token or auth != f'Bearer {expected_token}':
                    self.send_response(401)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': 'unauthorized'}).encode())
                    return
                
                try:
                    subprocess.run(['/run/wrappers/bin/doas', 'systemctl', 'start', 'downloaderBrr'], check=True)
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'status': 'triggered'}).encode())
                except Exception as e:
                    self.send_response(500)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': str(e)}).encode())
            else:
                self.send_response(404)
                self.end_headers()
        
        def log_message(self, format, *args):
            pass

    httpd = http.server.HTTPServer(('127.0.0.1', 8081), WebhookHandler)
    httpd.serve_forever()
  '';
in
{
  options.plusultra.services.remote-downloader = with types; {
    enable = mkBoolOpt false "Whether to enable remote download service.";
    
    mappings = mkOpt (listOf (submodule {
      options = {
        src = mkOpt str "" "Source path for downloads.";
        dest = mkOpt str "" "Destination path for downloads.";
      };
    })) [] "Download path mappings.";

    webhook = {
      enable = mkBoolOpt true "Enable webhook for immediate triggers.";
      port = mkOpt int 8081 "Port for webhook server.";
    };

    timer = {
      interval = mkOpt str "5m" "Timer interval for regular downloads.";
    };
  };

  config = mkIf cfg.enable {
    users.users.download-webhook = {
      isSystemUser = true;
      group = "download-webhook";
      extraGroups = [ "systemd-journal" "media" ];
      description = "Download webhook service user";
    };

    users.groups.download-webhook = {};
    users.groups.media.gid = 983;

    systemd.tmpfiles.rules = 
      [ "d /tank/media/downloads 0775 root media -" ] ++
      (map (mapping: 
        "d ${mapping.dest} 0775 root media -"
      ) cfg.mappings);

    age.secrets.downloader-rclone-conf = {
      owner = "download-webhook";
      group = "download-webhook";
      mode = "0400";
    };

    systemd.services.downloaderBrr = {
      description = "download all stuff from brr";
      serviceConfig = {
        User = "download-webhook";
        Group = "media";
        Type = "oneshot";
        UMask = "0002";
      };
      environment = {
        RCLONE_CONFIG = config.age.secrets.downloader-rclone-conf.path;
      };
      script = lib.concatMapStringsSep "\n" (
        mapping: "${downloaderBrr}/bin/downloaderBrr ${mapping.src} ${mapping.dest}"
      ) cfg.mappings;
    };

    systemd.timers.downloaderBrr = {
      wantedBy = [ "timers.target" ];
      partOf = [ "downloaderBrr.service" ];
      timerConfig = {
        OnUnitActiveSec = cfg.timer.interval;
        OnBootSec = cfg.timer.interval;
        Unit = "downloaderBrr.service";
      };
    };

    systemd.services.download-webhook = mkIf cfg.webhook.enable {
      description = "Download trigger webhook";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "download-webhook";
        Group = "download-webhook";
        Restart = "always";
        RestartSec = "10s";
        ExecStart = "${pkgs.python3}/bin/python3 ${webhookScript}";
        EnvironmentFile = config.age.secrets.webhook-token.path;
      };
    };

    security.doas.extraRules = [{
      users = [ "download-webhook" ];
      noPass = true;
      cmd = "systemctl";
      args = [ "start" "downloaderBrr" ];
    }];
  };
}