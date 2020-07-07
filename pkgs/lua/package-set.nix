/* pkgs/lua/package-set.nix is an auto-generated file -- DO NOT EDIT!
Regenerate it with:
nixpkgs$ ../nixpkgs/maintainers/scripts/update-luarocks-packages pkgs/lua/package-set.nix

These packages are manually refined in lua-overrides.nix
*/
{ self, stdenv, fetchurl, fetchgit, pkgs, ... } @ args:
self: super:
with self;
{

  luajson = buildLuarocksPackage {
    pname = "luajson";
    version = "1.3.4-1";

    src = fetchurl {
      url = mirror://luarocks/luajson-1.3.4-1.src.rock;
      sha256 = "077h00bmcvvjqbj7v6s88q8wpp7ixgssxklskbx7kzg4ya695998";
    };
    disabled = (luaOlder "5.1");
    propagatedBuildInputs = [ lua lpeg ];

    meta = with stdenv.lib; {
      homepage = "http://github.com/harningt/luajson";
      description = "customizable JSON decoder/encoder";
      license.fullName = "MIT/X11";
    };
  };
  lualdap = buildLuarocksPackage {
    pname = "lualdap";
    version = "1.2.4.rc1-0";

    src = fetchurl {
      url = mirror://luarocks/lualdap-1.2.4.rc1-0.src.rock;
      sha256 = "1a46nvkzhsayczj7dxxd7hmacm0wz3dg1vmyh0m0f5k5dz8dlvci";
    };
    disabled = (luaOlder "5.1");
    propagatedBuildInputs = [ lua ];

    meta = with stdenv.lib; {
      homepage = "https://github.com/bdellegrazie/lualdap";
      description = "Simple interface from Lua to an LDAP Client";
      license.fullName = "MIT";
    };
  };
  luafilesystem = buildLuarocksPackage {
    pname = "luafilesystem";
    version = "1.8.0-1";

    src = fetchurl {
      url = mirror://luarocks/luafilesystem-1.8.0-1.src.rock;
      sha256 = "1kqr1vwazrysgxamx9x89vn3fparfffx986bq9a452ajayjp0qjp";
    };
    disabled = (luaOlder "5.1");
    propagatedBuildInputs = [ lua ];

    meta = with stdenv.lib; {
      homepage = "git://github.com/keplerproject/luafilesystem";
      description = "File System Library for the Lua Programming Language";
      license.fullName = "MIT/X11";
    };
  };
  lrexlib-pcre = buildLuarocksPackage {
    pname = "lrexlib-pcre";
    version = "2.9.0-1";

    src = fetchurl {
      url = mirror://luarocks/lrexlib-pcre-2.9.0-1.src.rock;
      sha256 = "1nqai27lbd85mcjf5cb05dbdfg460vmp8cr0lmb8dd63ivk8cbvx";
    };
    disabled = (luaOlder "5.1");
    propagatedBuildInputs = [ lua ];

    meta = with stdenv.lib; {
      homepage = "http://github.com/rrthomas/lrexlib";
      description = "Regular expression library binding (PCRE flavour).";
      license.fullName = "MIT/X11";
    };
  };
  luasocket = buildLuarocksPackage {
    pname = "luasocket";
    version = "3.0rc1-2";

    src = fetchurl {
      url = mirror://luarocks/luasocket-3.0rc1-2.src.rock;
      sha256 = "1isin9m40ixpqng6ds47skwa4zxrc6w8blza8gmmq566w6hz50iq";
    };
    disabled = (luaOlder "5.1");
    propagatedBuildInputs = [ lua ];

    meta = with stdenv.lib; {
      homepage = "http://luaforge.net/projects/luasocket/";
      description = "Network support for the Lua language";
      license.fullName = "MIT";
    };
  };

}
/* GENERATED */
