{
  lib,
  python3Packages,
}:

python3Packages.buildPythonApplication {
  pname = "hdd-scraper";
  version = "1.0.0";
  format = "other";

  src = ../../tools/hdd-scraper;

  propagatedBuildInputs = with python3Packages; [
    requests
    beautifulsoup4
    lxml
    tabulate
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp hdd_scraper.py $out/bin/hdd-scraper
    chmod +x $out/bin/hdd-scraper

    runHook postInstall
  '';

  meta = with lib; {
    description = "Fetch and analyze HDD prices from tietokonekauppa.fi";
    homepage = "https://tietokonekauppa.fi";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
