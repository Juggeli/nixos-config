{
  flake.nixosModules.haruka-storage =
    { config, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        btrfs-progs
        cryptsetup
        hdparm
      ];

      powerManagement.powerUpCommands = with pkgs; ''
        for dev in /dev/sd[a-z]; do
          if [ -b "$dev" ]; then
            ${hdparm}/bin/hdparm -S 242 -B 127 "$dev" || true
          fi
        done
      '';

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
          mail = {
            enable = true;
            sender = "smartd@haruka";
            recipient = "root";
            mailer = "${pkgs.writeShellScript "ntfy-smartd" ''
              topic=$(${pkgs.coreutils}/bin/cat "${config.age.secrets.ntfy-topic.path}")

              if [ -n "$SMARTD_DEVICE" ]; then
                device="$SMARTD_DEVICE"
                message="$SMARTD_MESSAGE"
                subject="SMART Alert: $device"
              else
                email_content=$(${pkgs.coreutils}/bin/cat)
                device=$(echo "$email_content" | ${pkgs.gnugrep}/bin/grep -o "/dev/[a-z0-9]*" | ${pkgs.coreutils}/bin/head -1 || echo "Unknown Device")

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
