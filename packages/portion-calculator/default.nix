{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
}:

buildNpmPackage {
  pname = "portion-calculator";
  version = "1.0.0";

  # The client bundle (public/app.js) and node_modules are generated, so they
  # are excluded here and produced during the build.
  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: type:
      let
        base = baseNameOf path;
      in
      base != "node_modules"
      && base != "data"
      && base != "app.js"
      && base != "result"
      && base != ".gitignore"
      && base != ".agents"
      && base != ".claude"
      && base != "skills-lock.json"
      && base != "REBUILD_PROMPT.md";
  };

  npmDepsHash = "sha256-OTh4ULKxiSca3huQ4xRzlFQ8OkBqeY4c9+2qLcK9Y6I=";

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec
    cp -r src package.json node_modules $out/libexec/
    mkdir -p $out/libexec/public
    cp public/index.html public/styles.css public/app.js $out/libexec/public/

    mkdir -p $out/bin
    makeWrapper "${lib.getExe nodejs}" "$out/bin/portion-calculator" \
      --add-flags "$out/libexec/src/main.ts" \
      --set NODE_ENV production

    runHook postInstall
  '';

  meta = {
    description = "Mobile-first web app for calculating food portion weights from batch cooking";
    license = lib.licenses.mit;
    mainProgram = "portion-calculator";
    platforms = lib.platforms.linux;
  };
}
