{
  flake.nixosModules.logitech-mouse-resume =
    { pkgs, ... }:
    {
      systemd.services.logitech-mouse-resume = {
        description = "Reload Logitech mouse drivers after resume from sleep";
        after = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "logitech-mouse-resume" ''
            #!/usr/bin/env bash

            sleep 3

            for device in /sys/bus/usb/devices/*; do
              if [[ -f "$device/idVendor" ]] && [[ -f "$device/idProduct" ]]; then
                vendor=$(cat "$device/idVendor")
                product=$(cat "$device/idProduct")

                if [[ "$vendor" == "046d" ]]; then
                  device_name=$(basename "$device")
                  echo "Found Logitech device: $device_name (vendor=$vendor, product=$product)"

                  if [[ -f "/sys/bus/usb/drivers/usb/unbind" ]] && [[ -f "/sys/bus/usb/drivers/usb/bind" ]]; then
                    echo "$device_name" > /sys/bus/usb/drivers/usb/unbind
                    sleep 1
                    echo "$device_name" > /sys/bus/usb/drivers/usb/bind
                    echo "Reset Logitech device: $device_name"
                  fi
                fi
              fi
            done
          '';
        };
      };
    };
}
