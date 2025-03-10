{ lib
, fetchFromGitHub
, vscode-utils
, jq
, rust-analyzer
, nodePackages
, moreutils
, esbuild
, pkg-config
, libsecret
, setDefaultServerPath ? true
}:

let
  pname = "rust-analyzer";
  publisher = "matklad";

  # Use the plugin version as in vscode marketplace, updated by update script.
  inherit (vsix) version;

  releaseTag = "2021-11-29";

  src = fetchFromGitHub {
    owner = "rust-analyzer";
    repo = "rust-analyzer";
    rev = releaseTag;
    sha256 = "sha256-vh7z8jupVxXPOko3sWUsOB7eji/7lKfwJ/CE3iw97Sw=";
  };

  build-deps = nodePackages."rust-analyzer-build-deps-../../misc/vscode-extensions/rust-analyzer/build-deps";
  # FIXME: Making a new derivation to link `node_modules` and run `npm run package`
  # will cause a build failure.
  vsix = build-deps.override {
    src = "${src}/editors/code";
    outputs = [ "vsix" "out" ];

    inherit releaseTag;

    nativeBuildInputs = [
      jq moreutils esbuild
      # Required by `keytar`, which is a dependency of `vsce`.
      pkg-config libsecret
    ];

    # Follows https://github.com/rust-analyzer/rust-analyzer/blob/41949748a6123fd6061eb984a47f4fe780525e63/xtask/src/dist.rs#L39-L65
    postInstall = ''
      jq '
        .version = $ENV.version |
        .releaseTag = $ENV.releaseTag |
        .enableProposedApi = false |
        walk(del(.["$generated-start"]?) | del(.["$generated-end"]?))
      ' package.json | sponge package.json

      mkdir -p $vsix
      # vsce ask for continue due to missing LICENSE.md
      # Should be removed after https://github.com/rust-analyzer/rust-analyzer/commit/acd5c1f19bf7246107aaae7b6fe3f676a516c6d2
      echo y | npx vsce package -o $vsix/${pname}.zip
    '';
  };

in
vscode-utils.buildVscodeExtension {
  inherit version vsix;
  name = "${pname}-${version}";
  src = "${vsix}/${pname}.zip";
  vscodeExtUniqueId = "${publisher}.${pname}";

  nativeBuildInputs = lib.optionals setDefaultServerPath [ jq moreutils ];

  preInstall = lib.optionalString setDefaultServerPath ''
    jq '.contributes.configuration.properties."rust-analyzer.server.path".default = $s' \
      --arg s "${rust-analyzer}/bin/rust-analyzer" \
      package.json | sponge package.json
  '';

  meta = with lib; {
    description = "An alternative rust language server to the RLS";
    homepage = "https://github.com/rust-analyzer/rust-analyzer";
    license = with licenses; [ mit asl20 ];
    maintainers = with maintainers; [ ];
    platforms = platforms.all;
  };
}
