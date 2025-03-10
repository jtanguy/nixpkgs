{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, installShellFiles
, libiconv
, Security
}:

rustPlatform.buildRustPackage rec {
  pname = "starship";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "starship";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-KU9IbvQ6qPbSoHVRN/g7iETV47Y4wMMESzpRHMQ0Uxw=";
  };

  nativeBuildInputs = [ installShellFiles ] ++ lib.optionals stdenv.isLinux [ pkg-config ];

  buildInputs = lib.optionals stdenv.isLinux [ openssl ]
    ++ lib.optionals stdenv.isDarwin [ libiconv Security ];

  buildFeatures = lib.optional (!stdenv.isDarwin) "notify-rust";

  postInstall = ''
    for shell in bash fish zsh; do
      STARSHIP_CACHE=$TMPDIR $out/bin/starship completions $shell > starship.$shell
      installShellCompletion starship.$shell
    done
  '';

  cargoSha256 = "sha256-IzTRvvQ1uHS2WY2Cf8VQOq423PjwXYNW4bub0ZyvTIE=";

  preCheck = ''
    HOME=$TMPDIR
  '';

  meta = with lib; {
    description = "A minimal, blazing fast, and extremely customizable prompt for any shell";
    homepage = "https://starship.rs";
    license = licenses.isc;
    maintainers = with maintainers; [ bbigras davidtwco Br1ght0ne Frostman marsam ];
  };
}
