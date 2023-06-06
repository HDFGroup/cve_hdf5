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

# Location of CVE files
CVE_H5_FILES_DIR=cvefiles

# How are the CVE issues tested?
# CVE-2017-17505
# CVE-2017-17506
# CVE-2017-17507
# CVE-2017-17508
# CVE-2017-17509
# CVE-2018-11202
# CVE-2018-11203
# CVE-2018-11204
# CVE-2018-11205
# CVE-2018-11206
# CVE-2018-13873
# CVE-2018-15671
# CVE-2018-15672
# CVE-2018-17233
# CVE-2018-17234
# CVE-2018-17433
# CVE-2018-17434
# CVE-2018-17435
# CVE-2018-17436
# CVE-2018-17437
# CVE-2018-17438
# CVE-2018-17439
# CVE-2019-8396
# CVE-2019-8397
# CVE-2019-8398
# CVE-2019-9151
# CVE-2019-9152
# CVE-2020-10809
# CVE_2020_10810
# CVE-2020-10810
# CVE-2020-10811
# CVE_2020_10812
# CVE-2020-10812
# CVE-2021-45829    h5stat <file.h>
# CVE-2021-45830    h5format_convert -n <file.h5>
# CVE-2021-45832    h5format_convert -n <file.h5>
# CVE-2021-45833    h5dump <file.h5>
# CVE-2021-46242    h5format_convert <file.h5>
# CVE-2021-46243    h5ls <file.h5>
# CVE-2021-46244    h5format_convert <file.h5>
# CVE-2022-25942    gif2h5 <file.gif> <file.h5>
# CVE-2022-25972    gif2h5 <file.gif> <file.h5>
# CVE-2022-26061    gif2h5 <file.gif> <file.h5>

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
cve-2018-15671.h5
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

# Run user-provided h5dump on a given CVE file and report PASSED or FAILED
TEST_CVEFILE() {

    infile=$1
    base=$(basename "$1" .exp)

    echo -ne "$base\t\t\t"

    # Store actual output in a file for inspection and reducing clutter on screen
    outfile="$base.out"

    # Run test, redirecting stderr and stdout to the output file
    (
        # Run using timeout to detect infinite loops.
        # Timeout returns 124 when the timeout has been exceeded.
        timeout 10 $H5DUMP "$infile"

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

    # A test passes when it invokes normal HDF5 error handling.
    if [[ $RET == 139 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Segmentation fault)"
    elif [[ $RET == 136 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Floating point exception)"
    elif [[ $RET == 124 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Probable infinite loop)"
    elif [[ $RET == 57 ]] ; then
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Abort)"
    elif [[ $RET == 0 || $RET == 1 ]] ; then
        echo "PASSED"
    else
        nerrors=$(( nerrors + 1 ))
        echo "***FAILED*** (Unexpected error: $RET)"
    fi
}

# Show the HDF5 version
$H5DUMP -V
echo ""

# Run h5dump on each CVE file
for testfile in $CVE_TEST_FILES
do
    TEST_CVEFILE "$CVE_H5_FILES_DIR/$testfile"
done

# Report test results and exit
echo ""
if test "$nerrors" -eq 0 ; then
    echo "All tests passed."
    exit $EXIT_SUCCESS
else
    echo "Tests failed with $nerrors errors."
    exit $EXIT_FAILURE
fi
