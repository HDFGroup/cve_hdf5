# HDF5 CVE Test Suite

Contains scripts and test files for testing CVE issues filed against
the HDF5 library

* test_hdf5_cve.sh - Currently test 1.10.9, 1.12.0, 1.14.0, and develop only
* test_hdf5_cve_specific_version.sh - Tests a specific version of HDF5
  
  Usage:

  ./test_hdf5_cve_specific_version.sh \<bin directory of h5dump\> \<name of your test directory\>
  
  (Currently, the test directory needs to be in cve_hdf5 repo directory, in order to access the CVE test files in testfiles/)
