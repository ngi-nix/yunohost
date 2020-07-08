{ stdenv, lua }:

{ src, version }:
let
  luaInterpreter = lua.withPackages (ps: with ps;
    [
      luajson
      lualdap
      luafilesystem
      luasocket
      lrexlib-pcre
    ]
  );
in
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

  passthru = { lua = luaInterpreter; };
}
