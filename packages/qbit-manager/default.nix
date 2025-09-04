{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "qbit-manager";
  version = "1.0.0";
  format = "other";

  src = ./.;

  propagatedBuildInputs = with python3Packages; [
    qbittorrent-api
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp main.py $out/bin/qbit-manager
    chmod +x $out/bin/qbit-manager

    runHook postInstall
  '';

  meta = with lib; {
    description = "qBittorrent management tool for automated categorization and cleanup";
    homepage = "https://github.com/user/dotfiles";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
