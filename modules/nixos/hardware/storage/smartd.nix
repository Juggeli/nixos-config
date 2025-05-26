{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.hardware.storage.smartd;
in
{
  options.plusultra.hardware.storage.smartd = with types; {
    enable = mkBoolOpt false "Whether to enable SMART monitoring for HDDs";
    ntfy = mkBoolOpt true "Whether to send notifications via ntfy";
  };

  config = mkIf cfg.enable {
    services.smartd = {
      enable = true;
      autodetect = false;
      devices = [
        {
          device = "/dev/sda";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,50";
        }
        {
          device = "/dev/sdb";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,50";
        }
        {
          device = "/dev/sdc";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,50";
        }
        {
          device = "/dev/sdd";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,50";
        }
        {
          device = "/dev/sde";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,50";
        }
        {
          device = "/dev/sdf";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,45,50";
        }
        {
          device = "/dev/nvme0";
          options = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03)";
        }
      ];
      notifications = {
        x11.enable = false;
        wall.enable = false;
        mail = mkIf cfg.ntfy {
          enable = true;
          sender = "smartd@haruka";
          recipient = "root";
          mailer = "${pkgs.writeShellScript "ntfy-smartd" ''
            topic=$(${pkgs.coreutils}/bin/cat "${config.age.secrets.ntfy-topic.path}")

            # smartd passes device and message info as environment variables
            # Use SMARTD_* environment variables if available, otherwise parse stdin
            if [ -n "$SMARTD_DEVICE" ]; then
              device="$SMARTD_DEVICE"
              message="$SMARTD_MESSAGE"
              subject="SMART Alert: $device"
            else
              # Fallback: read from stdin and extract device info
              email_content=$(${pkgs.coreutils}/bin/cat)
              device=$(echo "$email_content" | ${pkgs.gnugrep}/bin/grep -o "/dev/[a-z0-9]*" | ${pkgs.coreutils}/bin/head -1 || echo "Unknown Device")
              
              # Extract temperature or error info from the message
              if echo "$email_content" | ${pkgs.gnugrep}/bin/grep -q "Temperature"; then
                temp_info=$(echo "$email_content" | ${pkgs.gnugrep}/bin/grep "Temperature" | ${pkgs.coreutils}/bin/head -1)
                message="$temp_info"
                subject="Temperature Alert: $device"
              elif echo "$email_content" | ${pkgs.gnugrep}/bin/grep -q "SMART"; then
                smart_info=$(echo "$email_content" | ${pkgs.gnugrep}/bin/grep "SMART" | ${pkgs.coreutils}/bin/head -1)
                message="$smart_info"
                subject="SMART Alert: $device"
              else
                message="SMART monitoring alert for $device"
                subject="SMART Alert: $device"
              fi
            fi

            # Send to ntfy
            ${pkgs.curl}/bin/curl -s \
              -H "Title: $subject" \
              -H "Priority: high" \
              -H "Tags: warning,hdd" \
              -d "$message" \
              "https://ntfy.sh/$topic"
          ''}";
        };
      };
    };
  };
}
