#!/bin/bash

set -x
set -e

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
FPCRPMVersion=`echo $FPCRPM | sed -e 's/fpc-//g'`
echo "installed fpc version: $FPCRPMVersion"

Date=$Year$Month$Day
LazVersion=$(./get_lazarus_version.sh)
if [ -z "$LazRelease" ]; then
  LazRelease='0' # $(echo $FPCRPM | sed -e 's/-/_/g')
fi
Src=lazarus-$LazVersion-$LazRelease.tar.gz
SrcTGZ=$(./rpm/get_rpm_source_dir.sh)/SOURCES/$Src
TmpDir=/tmp/lazarus$LazVersion
SpecFile=rpm/lazarus-$LazVersion-$LazRelease.spec

# download lazarus svn if necessary
echo "creating lazarus tgz ..."
#if [ ! -f $SrcTGZ ]; then
  sh create_lazarus_export_tgz.sh $SrcTGZ
#fi

# create spec file
echo "creating lazarus spec file ..."
cat rpm/lazarus.spec.template | \
  sed -e "s/LAZVERSION/$LazVersion/g" \
      -e "s/LAZRELEASE/$LazRelease/g" \
      -e "s/LAZSOURCE/$Src/g" \
      -e "s/FPCBUILDVERSION/2.0.0/g" \
      -e "s/FPCVERSION/$FPCRPMVersion/g" \
  > $SpecFile

# build rpm
echo "building rpm ..."
rpm -ba $SpecFile || rpmbuild -ba $SpecFile

echo "The new rpm can be found at $(./rpm/get_rpm_source_dir.sh)/RPMS/i386/lazarus-$LazVersion-$LazRelease.i386.rpm"

# end.

