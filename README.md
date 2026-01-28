# HDF5 CVE Test Suite

This repository contains scripts and test files for testing [CVE issues filed against the HDF5 library](https://www.cve.org/CVERecord/SearchResults?query=hdf5).

**Usage:**

```bash
./test_hdf5_cve.sh \<bin directory of h5dump\> \<directory for output files\>
```

## CVE patterns

Common symptoms (most frequent) among the CVEs tested:

- Buffer overflow variants dominate (heap/stack/general). “Buffer overflow” appears in ~60+ entries.
- Denial of service is just as common (~60+ mentions, often paired with overflows/crashes).
- Out‑of‑bounds read/write is frequent (~20+).
- Null pointer dereference shows up but less often (~8).
- Divide‑by‑zero / SIGFPE shows up in a handful (~5–7).
- Use‑after‑free / double‑free / memory leak are present but relatively rarer.

Commonly affected parts (based on file/function mentions):

- Memory/utility routines: `H5VM_memcpyvv`, `H5MM_`, `H5FL_`
- Core file/metadata handling: `H5F_addr_decode_len`, `H5Fint.c`, `H5O* (object header/layout)`, `H5S*` (dataspace), `H5Dchunk.c`, `H5Ocache.c`
- Filters/extensions appear in several entries (e.g., `scale‑offset`, `gif2h5/decompress`), but the majority still point to core library parsing/metadata paths.

Top file/function mentions (roughly):

- Files: `H5VM.c`, `H5T.c`, `H5S.c`, `H5Olayout.c`, `H5Dchunk.c`, `H5Ocache.c`, `H5Opline.c`, `H5FL.c`
- Functions: `H5VM_memcpyvv`, `H5F_addr_decode_len`, `H5HL__fl_deserialize`, `H5HG_read`, `H5Olayout*`, `H5Opline*`

## Module breakdown

| Module | CVE Count |
| --- | --- |
| Object headers/metadata (`H5O`) | 28 |
| Other/Unclassified (no clear `H5*` token/file) | 22 |
| Datatypes/Type conversion (`H5T`) | 13 |
| File (`H5F`) | 8 |
| Vector/memory utils (`H5VM`) | 8 |
| Datasets (`H5D`) | 8 |
| Filters/Compression (`H5Z`) | 6 |
| Memory management (`H5MM`) | 5 |
| Dataspaces (`H5S`) | 5 |
| Free space (`H5FS`) | 4 |
| Cache (`H5C`) | 4 |
| Heap (global) (`H5HG`) | 4 |
| Attributes (`H5A`) | 4 |
| Groups (`H5G`) | 3 |
| Heap (local) (`H5HL`) | 3 |
| Error handling (`H5E`) | 2 |
| Metadata cache (`H5AC`) | 2 |
| VFD drivers (`H5FD`) | 2 |
| Shared messages (`H5SM`) | 1 |
| References (`H5R`) | 1 |
| Links (`H5L`) | 1 |
| Property lists (`H5P`) | 1 |

## Acknowledgment

> This material is based upon work supported by the U.S. National Science Foundation under Federal Award No. 2534078. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.