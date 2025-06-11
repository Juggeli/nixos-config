{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
buildNpmPackage (finalAttrs: {
  pname = "task-master-ai";
  version = "0.16.2";

  src = fetchFromGitHub {
    owner = "eyaltoledano";
    repo = "claude-task-master";
    tag = "v${finalAttrs.version}";
    hash = "sha256-AfufOTq4ZR8dL5PwbkyrzF1VWc7hTjyHEqO8OMFooII=";
  };

  npmDepsHash = "sha256-WjPFg/jYTbxrKNzTyqb6e0Z+PLPg6O2k8LBIELwozo8=";

  dontNpmBuild = true;

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Node.js agentic AI workflow orchestrator";
    homepage = "https://task-master.dev";
    changelog = "https://github.com/eyaltoledano/claude-task-master/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = licenses.mit;
    mainProgram = "task-master-ai";
    maintainers = [ maintainers.repparw ];
    platforms = platforms.all;
  };
})
