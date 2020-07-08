{ pkgs, ... }:
final: prev:

{
  # extraVariables fails with some error message regarding types I can't decipher
  lualdap = prev.lualdap.override {
    externalDeps =
      [
        { name = "LBER"; dep = pkgs.openldap; }
        { name = "LDAP"; dep = pkgs.openldap; }
      ];
  };

  lrexlib-pcre = prev.lrexlib-pcre.override {
    externalDeps = [{ name = "PCRE"; dep = pkgs.pcre; }];
  };

  luaexpat = prev.luaexpat.override {
    externalDeps = [{ name = "EXPAT"; dep = pkgs.expat; }];
  };

  luaevent = prev.luaevent.override {
    externalDeps = [{ name = "EVENT"; dep = pkgs.libevent; }];
  };

  luasec = prev.luasec.override {
    externalDeps = [{ name = "OPENSSL"; dep = pkgs.openssl; }];
  };

  lua-zlib = prev.lua-zlib.override {
    externalDeps = [{ name = "ZLIB"; dep = pkgs.zlib; }];
  };
}
