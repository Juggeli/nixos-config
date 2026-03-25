{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "sonarr-anime-cleanup";
  version = "1.0.0";
  format = "other";

  src = ./.;

  propagatedBuildInputs = with python3Packages; [
    requests
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp main.py $out/bin/sonarr-anime-cleanup
    chmod +x $out/bin/sonarr-anime-cleanup

    runHook postInstall
  '';

  meta = with lib; {
    description = "Clean up fully watched anime series from Sonarr based on Jellyfin watch history";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
