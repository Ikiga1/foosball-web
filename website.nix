{ stdenv,
  lib,
  # Url of the API (empty if the API is part of the current website)
  domainAPI ? "",
  ...
}:
stdenv.mkDerivation {
  src = ./.;
  pname = "cwi-foosball-web";
  version = "1.0";
  postPatch = ''
    substituteInPlace js/config.js --replace 'API_URL = ""' 'API_URL = "${domainAPI}"'
  '';
  installPhase = ''
    mkdir -p $out
    cp -r *.html js/ img/ sounds/ css/ $out
  '' + lib.optionalString (domainAPI == "") ''
    cp -r admin/ api/ create_database.sql $out
    ## TODO: change the password in phpliteadmin.config.php, ideally outside of the store.
  '';
}
