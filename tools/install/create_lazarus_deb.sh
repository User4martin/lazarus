#!/usr/bin/env bash
#
# Author: Mattias Gaertner
#
# Usage: ./create_lazarus_deb.sh [gtk1] [append-revision] [chmhelp]
#
#   Options:
#     gtk1              compile IDE and programs for gtk1 too. gtk2 ppu are still built.
#     append-revision   append the svn revision to the .deb version
#     chmhelp           add package chmhelp and add chm,kwd,xct,txt files in docs/chm

set -e

LCLWidgetset=
LazVersionPostfix=
UseCHMHelp=

while [ $# -gt 0 ]; do
  echo "param=$1"
  case "$1" in
  gtk1)
    echo "Compile for gtk1 too"
    LCLWidgetset=gtk
    ;;

  append-revision)
    LazVersionPostfix=$(./get_svn_revision_number.sh .)
    if [ -n "$LazVersionPostfix" ]; then
      LazVersionPostfix=.$LazVersionPostfix
    fi
    echo "Appending svn revision $LazVersionPostfix to deb name"
    ;;

  chmhelp)
    echo "using package chmhelp"
    UseCHMHelp=1
    ;;

  *)
    echo "invalid parameter $1"
    echo "Usage: ./create_lazarus_deb.sh [gtk1] [release=svn] [chmhelp]"
    exit 1
    ;;
  esac
  shift
done

# get FPC version
FPCVersion=$(fpc -v | grep 'Compiler version' | sed 's/.*\([0-9]\.[0-9]\.[0-9]\).*/\1/')
echo "FPCVersion=$FPCVersion"

Arch=`dpkg --print-architecture`
echo "debian architecture=$Arch"
if [  "$Arch" = i386 ]; then 
  ppcbin=ppc386 
else 
  if [ "$Arch" = amd64 ]; then 
    ppcbin=ppcx64 
  else   
    if [  "$Arch" = powerpc ]; then 
      ppcbin=ppcppc 
    else 
      if [  "$Arch" = sparc ]; then 
        ppcbin=ppcsparc 
      else 
        echo "$Arch is not supported." 
        exit -1 
      fi 
    fi 
  fi 
fi

Date=`date +%Y%m%d`
LazVersion=$(./get_lazarus_version.sh)$LazVersionPostfix
LazRelease='0'
SrcTGZ=lazarus-$LazVersion-$LazRelease.tar.gz
CurDir=`pwd`
TmpDir=~/tmp/lazarus$LazVersion
LazBuildDir=$TmpDir/lazarus_build
LazDeb=$CurDir/lazarus_${LazVersion}-${LazRelease}_$Arch.deb
DebianSrcDir=$CurDir/debian_lazarus
EtcSrcDir=$CurDir/linux
LazSrcDir=../..
LazDestDir=$LazBuildDir/usr/share/lazarus/${LazVersion}
LazDestDirInstalled=/usr/share/lazarus/${LazVersion}
 
FPCVersion=$($ppcbin -v | grep version| sed 's/.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/')
ChangeLogDate=`date --rfc-822`

echo "ppcbin=$ppcbin"
echo "LazVersion=$LazVersion"
echo "FPCVersion=$FPCVersion"
echo "ChangeLogDate=$ChangeLogDate"

# download/export lazarus svn if needed
if [ ! -f $SrcTGZ ]; then
  ./create_lazarus_export_tgz.sh $SrcTGZ
fi

echo "Build directory is $LazBuildDir"
if [ x$LazBuildDir = x/ ]; then
  echo "ERROR: invalid build directory"
  exit
fi
rm -rf $LazBuildDir

# Unpack lazarus source
echo "unpacking $SrcTGZ ..."
ls -l $SrcTGZ
mkdir -p $LazDestDir
cd $LazDestDir
tar xzf $CurDir/$SrcTGZ --strip 1
cd -
if [ "$UseCHMHelp" = "1" ]; then
  echo
  echo "Copying chm files"
  cd $LazSrcDir/docs/chm
  cp -v *.txt *.kwd *.chm *.xct $LazDestDir/docs/chm/
  cd -
fi

# compile
echo
echo "Compiling may take a while ... =========================================="
cd $LazDestDir
MAKEOPTS="-Fl/opt/gnome/lib"
if [ -n "$FPCCfg" ]; then
  MAKEOPTS="$MAKEOPTS -n @$FPCCfg"
fi
if [ "$UseCHMHelp" = "1" ]; then
  MAKEOPTS="$MAKEOPTS -dUseCHMHelp"
fi
echo "MAKEOPTS=$MAKEOPTS"
# build
export LCL_PLATFORM=$LCLWidgetset
make bigide PP=$ppcbin OPT="$MAKEOPTS"

export LCL_PLATFORM=

strip lazarus
strip startlazarus
strip lazbuild
strip tools/lazres
strip tools/updatepofiles
strip tools/lrstolfm
strip tools/svn2revisioninc
cd -

# create control file
echo "========================================================================="
echo "copying control file"
mkdir -p $LazBuildDir/DEBIAN
cat $DebianSrcDir/control$LCLWidgetset | \
  sed -e "s/FPCVERSION/$FPCVersion/g" \
      -e "s/LAZVERSION/$LazVersion/g" \
      -e "s/ARCH/$Arch/g" \
  > $LazBuildDir/DEBIAN/control

# copyright and changelog files
echo "copying copyright and changelog files"
mkdir -p $LazBuildDir/usr/share/doc/lazarus
cp $DebianSrcDir/{copyright,changelog,changelog.Debian} $LazBuildDir/usr/share/doc/lazarus/
gzip --best $LazBuildDir/usr/share/doc/lazarus/changelog
gzip --best $LazBuildDir/usr/share/doc/lazarus/changelog.Debian

# icons, links
mkdir -p $LazBuildDir/usr/share/pixmaps
mkdir -p $LazBuildDir/usr/share/applications
mkdir -p $LazBuildDir/usr/share/mime/packages
mkdir -p $LazBuildDir/usr/bin/
install -m 644 $LazDestDir/images/icons/lazarus128x128.png $LazBuildDir/usr/share/pixmaps/lazarus.png
install -m 644 $LazDestDir/install/lazarus.desktop $LazBuildDir/usr/share/applications/lazarus.desktop
install -m 644 $LazDestDir/install/lazarus-mime.xml $LazBuildDir/usr/share/mime/packages/lazarus.xml
ln -s $LazDestDirInstalled/lazarus $LazBuildDir/usr/bin/lazarus-ide
ln -s $LazDestDirInstalled/startlazarus $LazBuildDir/usr/bin/startlazarus
ln -s $LazDestDirInstalled/lazbuild $LazBuildDir/usr/bin/lazbuild

# docs
mkdir -p $LazBuildDir/usr/share/man/man1
for exe in lazbuild lazarus-ide startlazarus lazres svn2revisioninc updatepofiles; do
cat $LazDestDir/install/man/man1/$exe.1 | gzip > $LazBuildDir/usr/share/man/man1/$exe.1.gz
done

# default configs
mkdir -p $LazBuildDir/etc/lazarus
cp $EtcSrcDir/editoroptions.xml $LazBuildDir/etc/lazarus/
cat $EtcSrcDir/environmentoptions.xml | \
  sed -e "s#__LAZARUSDIR__#$LazDestDirInstalled/#" \
      -e "s#__FPCSRCDIR__#/usr/share/fpcsrc/\$(FPCVER)/#" \
  > $LazBuildDir/etc/lazarus/environmentoptions.xml
chmod 644 $LazBuildDir/etc/lazarus/*.xml

# fixing permissions
echo "fixing permissions ..."
find $LazBuildDir -type d | xargs -d '\n' chmod 755  # this is needed, don't ask me why

# postinst + postrm:
# ToDo: update-mime-database /usr/share/mime
# ToDo: update-desktop-database

# creating deb
echo "creating deb ..."
cd $TmpDir
fakeroot dpkg-deb --build $LazBuildDir
mv $LazBuildDir.deb $LazDeb
echo "the new deb can be found at $LazDeb"
cd -

# removing temporary files
rm -r $TmpDir

# end.

