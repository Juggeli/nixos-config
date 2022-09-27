{ config, options, lib, home-manager, ... }:

with lib;
with lib.my;
{
  options = with types; {
    user = mkOpt attrs {};

    dotfiles = {
      dir = mkOpt path
        (findFirst pathExists (toString ../.) [
          "${config.user.home}/.config/dotfiles"
          "/etc/dotfiles"
        ]);
      binDir     = mkOpt path "${config.dotfiles.dir}/bin";
      configDir  = mkOpt path "${config.dotfiles.dir}/config";
      modulesDir = mkOpt path "${config.dotfiles.dir}/modules";
      themesDir  = mkOpt path "${config.dotfiles.modulesDir}/themes";
    };

    home = {
      file       = mkOpt' attrs {} "Files to place directly in $HOME";
      # configFile = mkOpt' attrs {} "Files to place in $XDG_CONFIG_HOME";
      dataFile   = mkOpt' attrs {} "Files to place in $XDG_DATA_HOME";
      systemDirs = mkOpt' attrs {} "Files to plaec in system dir";
      gtk        = mkOpt' attrs {} "GTK theme";
      sway       = mkOpt' attrs {} "Sway config";
      programs   = mkOpt' attrs {} "Home-manager programs";
      packages   = mkOpt' attrs [] "Home-manager packages";
      sessionVariables = mkOpt' attrs {} "Home-manager session variables";
    };

    xdg = {
      configFile = mkOpt' attrs {} "Home-manager xdg conf file";
    };

    # systemd = {
    #   user = {
    #     extraConfig = mkOpt' attrs {} "";
    #     paths = mkOpt' attrs {} "";
    #     services = mkOpt' attrs {} "";
    #     slices = mkOpt' attrs {} "";
    #     sockets = mkOpt' attrs {} "";
    #     targets = mkOpt' attrs {} "";
    #     timers = mkOpt' attrs {} "";
    #     units = mkOpt' attrs {} "";
    #   };
    # };

    env = mkOption {
      type = attrsOf (oneOf [ str path (listOf (either str path)) ]);
      apply = mapAttrs
        (n: v: if isList v
               then concatMapStringsSep ":" (x: toString x) v
               else (toString v));
      default = {};
      description = "TODO";
    };
  };

  config = {
    user =
      let user = builtins.getEnv "USER";
          name = if elem user [ "" "root" ] then "juggeli" else user;
      in {
        inherit name;
        description = "The primary user account";
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        home = "/home/${name}";
        group = "users";
        uid = 1001;
      };

    # Install user packages to /etc/profiles instead. Necessary for
    # nixos-rebuild build-vm to work.
    home-manager = {
      useUserPackages = true;

      # I only need a subset of home-manager's capabilities. That is, access to
      # its home.file, home.xdg.configFile and home.xdg.dataFile so I can deploy
      # files easily to my $HOME, but 'home-manager.users.hlissner.home.file.*'
      # is much too long and harder to maintain, so I've made aliases in:
      #
      #   home.file        ->  home-manager.users.hlissner.home.file
      #   home.configFile  ->  home-manager.users.hlissner.home.xdg.configFile
      #   home.dataFile    ->  home-manager.users.hlissner.home.xdg.dataFile
      users.${config.user.name} = {
        home = {
          file = mkAliasDefinitions options.home.file;
          # Necessary for home-manager to work with flakes, otherwise it will
          # look for a nixpkgs channel.
          stateVersion = config.system.stateVersion;
          packages = mkAliasDefinitions options.home.packages;
          sessionVariables = mkAliasDefinitions options.home.sessionVariables;
        };
        gtk = mkAliasDefinitions options.home.gtk;
        xdg = {
          configFile = mkAliasDefinitions options.xdg.configFile;
          dataFile   = mkAliasDefinitions options.home.dataFile;
          systemDirs = mkAliasDefinitions options.home.systemDirs;
        };
        wayland.windowManager.sway = mkAliasDefinitions options.home.sway;
        programs = mkAliasDefinitions options.home.programs;
        # systemd = {
        #   user = {
        #     extraConfig = mkAliasDefinitions options.systemd.user.extraConfig;
        #     paths = mkAliasDefinitions options.systemd.user.paths;
        #     services = mkAliasDefinitions options.systemd.user.services;
        #     slices = mkAliasDefinitions options.systemd.user.slices;
        #     sockets = mkAliasDefinitions options.systemd.user.sockets;
        #     targets = mkAliasDefinitions options.systemd.user.targets;
        #     timers = mkAliasDefinitions options.systemd.user.timers;
        #     units = mkAliasDefinitions options.systemd.user.units;
        #   };
        # };
      };
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix.settings = let users = [ "root" config.user.name ]; in {
      trusted-users = users;
      allowed-users = users;
    };

    # must already begin with pre-existing PATH. Also, can't use binDir here,
    # because it contains a nix store path.
    env.PATH = [ "$DOTFILES_BIN" "$XDG_BIN_HOME" "$PATH" ];

    environment.extraInit =
      concatStringsSep "\n"
        (mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.env);
  };
}
