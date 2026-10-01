# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)

project(Canon VERSION 0.1.0 LANGUAGES NONE)

include(cmake/Canon.cmake)

# Keep Canon's development setup out of projects that vendor it as a subdirectory.
if (NOT PROJECT_IS_TOP_LEVEL)
    return()
endif()

include(CMakePackageConfigHelpers)
_canon_package_version_compatibility(_canon_version_compatibility)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY "${_canon_version_compatibility}"
    ARCH_INDEPENDENT
)

install(
    FILES
        cmake/Canon.cmake
        cmake/CanonConfig.cmake
        cmake/CanonCoverageClean.cmake
        cmake/CanonCoverageVerify.cmake
        "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    DESTINATION share/cmake/Canon
)

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(test)
endif()
