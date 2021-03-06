{ buildPythonPackage
, isPy3k
, argcomplete
, psutil
, pytz
, pyyaml
, toml
, ldap
, gevent-websocket
, bottle
, pytest
, pytest-cov
, pytest-env
, pytest-mock
, requests
, requests-mock
, webtest
}:

{ src, version }:

buildPythonPackage rec {
  pname = "moulinette";
  inherit version src;
  disabled = isPy3k;

  prePatch = ''
    sed -i 's@\(systemctl restart\) slapd@\1 openldap@' moulinette/authenticators/ldap.py
  '';

  propagatedBuildInputs = [
    argcomplete
    psutil
    pytz
    pyyaml
    toml
    ldap
    gevent-websocket
    bottle
  ];

  # pytest-cov doesn't compile on pyhon2
  doCheck = false;
  checkInputs = [
    pytest
    pytest-cov
    pytest-env
    pytest-mock
    requests
    requests-mock
    webtest
  ];
}
