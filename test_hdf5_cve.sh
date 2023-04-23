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

echo "Testing HDF5 against known CVE issues"
echo ""

#
# this is currently cve_hdf5
srcdir=`pwd`

LIST_OF_BRANCHES="
10
12
14
15
"

TESTNAME=h5dump
EXIT_SUCCESS=0
EXIT_FAILURE=1
nerrors=0

#
# currently used the versions built here
bindir=/scr/bmribler

#
# temporary executables (what I happen to have around)
DUMPER1_15=$bindir/build_dev_branch/built/bin/h5dump
DUMPER1_14=$bindir/build_hdf5-1_14_0/built/bin/h5dump
DUMPER1_12=$bindir/build_hdf5-1_12_0/built/bin/h5dump
DUMPER1_10=$bindir/build_hdf5-1_10_9/built-debug/bin/h5dump

#
# location of CVE files
# using ../ to run tests in multiple branch directories
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
# files cannot be run due to infinite loop
LIST_LEFT_OUT="
$CVE_TESTFILES_DIR/cve-2018-15671.h5
"

#
# print a line for the CVE file being tested on
TESTING() {
   echo "Dumping file $1 "
}

#
# run h5dump of a branch on a given CVE file and report PASSED or FAILED
TESTDUMP_CVEFILE() {

    DUMPER=$1
    infile=$2
    outputdir=$3

    #
    # store actual output in a file for inspection and reducing clutter on screen
    actual="$outputdir/`basename $2 .exp`.out"
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
# for each branch, create test and test output directories, then run the
# test using TESTDUMP_CVEFILE, passing in h5dump of that branch, the CVE
# file, and the test output directory
for branch in $LIST_OF_BRANCHES
do
    echo ""
    echo "==================================================================="
    echo "                      Testing in 1.$branch"
    echo "==================================================================="

    # create top directory for each branch
    testdir=test1_$branch
    mkdir -p -m=755 $testdir
    cd $testdir

    if [ $branch == 10 ] ; then
        DUMPER=$DUMPER1_10
    elif [ $branch == 12 ] ; then
        DUMPER=$DUMPER1_12
    elif [ $branch == 14 ] ; then
        DUMPER=$DUMPER1_14
    elif [ $branch == 15 ] ; then
        DUMPER=$DUMPER1_15
    else
        echo "only branches 1.10, 1.12, and 1.14 available"
    fi

    # create directory to store actual output in each branch
    output_testdir=dumper_out
    mkdir -p -m=755 $output_testdir

    # run h5dump on each CVE file
    for testfile in $LIST_CVEHDF5_TEST_FILES
    do
        TESTDUMP_CVEFILE $DUMPER $testfile $output_testdir
    done
    cd ..
done

#
# cleanup actual output
echo ""
echo "*** not cleanup the output files at this time, they should be inspected ***"
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
