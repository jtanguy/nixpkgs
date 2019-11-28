{ stdenv, fetchzip, recurseIntoAttrs }:

let
  allFonts = import ./fonts.nix;
  mkFont = {name, url, sha256}: {
    name = name;
    value = fetchzip {
      name = "nerdfonts-${name}-${allFonts.version}";

      url = url;

      postFetch = ''
        mkdir -p $out/share/fonts
        unzip -l $downloadedFile
        unzip -j $downloadedFile "*.otf" -d $out/share/fonts/opentype || true
        unzip -j $downloadedFile "*.ttf" -d $out/share/fonts/truetype || true
      '';

      sha256 = sha256;

      meta = with stdenv.lib; {
        description = ''
          A Nerd Font-patched version of ${name}
        '';
        homepage = https://github.com/ryanoasis/nerd-fonts;
        license = licenses.mit;
        maintainers = with maintainers; [ ];
      };
    };
  };
 
in
  builtins.listToAttrs (builtins.map mkFont allFonts.fonts)
