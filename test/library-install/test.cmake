# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

canon_test_make_configure_command(
    _configure_command
    "${CANON_SOURCE_DIR}/test/library-install"
    "${_build_dir}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    -DCMAKE_BUILD_TYPE=Debug
)

canon_test_run(
    DESCRIPTION "Canon library-install configure"
    COMMAND ${_configure_command}
)
canon_test_run(
    DESCRIPTION "Canon library-install build"
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
)
canon_test_run(
    DESCRIPTION "Canon library-install install"
    COMMAND "${CMAKE_COMMAND}" --install "${_build_dir}" --prefix "${_install_prefix}"
)

file(STRINGS "${_build_dir}/installed-directories.txt" _installed_directories)
list(GET _installed_directories 0 _library_directory)
list(GET _installed_directories 1 _include_directory)

file(STRINGS "${_build_dir}/installed-library-names.txt" _library_names)
foreach(_library_name IN LISTS _library_names)
    set(_installed_library "${_install_prefix}/${_library_directory}/${_library_name}")
    if (NOT EXISTS "${_installed_library}")
        message(FATAL_ERROR "Canon library install did not produce '${_installed_library}'")
    endif()
endforeach()

foreach(_header IN ITEMS
    arbitrary/sample.hpp
    interface_api/sample.hpp
    canon_library_install/export.hpp
    canon_library_install/ipv6_address/export.hpp
    canon_library_install/sample_module/export.hpp
)
    set(_installed_header "${_install_prefix}/${_include_directory}/${_header}")
    if (NOT EXISTS "${_installed_header}")
        message(FATAL_ERROR "Canon library install did not produce '${_installed_header}'")
    endif()
endforeach()
