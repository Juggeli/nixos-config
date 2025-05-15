{ pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd 'uwsm start hyprland-uwsm.desktop'";
      };
      initial_session = {
        command = "uwsm start hyprland-uwsm.desktop";
        user = "juggeli";
      };
    };
  };
}
