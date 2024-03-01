{ lib, config, ... }:

with lib;
with lib.plusultra; let
  cfg = config.plusultra.user;
in
{
  options.plusultra.user = {
    name = mkOpt types.str "juggeli" "The user account.";
    fullName = mkOpt types.str "Jukka Alavesa" "The full name of the user.";
    email = mkOpt types.str "jukka.alavesa@codemate.com" "The email of the user.";
    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      # @NOTE(jakehamilton): Setting the uid here is required for another
      # module to evaluate successfully since it reads
      # `users.users.${plusultra.user.name}.uid`.
      uid = mkIf (cfg.uid != null) cfg.uid;
    };

    plusultra.home.file.".profile".text = ''
      # The default file limit is far too low and throws an error when rebuilding the system.
      # See the original with: ulimit -Sa
      ulimit -n 4096
    '';
  };
}

