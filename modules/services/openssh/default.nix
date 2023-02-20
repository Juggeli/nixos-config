{ options, config, pkgs, lib, systems, name, format, inputs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.services.openssh;

  user = config.users.users.${config.plusultra.user.name};
  user-id = builtins.toString user.uid;

  default-key =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpvXZ6hWXrKgvX1ce+v+tmjYO2EuW9YjS8o5N7vmfRO juggeli@gmail.com";

  other-hosts = lib.filterAttrs
    (key: host:
      key != name && (host.config.plusultra.user.name or null) != null)
    ((inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { }));

  other-hosts-config = lib.concatMapStringsSep
    "\n"
    (name:
      let
        remote = other-hosts.${name};
        remote-user-name = remote.config.plusultra.user.name;
        remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;
      in
      ''
        Host ${name}
          User ${remote-user-name}
          ForwardAgent yes
          Port ${builtins.toString cfg.port}
      ''
    )
    (builtins.attrNames other-hosts);
in
{
  options.plusultra.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys =
      mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = if format == "install-iso" then "yes" else "no";

      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [
        22
        cfg.port
      ];
    };

    programs.ssh.extraConfig = ''
      Host *
        HostKeyAlgorithms +ssh-rsa
      ${other-hosts-config}
    '';

    plusultra.user.extraOptions.openssh.authorizedKeys.keys =
      cfg.authorizedKeys;
  };
}
