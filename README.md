<h1 align="center">golxzn::cmake</h1>
<!-- <div align="center"> </div> -->

`golxzn::cmake` is a library that provides CMake functions to help you integrate golxzn modules
to your project.

## __*Usage*__

### 1. Add this repository to your project:

```bash
git submodule add https://github.com/golxzn/modules-cmake.git cmake/golxzn
```

You could change `cmake/golxzn` to any path you want. I usually place it near other modules in the
`code/modules/cmake` directory. You could see example in [my sandbox project](https://github.com/golxzn/sandbox).

### 2. Include [goxzn-modules.cmake](golxzn-modules.cmake) to your CMake project:

```cmake
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/golxzn-modules.cmake)

golxzn_load_modules(
	PATH ${CMAKE_SOURCE_DIR}/deps/golxzn
	DISABLED_MODULES
		golxzn::os::threads
		golxzn::os::network
)
```

`golxzn_load_modules` has the following parameters:

| __Argument__         | __Value example__                        | __Description__                                                  |
|---------------------:|------------------------------------------|------------------------------------------------------------------|
| __PATH__             | `code/modules`                           | This path has to contain of golxzn modules, such as `golxzn::os` |
| __DISABLED_MODULES__ | ```golxzn::render;golxzn::os::threads``` | List of excluded golxzn's modules or submodules                  |

### 3. Add golxzn modules to your project:

```bash
git submodule add https://github.com/golxzn/os.git deps/golxzn/os
```

```bash
git submodule add https://github.com/golxzn/core.git deps/golxzn/core
```

## __*I don't need this repository to use golxzn modules!*__

### If you need whole module

It's okay if you don't want or can't use this repository to integrate golxzn modules to your project.
To import any module to your project, you need to clone it as in the third step, and then declare
few variables before include `gmodule.cmake` script:

```cmake
set(GXZN_PATH path/to/modules)
set(GXZN_DISABLED_MODULES golxzn::os::threads golxzn::os::network)

include(${GXZN_PATH}/os/gmodule.cmake)

target_link_libraries(${TARGET} PRIVATE golxzn::os)

```

### If you need a submodule of module!

Any submodule you could obtain with `add_subdirectory` CMake function. But make sure to add
submodules from `grecuires` file!

Example:

```cmake
add_subdirectory(libs/golxzn/os/aliases) # Has to be first, cuz `golxzn::memory` depends on it
add_subdirectory(libs/golxzn/os/memory)
```
