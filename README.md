kwebkit
=======

Script to build the dependencies and webkit-nix for Klaatu

Currently runs asis only on a HACKED Ubuntu 10.04 KLAATU build machine.
HACKS:
#1) libtool >= 2.4.2 (sysroot friendlier)
#2) pkgconfig.pkg in /usr/share/aclocal copied to klaatu sysroot
#3) cmake >= 2.8.7 (webkit-nix needs a newish cmake)
#4) qemu-arm-static >= 1.2.0  (we need to run some of the things we build)
#5) /system/bin/linker is the Klaatu linker (see above)
Getting it to work on a 12.04 is a (not hard) TODO...


Steps:
1) build AOSP (you need all the libs)
The following MUST be done from the shell you lunched in.
2) run klaatu-manifests/script/makeusr (you need a linux friendly sysroot to build against)
3) run dloadPkgs.sh  (grabs the packages webkit nix relies on as well as nix itself)
4) run buildBasePkgs.sh (builds them in the "right" order)



