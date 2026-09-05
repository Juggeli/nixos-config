{
  flake.homeModules.publish-plan =
    { config, pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [
          (pkgs.callPackage ../../packages/plans {
            keyFile = config.age.secrets.plans-publish-key.path;
          })
        ];
        home.file = {
          ".agents/skills/publish-plan".source = ../../packages/plans/skill;
          ".claude/skills/publish-plan".source = ../../packages/plans/skill;
        };
      };
    };
}
