{ src, version }:
{ stdenv
, python }:

let
  pythonInterpreter = python.withPackages (ps: with ps; [
    pyyaml jinja2
  ]);
in
stdenv.mkDerivation {
  pname = "yunohost";
  inherit src version;

  buildPhase = ''
    runHook preBuild

    # debian/rules
    ${pythonInterpreter}/bin/python data/actionsmap/yunohost_completion.py
    ${pythonInterpreter}/bin/python doc/generate_manpages.py --gzip --output doc/yunohost.8.gz

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # debian/install
    sed -i 's@/usr@@g' debian/install
    while IFS= read -r line; do
      src="$(echo "$line" | awk '{print $1}')"
      dest="$(echo "$line" | awk '{print $2}')"

      mkdir -p $out$dest
      cp -r $src $out$dest
    done < debian/install

    mkdir -p $out/lib/systemd/system
    cp debian/*.service $out/lib/systemd/system

    runHook postInstall
  '';
}
