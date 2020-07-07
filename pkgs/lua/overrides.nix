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
}
