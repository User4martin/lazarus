#!/bin/bash
#
# Author: Mattias Gaertner
#
# Usage: ./create_lazarus_rpm.sh [chmhelp]
#
#   Options:
#     chmhelp           add package chmhelp and add chm,kwd files in docs/chm
#
# Note: To create an rpm as normal user, see the script rpm/create_nonroot_rpmmacros.sh 

set -e

UseCHMHelp=

while [ $# -gt 0 ]; do
  echo "param=$1"
  case "$1" in
  chmhelp)
    echo "using package chmhelp"
    UseCHMHelp=1
    ;;

  *)
    echo "invalid parameter $1"
    echo "Usage: ./create_lazarus_rpm.sh [chmhelp]"
    exit 1
    ;;
  esac
  shift
done


set -x

# get date of day
Year=$(date +%y)
Month=$(date +%m)
Day=$(date +%d)

# get installed fpc version
echo "getting installed fpc version ..."
FPCRPM=$(rpm -qa | egrep '^fpc-[0-9]')
if [ "x$FPCRPM" = "x" ]; then
  echo ERROR: fpc rpm not installed
  exit
fi
# remove from the fpc version the architecture i386, i686, x86_64
FPCRPMVersion=$(echo $FPCRPM | sed -e 's/fpc-//g' -e 's/\.[a-z0-9_]\+$//g')
echo "installed fpc version: $FPCRPMVersion"
FPCSRCRPMVersion=$(echo $FPCRPMVersion | cut -d- -f1)

Date=$Year$Month$Day
LazVersion=$(./get_lazarus_version.sh | sed -e 's/-/_/g')
LazRelease='0' # $(echo $FPCRPM | sed -e 's/-/_/g')
RPMSrcDir=$(./rpm/get_rpm_source_dir.sh)
Src=lazarus-$LazVersion-$LazRelease.tar.gz
SrcTGZ=$RPMSrcDir/SOURCES/$Src
SrcTGZOpts=
SpecFile=rpm/lazarus-$LazVersion-$LazRelease.spec

Arch=$(rpm --eval "%{_arch}")

# download lazarus svn if needed
echo "creating lazarus tgz ..."
#if [ ! -f $SrcTGZ ]; then
  if [ "$UseCHMHelp" = "1" ]; then SrcTGZOpts="chmhelp"; fi
  sh create_lazarus_export_tgz.sh $SrcTGZOpts $SrcTGZ
#fi

# create spec file
echo "creating lazarus spec file ..."
CHMCOMMENT="# "
cat rpm/lazarus.spec.template | \
  sed -e "s/LAZVERSION/$LazVersion/g" \
      -e "s/LAZRELEASE/$LazRelease/g" \
      -e "s/LAZSOURCE/$Src/g" \
      -e "s/FPCBUILDVERSION/2.6.1/g" \
      -e "s/FPCVERSION/$FPCRPMVersion/g" \
      -e "s/FPCSRCVERSION/$FPCSRCRPMVersion/g" \
  > $SpecFile

# build rpm
echo "building rpm ..."
rpm -ba $SpecFile || rpmbuild -ba $SpecFile

echo "The new rpm can be found at $RPMSrcDir/RPMS/$Arch/lazarus-$LazVersion-$LazRelease.$Arch.rpm"

# end.

