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

# I'm using cve_hdf5 currently
#
srcdir=`pwd`
testdir=$srcdir/testfiles
bindir=/scr/bmribler

TESTNAME=h5dump
EXIT_SUCCESS=0
EXIT_FAILURE=1
nerrors=0

# temporary executables (what I happen to have around),
# need to know how we do with the different branches
#
DUMPER1_14=/mnt/hdf/bmribler/H5lib/jelly-1140/bin/h5dump
DUMPER1_12=/scr/bmribler/build_hdf5-1_12_0/built/bin/h5dump
DUMPER1_10=/scr/bmribler/build_hdf5-1_10_9/built-debug/bin/h5dump

SRC_CVE_TESTFILES=$srcdir/testfiles

LIST_CVEHDF5_TEST_FILES="
$SRC_CVE_TESTFILES/cve-2017-17505.h5
$SRC_CVE_TESTFILES/cve-2017-17506.h5
$SRC_CVE_TESTFILES/cve-2017-17507.h5
$SRC_CVE_TESTFILES/cve-2017-17508.h5
$SRC_CVE_TESTFILES/cve-2017-17509.h5
$SRC_CVE_TESTFILES/cve-2018-11202.h5
$SRC_CVE_TESTFILES/cve-2018-11203.h5
$SRC_CVE_TESTFILES/cve-2018-11204.h5
$SRC_CVE_TESTFILES/cve-2018-11205.h5
$SRC_CVE_TESTFILES/cve-2018-11206-new.h5
$SRC_CVE_TESTFILES/cve-2018-11206-old.h5
$SRC_CVE_TESTFILES/cve-2018-13873.h5
$SRC_CVE_TESTFILES/cve-2018-15671.h5
$SRC_CVE_TESTFILES/cve-2018-15672.h5
$SRC_CVE_TESTFILES/cve-2018-17233.h5
$SRC_CVE_TESTFILES/cve-2018-17234.h5
$SRC_CVE_TESTFILES/cve-2018-17433.h5
$SRC_CVE_TESTFILES/cve-2018-17434.h5
$SRC_CVE_TESTFILES/cve-2018-17435.h5
$SRC_CVE_TESTFILES/cve-2018-17436.h5
$SRC_CVE_TESTFILES/cve-2018-17437.h5
$SRC_CVE_TESTFILES/cve-2018-17438.h5
$SRC_CVE_TESTFILES/cve-2018-17439.h5
$SRC_CVE_TESTFILES/cve-2019-8396.h5
$SRC_CVE_TESTFILES/cve-2019-8397.h5
$SRC_CVE_TESTFILES/cve-2019-8398.h5
$SRC_CVE_TESTFILES/cve-2019-9151.h5
$SRC_CVE_TESTFILES/cve-2019-9152.h5
$SRC_CVE_TESTFILES/cve-2020-10809.h5
$SRC_CVE_TESTFILES/cve_2020_10810.h5
$SRC_CVE_TESTFILES/cve-2020-10810.h5
$SRC_CVE_TESTFILES/cve-2020-10811.h5
$SRC_CVE_TESTFILES/cve_2020_10812.h5
$SRC_CVE_TESTFILES/cve-2020-10812.h5
$SRC_CVE_TESTFILES/cve-2021-45829.h5
$SRC_CVE_TESTFILES/cve-2021-45830.h5
$SRC_CVE_TESTFILES/cve-2021-45833.h5
$SRC_CVE_TESTFILES/cve-2021-46242.h5
$SRC_CVE_TESTFILES/cve-2021-46243.h5
$SRC_CVE_TESTFILES/cve-2021-46244.h5
"

# Print a line beginning with the word "Testing".
#
TESTING() {
   echo "Testing $* "
}

DUMPER_ACTUAL=$testdir/dumper_out

# run h5dump on a CVE file and check for various types of crashes
#
DUMP_CVEFILE() {

    infile=$1
    actual="$DUMPER_ACTUAL/`basename $1 .exp`.out"
    echo ""

    # Run test
    TESTING $TESTNAME $infile
    (
        $DUMPER1_10 "$@" $infile
    ) >&$actual
    RET=$?
    # Segfault occurred
    if [ $RET == 139 ] ; then
        nerrors="`expr $nerrors + 1`"
        echo "*FAILED - test on $infile produced Segmentation fault (core dumped)"
    # Floating point exception
    elif [ $RET == 136 ] ; then
        nerrors="`expr $nerrors + 1`"
        echo "*FAILED - test on $infile produced Floating point exception(core dumped)"
    # Aborted
    elif [ $RET == 134 ] ; then
        nerrors="`expr $nerrors + 1`"
        echo "*FAILED - test on $infile got Aborted (core dumped)"
    else
        echo " PASSED"
    fi
}

# create directory to store actual output
#
mkdir -p -m=777 $DUMPER_ACTUAL

# run h5dump on each CVE file
#
for testfile in $LIST_CVEHDF5_TEST_FILES
do
    DUMP_CVEFILE $testfile
done

# cleanup actual output
#
echo "*** not cleanup the output files at this time, they should be inspected ***"

# Report test results and exit
#
if test $nerrors -eq 0 ; then
    echo "All $TESTNAME tests passed."
    exit $EXIT_SUCCESS
else
    echo "$TESTNAME tests failed with $nerrors errors."
    exit $EXIT_FAILURE
fi

echo "DONE!"
