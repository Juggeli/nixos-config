{
  flake.nixosModules.tmpfs = {
    boot.tmp = {
      useTmpfs = true;
      tmpfsSize = "50%";
    };
  };
}
