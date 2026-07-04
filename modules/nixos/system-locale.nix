{
  flake.nixosModules.system-locale =
    { lib, ... }:
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = lib.mkForce "us";
    };
}
