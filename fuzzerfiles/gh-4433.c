#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <hdf5.h>

int main(int argc, char *argv[])
{
   hid_t v0 = H5Fopen(argv[1], H5F_ACC_RDONLY, H5P_DEFAULT);
   if (v0 == H5I_INVALID_HID) exit(1);
   H5G_info_t * v1;
   H5Gget_info(v0, v1);
   return 0;
}

