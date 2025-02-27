{ lib
, stdenv
, fetchFromGitHub
, autoconf
, automake
, bc
, fluxbox
, gettext
, glibmm
, gtkmm2
, libglademm
, libsigcxx
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "fme";
  version = "1.1.3";

  src = fetchFromGitHub {
    owner = "rdehouss";
    repo = "fme";
    rev = "v${version}";
    sha256 = "sha256-P67OmExBdWM6NZhDyYceVJOZiy8RC+njk/QvgQcWZeQ=";
  };

  nativeBuildInputs = [
    autoconf
    automake
    gettext
    pkg-config
  ];
  buildInputs = [
    bc
    fluxbox
    glibmm
    gtkmm2
    libglademm
    libsigcxx
  ];

  preConfigure = ''
    ./autogen.sh
  '';

  meta = with lib; {
    homepage = "https://github.com/rdehouss/fme/";
    description = "Editor for Fluxbox menus";
    longDescription = ''
      Fluxbox Menu Editor is a menu editor for the Window Manager Fluxbox
      written in C++ with the libraries Gtkmm, Glibmm, libglademm and gettext
      for internationalization.  Its user-friendly interface will help you to
      edit, delete, move (Drag and Drop) a row, a submenu, etc very easily.
    '';
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.AndersonTorres ];
    platforms = platforms.linux;
  };
}
