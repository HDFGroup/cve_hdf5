#!/bin/bash
#
# Copyright by The HDF Group.
# All rights reserved.
#
# The full copyright notice, including terms governing use,
# modification, and redistribution, is contained in the COPYING
# file, which can be found at the root of the source code
# distribution tree, or in https://www.hdfgroup.org/licenses.
# If you do not have access to either file, you may request a copy from
# help@hdfgroup.org.
#
# A script for testing HDF5 against all the CVE issues that have
# been filed against it.

echo ""
echo "Testing HDF5 against known CVE issues"
echo "====================================="

EXIT_SUCCESS=0
EXIT_FAILURE=1
nerrors=0

# Location of HDF5 command-line tools
bindir=$1

# Output directory
outdir=$2
test -d "$outdir" || mkdir -p "$outdir"

# Tool executables
H5DUMP=$bindir/h5dump

# Location of CVE files
CVE_H5_FILES_DIR=cvefiles

CVE_TEST_FILES="
cve-2017-17505.h5
cve-2017-17506.h5
cve-2017-17507.h5
cve-2017-17508.h5
cve-2017-17509.h5
cve-2018-11202.h5
cve-2018-11203.h5
cve-2018-11204.h5
cve-2018-11205.h5
cve-2018-11206-new.h5
cve-2018-11206-old.h5
cve-2018-13873.h5
cve-2018-15672.h5
cve-2018-17233.h5
cve-2018-17234.h5
cve-2018-17433.h5
cve-2018-17434.h5
cve-2018-17435.h5
cve-2018-17436.h5
cve-2018-17437.h5
cve-2018-17438.h5
cve-2018-17439.h5
cve-2019-8396.h5
cve-2019-8397.h5
cve-2019-8398.h5
cve-2019-9151.h5
cve-2019-9152.h5
cve-2020-10809.h5
cve_2020_10810.h5
cve-2020-10810.h5
cve-2020-10811.h5
cve_2020_10812.h5
cve-2020-10812.h5
cve-2021-45829.h5
cve-2021-45830.h5
cve-2021-45833.h5
cve-2021-46242.h5
cve-2021-46243.h5
cve-2021-46244.h5
"

# Problematic files that cannot be tested. For example, they might generate an
# infinite loop.
#CVE_BAD_FILES="
#cve-2018-15671.h5
#"

# Run user-provided h5dump on a given CVE file and report PASSED or FAILED
TEST_CVEFILE() {

    infile=$1
    base=$(basename "$1" .exp)

    echo -ne "$base\t\t\t"

    # Store actual output in a file for inspection and reducing clutter on screen
    outfile="$base.out"

    # Run test, redirecting stderr and stdout to the output file
    #
    # NOTE: An abort will cause bash to emit a bunch of text that will NOT
    #       be sent to the file, but will unilaterally be dumped.
    $H5DUMP "$infile" > "$outdir/$outfile" 2>&1

    RET=$?

    # A test passes when it invokes normal HDF5 error handling.
    if [[ $RET == 139 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "*FAILED - Segmentation fault"
    elif [[ $RET == 136 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "*FAILED - Floating point exception"
    elif [[ $RET == 134 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "*FAILED - Aborted"
    elif [[ $RET == 0 || $RET == 1 ]] ; then
        echo " PASSED"
    else
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** - Unexpected error: $RET"
    fi
}

# Run h5dump on each CVE file
for testfile in $CVE_TEST_FILES
do
    TEST_CVEFILE "$CVE_H5_FILES_DIR/$testfile"
done

# Clean up actual output
echo ""
echo "*** Do not cleanup the output files, they should be inspected ***"
echo ""

# Report test results and exit
if test "$nerrors" -eq 0 ; then
    echo "All tests passed."
    exit $EXIT_SUCCESS
else
    echo "Tests failed with $nerrors errors."
    exit $EXIT_FAILURE
fi

echo "DONE!"
