# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
    CANON_EXPECTED_VERSION
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Start the installed consumer from clean staging and build trees.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")

#
# configure and install Canon
#

# configure
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}"
        -B "${CANON_TEST_BINARY_DIR}/canon-build"
        -G "${CANON_GENERATOR}"
        -DBUILD_TESTING=OFF
    RESULT_VARIABLE _canon_configure_result
    OUTPUT_VARIABLE _canon_configure_stdout
    ERROR_VARIABLE _canon_configure_stderr
)
if (NOT _canon_configure_result EQUAL 0)
    message(FATAL_ERROR
        "Canon staging configure failed\n"
        "stdout:\n${_canon_configure_stdout}\n"
        "stderr:\n${_canon_configure_stderr}")
endif()

# install
execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        --install "${CANON_TEST_BINARY_DIR}/canon-build"
        --prefix "${_install_prefix}"
    RESULT_VARIABLE _canon_install_result
    OUTPUT_VARIABLE _canon_install_stdout
    ERROR_VARIABLE _canon_install_stderr
)
if (NOT _canon_install_result EQUAL 0)
    message(FATAL_ERROR
        "Canon staging install failed\n"
        "stdout:\n${_canon_install_stdout}\n"
        "stderr:\n${_canon_install_stderr}")
endif()

#
# configure and build consumer
#

set(_consumer_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/installed"
    -B "${CANON_TEST_BINARY_DIR}/consumer-build"
    -G "${CANON_GENERATOR}"
    "-DCANON_EXPECTED_VERSION=${CANON_EXPECTED_VERSION}"
    "-DCANON_EXPECTED_DIR=${_install_prefix}/share/cmake/Canon"
    "-DCMAKE_PREFIX_PATH=${_install_prefix}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

# configure
execute_process(
    COMMAND ${_consumer_configure_command}
    RESULT_VARIABLE _consumer_configure_result
    OUTPUT_VARIABLE _consumer_configure_stdout
    ERROR_VARIABLE _consumer_configure_stderr
)
if (NOT _consumer_configure_result EQUAL 0)
    message(FATAL_ERROR
        "Installed Canon consumer configure failed\n"
        "stdout:\n${_consumer_configure_stdout}\n"
        "stderr:\n${_consumer_configure_stderr}")
endif()

# build
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}/consumer-build"
    RESULT_VARIABLE _consumer_build_result
    OUTPUT_VARIABLE _consumer_build_stdout
    ERROR_VARIABLE _consumer_build_stderr
)
if (NOT _consumer_build_result EQUAL 0)
    message(FATAL_ERROR
        "Installed Canon consumer build failed\n"
        "stdout:\n${_consumer_build_stdout}\n"
        "stderr:\n${_consumer_build_stderr}")
endif()
