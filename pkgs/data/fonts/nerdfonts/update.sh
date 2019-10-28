#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq -p curl -p nix-prefetch-git

SCRIPT_DIR=$(dirname "$(readlink -f "$BASH_SOURCE")")

release_json=$(curl https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest)
release_assets=$(echo "$release_json" | jq -r '.assets[] | "\(.name | rtrimstr(".zip")) \(.browser_download_url)"')
version=$(echo "$release_json" | jq -r '.tag_name')


cat <<HEADER > fonts.nix
# Generated with ./update.sh
{
  version = "${version}";
  fonts = [
HEADER

echo "$release_assets" | while IFS=" " read -r name url; do

cat <<ASSET >>fonts.nix
    {
       name = "${name}";
       url = "${url}";
       sha256 = "$(nix-prefetch-url --unpack --name "nerdfonts-${name}-${version}" "$url")";
     }
ASSET
done


cat <<FOOTER >> fonts.nix
    ];
}
FOOTER
