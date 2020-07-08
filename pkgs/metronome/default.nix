{ stdenv
, libidn, openssl, lua }:

{ src, version }:

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
    # Wrapper doesn't contain the executable with a suffix
    # "--lua-suffix=${lua.luaversion}"
  ];

  nativeBuildInputs = [ libidn openssl ];

  preFixup = ''
    for file in $out/bin/metronome{,ctl} $out/lib/metronome/modules/register_api/send_mail; do
      sed -i \
        -e "s@\(CFG_CONFIGDIR=\).*@\1'/etc/metronome'@" \
        -e "s@\(CFG_DATADIR=\).*@\1'/var/lib/metronome'@" \
        $file
    done
  '';

  passthru = { lua = luaInterpreter; };
}
