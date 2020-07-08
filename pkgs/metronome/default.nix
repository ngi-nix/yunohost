{ src, version }:
{ stdenv
, libidn, openssl, lua }:

let
  luaInterpreter = lua.withPackages (ps: with ps;
    [
      luasocket
      luaexpat
      luafilesystem
      luaevent
      luasec
      lua-zlib
      luadbi
    ]);
in
stdenv.mkDerivation {
  pname = "metronome";
  inherit version src;

  configureFlags = [
    "--ostype=linux"

    "--with-lua-include=${lua}/include"
    "--with-lua=${luaInterpreter}/bin/lua"
    "--with-lua-lib=${luaInterpreter}/lib/lua/${lua.luaversion}"
    "--lua-suffix=${lua.luaversion}"
  ];

  nativeBuildInputs = [ libidn openssl ];
}
