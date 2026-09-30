# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_DOXYGEN_EXECUTABLE
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Copy the fixture so its generated documentation stays isolated from the source tree.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
set(_binary_dir "${_source_dir}/out")
set(_ordinary_prefix "${CANON_TEST_BINARY_DIR}/ordinary-prefix")
set(_generated_prefix "${CANON_TEST_BINARY_DIR}/generated-prefix")
set(_documentation_dir manual)
file(COPY "${CANON_SOURCE_DIR}/test/documentation/" DESTINATION "${_source_dir}")

set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${_source_dir}"
    -B "${_binary_dir}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
    "-DCMAKE_INSTALL_DOCDIR=${_documentation_dir}"
    "-DDOXYGEN_EXECUTABLE=${CANON_DOXYGEN_EXECUTABLE}"
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT "${_configure_result}" EQUAL 0)
    message(FATAL_ERROR
        "Documentation-install configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# Build ordinary artifacts without generating documentation.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT "${_build_result}" EQUAL 0)
    message(FATAL_ERROR
        "Documentation-install fixture build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# Ordinary installation must not require or install generated documentation.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --prefix "${_ordinary_prefix}"
    RESULT_VARIABLE _ordinary_install_result
    OUTPUT_VARIABLE _ordinary_install_stdout
    ERROR_VARIABLE _ordinary_install_stderr
)
if (NOT "${_ordinary_install_result}" EQUAL 0)
    message(FATAL_ERROR
        "Ordinary install failed before documentation was generated\n"
        "stdout:\n${_ordinary_install_stdout}\n"
        "stderr:\n${_ordinary_install_stderr}")
endif()
if (EXISTS "${_ordinary_prefix}/${_documentation_dir}")
    message(FATAL_ERROR "Ordinary install unexpectedly installed documentation")
endif()

# An explicit documentation install must fail until the generated HTML exists.
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_binary_dir}"
        --prefix "${_generated_prefix}"
        --component Documentation
    RESULT_VARIABLE _missing_install_result
    OUTPUT_VARIABLE _missing_install_stdout
    ERROR_VARIABLE _missing_install_stderr
)
if ("${_missing_install_result}" EQUAL 0)
    message(FATAL_ERROR "Documentation install unexpectedly succeeded before building doc")
endif()
set(_missing_install_output "${_missing_install_stdout}\n${_missing_install_stderr}")
if (NOT "${_missing_install_output}" MATCHES "doxygen/html")
    message(FATAL_ERROR
        "Documentation install failed for an unexpected reason\n"
        "stdout:\n${_missing_install_stdout}\n"
        "stderr:\n${_missing_install_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    RESULT_VARIABLE _doc_result
    OUTPUT_VARIABLE _doc_stdout
    ERROR_VARIABLE _doc_stderr
)
if (NOT "${_doc_result}" EQUAL 0)
    message(FATAL_ERROR
        "Documentation build failed\n"
        "stdout:\n${_doc_stdout}\n"
        "stderr:\n${_doc_stderr}")
endif()

# Generated documentation remains excluded from an ordinary installation.
file(REMOVE_RECURSE "${_ordinary_prefix}")
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --prefix "${_ordinary_prefix}"
    RESULT_VARIABLE _generated_ordinary_result
    OUTPUT_VARIABLE _generated_ordinary_stdout
    ERROR_VARIABLE _generated_ordinary_stderr
)
if (NOT "${_generated_ordinary_result}" EQUAL 0)
    message(FATAL_ERROR
        "Ordinary install failed after documentation was generated\n"
        "stdout:\n${_generated_ordinary_stdout}\n"
        "stderr:\n${_generated_ordinary_stderr}")
endif()
if (EXISTS "${_ordinary_prefix}/${_documentation_dir}")
    message(FATAL_ERROR "Ordinary install unexpectedly installed generated documentation")
endif()

execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${_binary_dir}"
        --prefix "${_generated_prefix}"
        --component Documentation
    RESULT_VARIABLE _documentation_install_result
    OUTPUT_VARIABLE _documentation_install_stdout
    ERROR_VARIABLE _documentation_install_stderr
)
if (NOT "${_documentation_install_result}" EQUAL 0)
    message(FATAL_ERROR
        "Documentation component install failed\n"
        "stdout:\n${_documentation_install_stdout}\n"
        "stderr:\n${_documentation_install_stderr}")
endif()

set(_installed_index "${_generated_prefix}/${_documentation_dir}/index.html")
if (NOT EXISTS "${_installed_index}")
    message(FATAL_ERROR "Documentation component did not install '${_installed_index}'")
endif()
