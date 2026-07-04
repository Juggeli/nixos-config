{
  flake.nixosModules.haruka-acme = {
    security.acme = {
      acceptTerms = true;
      defaults.email = "juggeli@gmail.com";
    };
  };
}
