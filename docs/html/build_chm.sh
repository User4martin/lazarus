#!/bin/bash

# Builds Lazarus documentation for LCL and LazUtils in CHM format.
# Requires a $(LazarusDir)/docs/chm directory which contains rtl.xct and fcl.xct.
# Process fails if either the directory or the files are missing.
# Process creates ./lcl and ./lazutils subdirectories for CHM output.
# Update the content in locallclfooter.xml if needed before starting the script.

# Path to the fpdoc program
# The trunk (main) version of fpdoc is recommended.
# CHANGE THIS TO A PATH VALID FOR YOUR SYSTEM AND FPDOC VERSION.
fpdocpath="../../fpc/3.2.2/bin/x86_64-win64"
# fpdoc in version 3.3.1-13340-g757f65d0e2 [2023/07/18] has output issues.
#fpdocpath="../../../fpc331/fpc/bin/x86_64-win64"

# rebuild if needed
#../../lazbuild build_lcl_docs.lpi

# build chm output without footers
#./build_lcl_docs --outfmt=chm --fpcdocs=../chm --fpdoc=$fpdocpath/fpdoc

# build chm output with date in footer
#./build_lcl_docs --outfmt=chm --fpcdocs=../chm --fpdoc=$fpdocpath/fpdoc --arg="--footer-date"

# For FPDoc 3.2.X: build chm output with footers in locallclfooter.xml
./build_lcl_docs --outfmt=chm --fpcdocs=../chm --fpdoc=$fpdocpath/fpdoc --footer=locallclfooter.xml 2>&1 | tee -a ./build_chm.log

# For FPDoc 3.3.X: build chm output with footers in locallclfooter.xml
#./build_lcl_docs --outfmt=chm --fpcdocs=../chm --fpdoc=$fpdocpath/fpdoc --footer=@locallclfooter.xml 2>&1 | tee -a ./build_chm.log

# For FPDoc 3.3.X: build chm output with footer text
#./build_lcl_docs --outfmt=chm --fpcdocs=../chm --fpdoc=$fpdocpath/fpdoc --footer="(c) Copyright 2022. All rights reserved."
