#!/usr/bin/env bash
# basic script to do a lcl.chm build.   Marco van de Voort dec 2011

# assumes a fpcdocs checkout where "fixdocs.sh" has been succesfully run.
# on 1.7GHz Core2 laptop single thread 6:26 minutes. Don't be impatient :-)

set -e

# set to path to FPC docs dir. Default assume it is on the same level as the lazarus checkout
FPCDIR=../../../fpcdocs
FPCDIREXP=`cd $FPCDIR ; pwd`

if [ -d "$FPCDIREXP" ]
then
echo FPCDOCS dir is $FPCDIREXP
else
echo FPCDOCS dir $FPCDIR expanded to $FPCDIREXP and was not found.
exit 1
fi

export HTMLFMT=chm
bash build_lazutils_html.sh fpdoc `pwd`/locallclfooter.xml $FPCDIREXP 1>lazutilsoutput.log 2>lazutilserror.log
bash build_lcl_html.sh fpdoc `pwd`/locallclfooter.xml $FPCDIREXP 1>lcloutput.log 2>lclerror.log
