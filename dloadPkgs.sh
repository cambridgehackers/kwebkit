#!/bin/sh

#set -x

KLAATU_TOPDIR=`pwd`
KLAATU_TMPDIR=`pwd`;
KLAATU_SUPPORTDIR=$KLAATU_TOPDIR/support_files

if [ "$1" != "" ]; then
    KLAATU_TMPDIR=`readlink -f $1`
fi


if [ ! -e $KLAATU_SUPPORTDIR/pkgList ]; then
    echo "where is the file pkgList? expected $KLAATU_SUPPORTDIR/pkgList!"
    exit -1;
fi

mkdir -p $KLAATU_TMPDIR/kwebkit_src_downloads
cd $KLAATU_TMPDIR/kwebkit_src_downloads
for i in `cat $KLAATU_SUPPORTDIR/pkgList`; do
    FNAME=${i##*/}
    
    GRABIT="N";
    if [ ! -e $FNAME ]; then
	GRABIT="Y"
    else
	echo "Verifying $FNAME"
	tar -tvf $FNAME 2>/dev/null 1>/dev/null
	if [ $? -ne 0 ]; then
	    echo "$FNAME is corrupt, regetting it."
	    rm $FNAME;
	    GRABIT="Y";
	fi
    fi
    if [ "$GRABIT" == "Y" ]; then
	echo "Working on $FNAME";
	wget -nv $i;
    fi
done

for i in `cat $KLAATU_SUPPORTDIR/pkgList`; do
    FNAME=${i##*/}
    if [ ! -e $FNAME ]; then
	echo "wget for $FNAME failed. :("
    fi
done
# since Nix is a repo, it get's handled specially
# if they were all repos, I'd use repo
echo "Working on webkitnix, this can take awhile..."
cd $KLAATU_TMPDIR/kwebkit_src_downloads
if [ -d webkitnix ]; then
    echo "pulling updates..."
    cd webkitnix
    git pull
else
    echo "cloning webkitnix..."
    git clone https://github.com/cambridgehackers/webkitnix.git
fi
if [ ! -f $KLAATU_SUPPORTDIR/WebKitNixBranch ]; then
    echo "you need to specify a branch for nix or i don't know which one to use!"
    exit -1
fi
if [ ! -d $KLAATU_TMPDIR/kwebkit_src_downloads/webkitnix ]; then
    echo "github clone failed :("
    exit -1
fi

WEBKITNIX_BRANCH=`cat $KLAATU_SUPPORTDIR/WebKitNixBranch | head -1`
FNAME=$KLAATU_TMPDIR/kwebkit_src_downloads/webkitnix-${WEBKITNIX_BRANCH}.tar
if [ ! -e $FNAME ]; then
    echo "archiving the git tree "
    cd $KLAATU_TMPDIR/kwebkit_src_downloads/webkitnix
    git checkout ${WEBKITNIX_BRANCH}
    git archive --format=tar --prefix=webkitnix-${WEBKITNIX_BRANCH}/ HEAD > $FNAME
else
    echo "webkitnix has already been git archived. To force a redo either remove "
    echo "$FNAME or "
    echo "update $KLAATU_SUPPORTDIR/WebKitNixBranch to a different branch"
fi



    
