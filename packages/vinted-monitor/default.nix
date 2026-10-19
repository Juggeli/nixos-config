{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "vinted-monitor";
  version = "1.0.0";
  format = "other";

  src = ./.;

  propagatedBuildInputs = with python3Packages; [
    requests
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp main.py $out/bin/vinted-monitor
    chmod +x $out/bin/vinted-monitor

    runHook postInstall
  '';

  meta = with lib; {
    description = "Send ntfy notifications for new listings in a Vinted search";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
