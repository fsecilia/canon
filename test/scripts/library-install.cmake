# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Validate the inputs supplied by Canon's library-install integration test.
foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Start the library-install lifecycle from clean build and install trees.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_build_dir "${CANON_TEST_BINARY_DIR}/build")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/library-install"
    -B "${_build_dir}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

# Configure the library fixture and retain output for a useful failure report.
execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "Canon library-install configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# Build each compiled library before installing it.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT _build_result EQUAL 0)
    message(FATAL_ERROR
        "Canon library-install build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# Install through the same lifecycle used by a real consumer project.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_build_dir}"
        --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT _install_result EQUAL 0)
    message(FATAL_ERROR
        "Canon library-install install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

# Resolve the platform's conventional library and include directories.
file(STRINGS "${_build_dir}/installed-directories.txt" _installed_directories)
list(GET _installed_directories 0 _library_directory)
list(GET _installed_directories 1 _include_directory)

# Require each compiled artifact to appear in the conventional library directory.
file(STRINGS "${_build_dir}/installed-library-names.txt" _library_names)
foreach(_library_name IN LISTS _library_names)
    set(_installed_library "${_install_prefix}/${_library_directory}/${_library_name}")
    if (NOT EXISTS "${_installed_library}")
        message(FATAL_ERROR "Canon library install did not produce '${_installed_library}'")
    endif()
endforeach()

# Require both arbitrarily named public header sets and Canon's generated export headers.
foreach(_header IN ITEMS
    arbitrary/sample.hpp
    interface_api/sample.hpp
    sample_static/export.hpp
    sample_shared/export.hpp
    sample_module/export.hpp
)
    set(_installed_header "${_install_prefix}/${_include_directory}/${_header}")
    if (NOT EXISTS "${_installed_header}")
        message(FATAL_ERROR "Canon library install did not produce '${_installed_header}'")
    endif()
endforeach()
