#!/bin/sh
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
echo "Testing specific HDF5 version against known CVE issues"
echo "======================================================"

#
# This is currently cve_hdf5
srcdir=`pwd`

TESTNAME=h5dump
EXIT_SUCCESS=0
EXIT_FAILURE=1
nerrors=0

#
# User provided tool installed location
bindir=$1

#
# Tool executables
DUMPER=$bindir/h5dump

#
# Location of CVE files
# using ../ to run tests in test directory
CVE_TESTFILES_DIR=../testfiles

LIST_CVEHDF5_TEST_FILES="
$CVE_TESTFILES_DIR/cve-2017-17505.h5
$CVE_TESTFILES_DIR/cve-2017-17506.h5
$CVE_TESTFILES_DIR/cve-2017-17507.h5
$CVE_TESTFILES_DIR/cve-2017-17508.h5
$CVE_TESTFILES_DIR/cve-2017-17509.h5
$CVE_TESTFILES_DIR/cve-2018-11202.h5
$CVE_TESTFILES_DIR/cve-2018-11203.h5
$CVE_TESTFILES_DIR/cve-2018-11204.h5
$CVE_TESTFILES_DIR/cve-2018-11205.h5
$CVE_TESTFILES_DIR/cve-2018-11206-new.h5
$CVE_TESTFILES_DIR/cve-2018-11206-old.h5
$CVE_TESTFILES_DIR/cve-2018-13873.h5
$CVE_TESTFILES_DIR/cve-2018-15672.h5
$CVE_TESTFILES_DIR/cve-2018-17233.h5
$CVE_TESTFILES_DIR/cve-2018-17234.h5
$CVE_TESTFILES_DIR/cve-2018-17433.h5
$CVE_TESTFILES_DIR/cve-2018-17434.h5
$CVE_TESTFILES_DIR/cve-2018-17435.h5
$CVE_TESTFILES_DIR/cve-2018-17436.h5
$CVE_TESTFILES_DIR/cve-2018-17437.h5
$CVE_TESTFILES_DIR/cve-2018-17438.h5
$CVE_TESTFILES_DIR/cve-2018-17439.h5
$CVE_TESTFILES_DIR/cve-2019-8396.h5
$CVE_TESTFILES_DIR/cve-2019-8397.h5
$CVE_TESTFILES_DIR/cve-2019-8398.h5
$CVE_TESTFILES_DIR/cve-2019-9151.h5
$CVE_TESTFILES_DIR/cve-2019-9152.h5
$CVE_TESTFILES_DIR/cve-2020-10809.h5
$CVE_TESTFILES_DIR/cve_2020_10810.h5
$CVE_TESTFILES_DIR/cve-2020-10810.h5
$CVE_TESTFILES_DIR/cve-2020-10811.h5
$CVE_TESTFILES_DIR/cve_2020_10812.h5
$CVE_TESTFILES_DIR/cve-2020-10812.h5
$CVE_TESTFILES_DIR/cve-2021-45829.h5
$CVE_TESTFILES_DIR/cve-2021-45830.h5
$CVE_TESTFILES_DIR/cve-2021-45833.h5
$CVE_TESTFILES_DIR/cve-2021-46242.h5
$CVE_TESTFILES_DIR/cve-2021-46243.h5
$CVE_TESTFILES_DIR/cve-2021-46244.h5
"

#
# Files cannot be run due to infinite loop.  It should be checked separately
# until infinite loop is removed.
LIST_LEFT_OUT="
$CVE_TESTFILES_DIR/cve-2018-15671.h5
"

#
# Print a line for the CVE file being tested on
TESTING() {
   echo "Dumping file $1 "
}

#
# Run user-provided h5dump on a given CVE file and report PASSED or FAILED
TESTDUMP_CVEFILE() {

    infile=$1
    outputdir=$2

    #
    # store actual output in a file for inspection and reducing clutter on screen
    actual="$outputdir/`basename $1 .exp`.out"
    echo ""

    # run test
    TESTING $infile
    (
        echo ""
        $DUMPER $infile
    ) >&$actual
    RET=$?

    # FAILED when crashes occurred, PASSED means normal failure
    if [ $RET == 139 ] ; then
        nerrors="`expr $nerrors + 1`"
        echo "*FAILED - Segmentation fault (core dumped)"
    elif [ $RET == 136 ] ; then
        nerrors="`expr $nerrors + 1`"
        echo "*FAILED - Floating point exception(core dumped)"
    elif [ $RET == 134 ] ; then
        nerrors="`expr $nerrors + 1`"
        echo "*FAILED - Aborted (core dumped)"
    else
        echo " PASSED"
    fi

}

#
# Create test output directory, change to it, then run the test using
# TESTDUMP_CVEFILE, passing in the CVE file, and the test output directory

# Directory to run tests in
testdir=$2
mkdir -p -m=755 $testdir
cd $testdir

# Directory to store actual output of each file
output_testdir=dumper_out
mkdir -p -m=755 $output_testdir

# run h5dump on each CVE file
for testfile in $LIST_CVEHDF5_TEST_FILES
do
    TESTDUMP_CVEFILE $testfile $output_testdir
done

#
# cleanup actual output
echo ""
echo "*** Do not cleanup the output files, they should be inspected ***"
echo ""

#
# Report test results and exit
if test $nerrors -eq 0 ; then
    echo "All $TESTNAME tests passed."
    exit $EXIT_SUCCESS
else
    echo "$TESTNAME tests failed with $nerrors errors."
    exit $EXIT_FAILURE
fi

echo "DONE!"
