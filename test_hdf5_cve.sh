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
echo ""
echo "Tests HDF5 CVE issues via the command-line tools. Most HDF5 CVE issues"
echo "are due to incorrect behavior when parsing corrupt files. This test"
echo "script opens the CVE demonstration files using the HDF command-line"
echo "tools to ensure that the library the tools are linked to behaves"
echo "correctly when parsing these files."
echo ""
echo "A PASSED test indicates that the tool exited normally (no segfaults,"
echo "etc.) and emitted a success/fail return value."
echo ""
echo "USAGE:"
echo ""
echo "      ./test_hdf5_cve.sh <path/to/tools> <output_dir>"
echo ""
echo "      path/to/tools is the path to where the command-line tools"
echo "      (e.g., h5dump) can be found. It can be relative or absolute."
echo ""
echo "      output_dir is where you would like to put the stderr/stdout"
echo "      output from each test."
echo ""
echo "The script returns 0 on success and 1 on failure so it can be used"
echo "in CI actions."
echo ""

EXIT_SUCCESS=0
EXIT_FAILURE=1
nerrors=0

# Check number of command-line arguments
len=$#
if [ $len -ne 2 ]; then
    echo "Incorrect number of arguments. Check usage, above."
    exit $EXIT_FAILURE
fi

# Location of HDF5 command-line tools
bindir=$1
if [ ! -f "$bindir/h5dump" ]; then
    echo "Can't find HDF5 tools. Make sure the 1st argument is a valid path."
    exit $EXIT_FAILURE
fi

# Output directory
outdir=$2
test -d "$outdir" || mkdir -p "$outdir"
if [ ! -d "$outdir" ]; then
    echo "Can't find output directory. Make sure the 2nd argument is a valid path."
    exit $EXIT_FAILURE
fi

# Tool executables
H5DUMP=$bindir/h5dump
H5CLEAR=$bindir/h5clear
H5DEBUG=$bindir/h5debug
GIF2H5=$bindir/gif2h5
H5FORMAT_CONVERT=$bindir/h5format_convert
H5LS=$bindir/h5ls
H52GIF=$bindir/h52gif
H5REPACK=$bindir/h5repack
H5STAT=$bindir/h5stat

# Location of CVE files
CVE_H5_FILES_DIR=cvefiles

# All of the CVE files are tested against the following tools:
#    h5dump, h5debug, h5ls, h5repack, and h5stat
# without any options.
#
# Then a number of the CVE files are then tested against the tools and
# options as specified in the CVE reports.  See the README file in the
# directory cvefiles/ for details.
CVE_TEST_FILES="
cve-2016-4330.h5
cve-2016-4331.h5
cve-2016-4332-mtime.h5
cve-2016-4332-mtime-new.h5
cve-2016-4332-stab.h5
cve-2016-4333.h5
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
cve-2018-11207.h5
cve-2018-13866.h5
cve-2018-13867.h5
cve-2018-13868.h5
cve-2018-13869.h5
cve-2018-13870.h5
cve-2018-13871.h5
cve-2018-13872.h5
cve-2018-13873.h5
cve-2018-13874.h5
cve-2018-13875.h5
cve-2018-13876.h5
cve-2018-14031.h5
cve-2018-14033.h5
cve-2018-14034.h5
cve-2018-14035.h5
cve-2018-14460.h5
cve-2018-15671.h5
cve-2018-15672.h5
cve-2018-16438.h5
cve-2018-17233.h5
cve-2018-17234.h5
cve-2018-17237.h5
cve-2018-17432.h5
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
cve-2020-10810.h5
cve-2020-10811.h5
cve-2020-10812.h5
cve-2021-36977.h5
cve-2021-37501.h5
cve-2021-45829.h5
cve-2021-45830.h5
cve-2021-45833.h5
cve-2021-46242.h5
cve-2021-46243.h5
cve-2021-46244.h5
cve-2023-1006-001.h5
cve-2023-1006-002.h5
cve-2023-1006-003.h5
cve-2023-1006-004.h5
cve-2023-1009-001.h5
cve-2023-1010-001.h5
cve-2023-1012-001.h5
cve-2023-1013-001.h5
cve-2023-1013-002.h5
cve-2023-1013-003.h5
cve-2023-1013-004.h5
cve-2023-1017-001.h5
cve-2023-1017-002.h5
cve-2023-1018-001.h5
cve-2023-1019-001.h5
cve-2023-1023-001.h5
cve-2023-1104-001.h5
cve-2023-1104-002.h5
cve-2023-1104-003.h5
cve-2023-1104-004.h5
cve-2023-1108-001.h5
cve-2023-1113-001.h5
cve-2023-1113-002.h5
cve-2023-1114-001.h5
cve-2023-1125-001.h5
cve-2023-1130-001.h5
cve-2023-1202-001.h5
cve-2023-1202-002.h5
cve-2023-1205-001.h5
cve-2023-1207-001.h5
cve-2023-1208-001.h5
cve-2023-1208-002.h5
cve-2024-0111-001.h5
cve-2024-0112-001.h5
cve-2024-0116-001.h5
"

GIF2H5_TEST_FILES="
cve-2018-17433
cve-2018-17436
cve-2018-17438
cve-2018-17439
cve-2020-10809
"

# Checks return value and display appropriate message
CHECK_RET() {

    ret=$1

    # A test passes when it invokes normal HDF5 error handling.
    if [[ $ret == 139 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Segmentation fault)"
    elif [[ $ret == 136 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Floating point exception)"
    elif [[ $ret == 124 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Probable infinite loop)"
    elif [[ $ret == 57 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Abort)"
    elif [[ $ret == 0 || $ret == 1 ]] ; then
        echo "PASSED"
    else
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Unexpected error: $ret)"
    fi
}

# Run user-provided tool on a given CVE file and generate an output file,
# then report PASSED or FAILED
TEST_TOOL_2FILES() {

    tool=$1
    infile=$2
    outfile=$3
    base=$(basename "$infile" .exp)
    toolbase=$(basename "$tool")
    shift
    shift
    shift

    echo -ne "$base\t\t\t"

    # Store actual output in a file for inspection and reducing clutter on screen
    resultfile="$toolbase-$base.out"

    # Run test, redirecting stderr and stdout to the output file
    (
        # Run using timeout to detect infinite loops.
        # Timeout returns 124 when the timeout has been exceeded.
        timeout 10 $tool "$@" "$infile" "$outfile"

        RET=$?

        # An abort (exit code 134) will cause bash to emit a bunch of noise.
        # Instead, we change the exit code to something the command line
        # tools don't use.
        if [[ $RET == 134 ]] ; then
            exit 57
        else
            exit $RET
        fi

    ) > "$outdir/$resultfile" 2>&1

    RET=$?

    CHECK_RET "$RET"

    # Clean up generated output files
    rm -f $outfile
}

# Run user-provided tool on a given CVE file and report PASSED or FAILED
TEST_TOOL() {

    infile=$1
    base=$(basename "$1" .exp)
    tool=$2
    echo -ne "$base\t\t\t"
    shift
    shift

    # Store actual output in a file for inspection and reducing clutter on screen
    outfile="$base.out"

    # Run test, redirecting stderr and stdout to the output file
    (
        # Run using timeout to detect infinite loops.
        # Timeout returns 124 when the timeout has been exceeded.
        timeout 10 $tool "$@" "$infile"
        # timeout 10 $tool "$infile"

        RET=$?

        # An abort (exit code 134) will cause bash to emit a bunch of noise.
        # Instead, we change the exit code to something the command line
        # tools don't use.
        if [[ $RET == 134 ]] ; then
            exit 57
        else
            exit $RET
        fi

    ) > "$outdir/$outfile" 2>&1

    RET=$?

    CHECK_RET "$RET"
}

# Show the HDF5 version
$H5DUMP -V
echo ""

##############################################################################
##############################################################################
#                                                                            #
#         Run these tools on all CVE files without option:                   #
#           h5dump, h5debug, h5ls, h5repack, and h5stat                      #
#                                                                            #
##############################################################################

# Run h5dump on each CVE file with no options
echo "  === h5dump on all files ==="
echo ""
for testfile in $CVE_TEST_FILES
do
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5DUMP"
done

# Run h5debug on each CVE file
echo ""
echo "  === h5debug on all files ==="
echo ""
for testfile in $CVE_TEST_FILES
do
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5DEBUG"
done

# Run h5ls on each CVE file
echo ""
echo "  === h5ls on all files ==="
echo ""
for testfile in $CVE_TEST_FILES
do
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5LS"
#    TEST_H5LS "$CVE_H5_FILES_DIR/$testfile"
done

# Run h5repack on each CVE file
echo ""
echo "  === h5repack on all files ==="
echo ""
for testfile in $CVE_TEST_FILES
do
    TEST_TOOL_2FILES "$H5REPACK" "$CVE_H5_FILES_DIR/$testfile" "$CVE_H5_FILES_DIR/repacked_$testfile"
done

# Run h5stat on each CVE file
echo ""
echo "  === h5stat on all files ==="
echo ""
for testfile in $CVE_TEST_FILES
do
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5STAT"
done

##############################################################################
##############################################################################
#                                                                            #
#         Run these tools on specific files and options                      #
#                                                                            #
##############################################################################

# Test h5dump with options on affected CVE files
TEST_H5DUMP() {
    echo ""
    echo "     === h5dump on affected files ==="
    testfile="cve-2018-17233.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5DUMP" -r -d BAG_root/metadata
    testfile="cve-2020-10811.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5DUMP" -r -d BAG_root/metadata
}

# Test h5repack with options on affected CVE file
TEST_H5REPACK() {
    echo ""
    echo "     === h5repack on affected files ==="
    testfile="cve-2018-17434.h5"
    TEST_TOOL_2FILES "$H5REPACK" "$CVE_H5_FILES_DIR/$testfile" "$CVE_H5_FILES_DIR/repacked_$testfile" -f GZIP=8 -l dset1:CHUNK=5x6
}

# Test h5stat with options on affected CVE file
TEST_H5STAT() {
    echo ""
    echo "     === h5stat on affected files ==="
    testfile="cve-2018-11207.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5STAT" -A -T -G -D -S
}

# Test h52gif on affected CVE files
TEST_H52GIF() {
    echo ""
    echo "     === h52gif on affected files ==="
    TEST_TOOL $H52GIF "$CVE_H5_FILES_DIR/cve-2018-17435.h5" image1.gif -i image
    TEST_TOOL $H52GIF "$CVE_H5_FILES_DIR/cve-2018-17437.h5" image1.gif
}

# Test gif2h5 on affected CVE files
TEST_GIF2H5() {
    echo ""
    echo "     === gif2h5 on affected files ==="
    for testfile in $GIF2H5_TEST_FILES
    do
        TEST_TOOL_2FILES "$GIF2H5" "$CVE_H5_FILES_DIR/$testfile" "$outdir/$testfile.h5"
    done
}

# Test h5format_convert on affected CVE files
TEST_H5FORMAT_CONVERT() {
    echo ""
    echo "     === h5format_convert on affected files ==="

    testfile="cve-2021-45830.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5FORMAT_CONVERT" -n
    testfile="cve-2021-45832.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5FORMAT_CONVERT" -n
    testfile="cve-2021-46242.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5FORMAT_CONVERT"
    testfile="cve-2021-46244.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5FORMAT_CONVERT"
}

# Test h5clear on affected CVE files
TEST_H5CLEAR() {
    echo ""
    echo "     === h5clear on affected files ==="
    testfile="cve-2020-10810.h5"
    TEST_TOOL "$CVE_H5_FILES_DIR/$testfile" "$H5CLEAR" -s -m
}

# Run oddball tests

echo ""
echo "Test tools on specific files and options"
echo "========================================"

TEST_H5DUMP
TEST_H5REPACK
TEST_H5STAT
# TEST_H52GIF modified cve-2018-17437.h5
TEST_GIF2H5
# TEST_H5FORMAT_CONVERT modified cve-2021-46244.h5
TEST_H5CLEAR

# Report test results and exit
echo ""
if test "$nerrors" -eq 0 ; then
    echo "All tests passed."
    exit $EXIT_SUCCESS
else
    echo "Tests failed with $nerrors errors."
    exit $EXIT_FAILURE
fi
