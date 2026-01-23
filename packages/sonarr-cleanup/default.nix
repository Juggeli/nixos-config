{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "sonarr-cleanup";
  version = "1.0.0";
  format = "other";

  src = ./.;

  propagatedBuildInputs = with python3Packages; [
    requests
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp main.py $out/bin/sonarr-cleanup
    chmod +x $out/bin/sonarr-cleanup

    runHook postInstall
  '';

  meta = with lib; {
    description = "Clean up unwatched TV series from Sonarr based on Jellyfin/Plex watch history";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
