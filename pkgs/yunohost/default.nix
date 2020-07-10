{ stdenv
, python2
}:

{ src, version }:
let
  pythonInterpreter = python2.withPackages (ps: with ps; [
    pyyaml
    jinja2

    psutil
    requests
    dnspython
    pyopenssl
    miniupnpc
    dbus-python
    jinja2
    toml
    packaging
    publicsuffix
    pip
    moulinette
  ]);
in
stdenv.mkDerivation {
  pname = "yunohost";
  inherit src version;

  buildInputs = [ pythonInterpreter ];

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
    for service in $out/lib/systemd/system/*; do
      sed -i "s@/usr/bin@$out/bin@g" $service
    done

    runHook postInstall
  '';

  preFixup = ''
    for f in `grep -lr /usr/share/yunohost $out | grep -v share/yunohost/templates`; do
      sed -i "s@/usr/share/yunohost@$out/share/yunohost@g" $f
    done
  '';

  passthru = { python = pythonInterpreter; };
}
