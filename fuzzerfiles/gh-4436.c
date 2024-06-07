#include "hdf5.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
typedef uint8_t   u8;   
typedef uint16_t  u16;  
typedef uint32_t  u32;  
typedef uint64_t  u64;
typedef unsigned int usize;
typedef int8_t  i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;
typedef int isize;
typedef float f32;
typedef double f64;
int main() {
    i8 v0_tmp[] = {3, 0, }; // buf
    i8 *v0 = malloc(sizeof v0_tmp);
    memcpy(v0, v0_tmp, sizeof v0_tmp);
    i8 *v1 = v0; // buf
    i64 v2 = H5Tdecode(v1); // $target
}
