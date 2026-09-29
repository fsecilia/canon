# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Validate the inputs supplied by Canon's integration-test registration.
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

# Start each nested ASan configure from a clean build tree.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")

# Configure the fixture with the active compiler and toolchain.
set(_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/asan"
    -B "${CANON_TEST_BINARY_DIR}"
    -G "${CANON_GENERATOR}"
    "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
    -DCMAKE_INSTALL_LIBDIR=artifact-lib
    -DCANON_ENABLE_ASAN=ON
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

# Configure and build the valid managed graph before exercising runtime behavior.
execute_process(
    COMMAND ${_configure_command}
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "ASan configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT _build_result EQUAL 0)
    message(FATAL_ERROR
        "ASan build failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# Run an ordinary executable and project-owned CTest entry under the sanitizer runtime.
execute_process(
    COMMAND "${CANON_TEST_BINARY_DIR}/asan_app"
    RESULT_VARIABLE _run_result
    OUTPUT_VARIABLE _run_stdout
    ERROR_VARIABLE _run_stderr
)
if (NOT _run_result EQUAL 0)
    message(FATAL_ERROR
        "ASan executable failed\n"
        "stdout:\n${_run_stdout}\n"
        "stderr:\n${_run_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_CTEST_COMMAND}" --test-dir "${CANON_TEST_BINARY_DIR}" --output-on-failure
    RESULT_VARIABLE _test_result
    OUTPUT_VARIABLE _test_stdout
    ERROR_VARIABLE _test_stderr
)
if (NOT _test_result EQUAL 0)
    message(FATAL_ERROR
        "ASan CTest run failed\n"
        "stdout:\n${_test_stdout}\n"
        "stderr:\n${_test_stderr}")
endif()


# Install the instrumented libraries and prove their exported usage requirements work downstream.
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${CANON_TEST_BINARY_DIR}" --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT _install_result EQUAL 0)
    message(FATAL_ERROR
        "ASan install failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

set(_consumer_build_dir "${CANON_TEST_BINARY_DIR}/package-consumer")
set(_consumer_configure_command
    "${CMAKE_COMMAND}"
    -S "${CANON_SOURCE_DIR}/test/asan-package-consumer"
    -B "${_consumer_build_dir}"
    -G "${CANON_GENERATOR}"
    "-DCanonAsanFixture_DIR=${_install_prefix}/artifact-lib/cmake/CanonAsanFixture"
    "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
    -DCMAKE_BUILD_TYPE=Debug
)
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _consumer_configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

execute_process(
    COMMAND ${_consumer_configure_command}
    RESULT_VARIABLE _consumer_configure_result
    OUTPUT_VARIABLE _consumer_configure_stdout
    ERROR_VARIABLE _consumer_configure_stderr
)
if (NOT _consumer_configure_result EQUAL 0)
    message(FATAL_ERROR
        "ASan package consumer configure failed\n"
        "stdout:\n${_consumer_configure_stdout}\n"
        "stderr:\n${_consumer_configure_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_consumer_build_dir}"
    RESULT_VARIABLE _consumer_build_result
    OUTPUT_VARIABLE _consumer_build_stdout
    ERROR_VARIABLE _consumer_build_stderr
)
if (NOT _consumer_build_result EQUAL 0)
    message(FATAL_ERROR
        "ASan package consumer build failed\n"
        "stdout:\n${_consumer_build_stdout}\n"
        "stderr:\n${_consumer_build_stderr}")
endif()

foreach(_consumer IN ITEMS asan_static_consumer asan_shared_consumer)
    execute_process(
        COMMAND "${_consumer_build_dir}/${_consumer}"
        RESULT_VARIABLE _consumer_run_result
        OUTPUT_VARIABLE _consumer_run_stdout
        ERROR_VARIABLE _consumer_run_stderr
    )
    if (NOT _consumer_run_result EQUAL 0)
        message(FATAL_ERROR
            "ASan package consumer '${_consumer}' failed\n"
            "stdout:\n${_consumer_run_stdout}\n"
            "stderr:\n${_consumer_run_stderr}")
    endif()
endforeach()

# Build and run a separate invalid target, then require a real AddressSanitizer diagnostic.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${CANON_TEST_BINARY_DIR}" --target asan_probe
    RESULT_VARIABLE _probe_build_result
    OUTPUT_VARIABLE _probe_build_stdout
    ERROR_VARIABLE _probe_build_stderr
)
if (NOT _probe_build_result EQUAL 0)
    message(FATAL_ERROR
        "ASan probe build failed\n"
        "stdout:\n${_probe_build_stdout}\n"
        "stderr:\n${_probe_build_stderr}")
endif()

execute_process(
    COMMAND "${CANON_TEST_BINARY_DIR}/asan_probe"
    RESULT_VARIABLE _probe_result
    OUTPUT_VARIABLE _probe_stdout
    ERROR_VARIABLE _probe_stderr
)
if (_probe_result EQUAL 0)
    message(FATAL_ERROR "AddressSanitizer unexpectedly accepted the invalid probe")
endif()

set(_probe_output "${_probe_stdout}\n${_probe_stderr}")
if (NOT _probe_output MATCHES "AddressSanitizer"
    OR NOT _probe_output MATCHES "heap-use-after-free")
    message(FATAL_ERROR
        "ASan probe did not surface the expected heap-use-after-free diagnostic\n"
        "${_probe_output}")
endif()
