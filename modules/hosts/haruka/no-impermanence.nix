{
  flake.nixosModules.haruka-no-impermanence =
    { lib, ... }:
    {
      environment.persistence = lib.mkForce { };
    };
}
