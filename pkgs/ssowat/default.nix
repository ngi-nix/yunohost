{ src, version }:
{ stdenv, luaPackages }:

stdenv.mkDerivation rec {
  pname = "ssowat";
  inherit version src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/etc/ssowat
    cp -r ./* $out/etc/ssowat

    runHook postInstall
  '';
}
