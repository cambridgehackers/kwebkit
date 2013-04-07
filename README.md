kwebkit
=======

Script to build the dependencies and webkit-nix for Klaatu

Currently runs asis on a Ubuntu 12.04 server install. see README.pkgs for the needed pkgs.
Hacks:
#2) pkgconfig.pkg in /usr/share/aclocal copied to klaatu sysroot
#5) /system/bin/linker is the Klaatu linker (see above)



Steps:
1) build AOSP (you need all the libs)
The following MUST be done from the shell you lunched in.
2) run klaatu-manifests/script/makeusr (you need a linux friendly sysroot to build against)
These just need the ANDROID_BUID_TOP Environment variable set.
3) run dloadPkgs.sh  (grabs the packages webkit nix relies on as well as nix itself)
4) run buildBasePkgs.sh (builds them in the "right" order)



