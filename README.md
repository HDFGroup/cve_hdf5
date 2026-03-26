# HDF5 CVE Test Suite

This repository contains scripts and test files for testing [CVE issues filed against the HDF5 library](https://www.cve.org/CVERecord/SearchResults?query=hdf5).

Review the list of CVEs in the [CVE_list.md](CVE_list.md) file. This file contains a summary of each CVE, including its ID, the version(s) of the HDF5 library in which  fixes were released, and the commit hash against the `develop` branch of the fix.

## Running the Tests

**Usage:**

```bash
./test_hdf5_cve.sh <bin directory of h5dump> <directory for output files>
```

## Generating the CVE Markdown File

⚠️ **Note:** Do not modify the generated `CVE_list.md` file directly! Instead, use the provided script to regenerate it from the YAML files.

```bash
./yaml2md.py [<path to the CVE yaml file>] [-o <output markdown file>]
./yaml2md.py --validate-only [<path to the CVE yaml file>]
./yaml2md.py --validate-only --check-links [<path to the CVE yaml file>]
```
`--check-links` performs a network reachability check for each CVE URL during validation.

## Adding New CVE Entries
To add a new CVE to this repository, follow these steps:

 1. Add an entry to `CVE_list.yml`
 2. Execute `./yaml2md.py -o CVE_list.md` as described above
 3. Add the test file(s) to the `cvefiles` directory, following the existing naming convention
 4. Add the test file(s) to the `CVE_TEST_FILES` variable in the `test_hdf5_cve.sh` script
 5. Add any other testing necessary to the `test_hdf5_cve.sh` script if simple execution of `h5dump`, `h5debug`, `h5ls`, `h5repack`, and `h5stat` on each test file is not sufficient to reproduce the issue
 6. Add an entry to `cvefiles/README.md`
 7. Ensure `test_hdf5_cve.sh` fails with an unpatched library version and passes with a patched library version. It's possible that the new test files will expose a different issue. In this case, first verify it is actually a library or tool issue, then leave the failing test in place and file a GitHub issue (if it is not a security issue) or security vulnerability (if it is).

## Acknowledgment

> This material is based upon work supported by the U.S. National Science Foundation under Federal Award No. 2534078. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
