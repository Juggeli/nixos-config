{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
      };
      initial_session = {
        command = "sway";
        user = "juggeli";
      };
    };
  };
}
