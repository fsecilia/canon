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
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY SameMinorVersion
    ARCH_INDEPENDENT
)

if (DEFINED CMAKE_INSTALL_DATADIR AND NOT "${CMAKE_INSTALL_DATADIR}" STREQUAL "")
    set(_canon_data_directory "${CMAKE_INSTALL_DATADIR}")
else()
    set(_canon_data_directory share)
endif()
set(_canon_install_directory "${_canon_data_directory}/cmake/Canon")

install(
    FILES
        cmake/Canon.cmake
        cmake/CanonConfig.cmake
        cmake/CanonCoverageClean.cmake
        cmake/CanonCoverageVerify.cmake
        "${CMAKE_CURRENT_BINARY_DIR}/CanonConfigVersion.cmake"
    DESTINATION "${_canon_install_directory}"
)

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(test)
endif()
