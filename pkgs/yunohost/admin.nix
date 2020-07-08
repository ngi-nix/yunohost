{ stdenv
, nodejs
, fetchNodeModules
, gifsicle
, optipng
}:

{ src, version, rngid }:

stdenv.mkDerivation rec {
  pname = "yunohost-admin";
  inherit src version;

  node_modules = fetchNodeModules {
    src = "${src}/src";
    nodejs = nodejs;
    sha256 = "0ii6hpgi1znmd6dfw5hxc6c6jl7d66vswipvqydv3jh4z9m0wdhd";
  };

  buildPhase = ''
    runHook preBuild

    # debian/rules
    cp -r ${node_modules} src/node_modules
    chmod 755 src/node_modules/{gifsicle,optipng-bin}/vendor
    ln -s ${gifsicle}/bin/gifsicle src/node_modules/gifsicle/vendor/
    ln -s ${optipng}/bin/optipng src/node_modules/optipng-bin/vendor/
    (cd src; ${nodejs}/bin/node node_modules/gulp/bin/gulp.js build)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # debian/install
    mkdir -p $out/share/yunohost/admin
    cp --target-directory $out/share/yunohost/admin -r src/{dist,locales,views,index.html}

    # debian/postinst
    sed -i "s/RANDOMID/${rngid}/g" $out/share/yunohost/admin/index.html

    runHook postInstall
  '';
}
