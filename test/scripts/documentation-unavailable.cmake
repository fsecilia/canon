# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

# Configure with Doxygen discovery disabled to exercise the late-bound requirement path.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_SOURCE_DIR}/test/documentation-unavailable")
set(_binary_dir "${CANON_TEST_BINARY_DIR}")

execute_process(
    COMMAND
        "${CMAKE_COMMAND}"
        -S "${_source_dir}"
        -B "${_binary_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=TRUE
    RESULT_VARIABLE _configure_result
    OUTPUT_VARIABLE _configure_stdout
    ERROR_VARIABLE _configure_stderr
)
if (NOT _configure_result EQUAL 0)
    message(FATAL_ERROR
        "Documentation-unavailable fixture configure failed\n"
        "stdout:\n${_configure_stdout}\n"
        "stderr:\n${_configure_stderr}")
endif()

# The ordinary build must remain usable when documentation tooling is absent.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}"
    RESULT_VARIABLE _build_result
    OUTPUT_VARIABLE _build_stdout
    ERROR_VARIABLE _build_stderr
)
if (NOT _build_result EQUAL 0)
    message(FATAL_ERROR
        "Build without Doxygen failed\n"
        "stdout:\n${_build_stdout}\n"
        "stderr:\n${_build_stderr}")
endif()

# Ordinary installation must not require documentation tooling or generated output.
set(_install_prefix "${CANON_TEST_BINARY_DIR}/install")
execute_process(
    COMMAND "${CMAKE_COMMAND}" --install "${_binary_dir}" --prefix "${_install_prefix}"
    RESULT_VARIABLE _install_result
    OUTPUT_VARIABLE _install_stdout
    ERROR_VARIABLE _install_stderr
)
if (NOT _install_result EQUAL 0)
    message(FATAL_ERROR
        "Install without Doxygen failed\n"
        "stdout:\n${_install_stdout}\n"
        "stderr:\n${_install_stderr}")
endif()

# Cleanup is always available, even when documentation generation is not.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc-clean
    RESULT_VARIABLE _clean_result
    OUTPUT_VARIABLE _clean_stdout
    ERROR_VARIABLE _clean_stderr
)
if (NOT _clean_result EQUAL 0)
    message(FATAL_ERROR
        "doc-clean without Doxygen failed\n"
        "stdout:\n${_clean_stdout}\n"
        "stderr:\n${_clean_stderr}")
endif()

# Requesting documentation without Doxygen must fail with Canon's explicit diagnostic.
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${_binary_dir}" --target doc
    RESULT_VARIABLE _doc_result
    OUTPUT_VARIABLE _doc_stdout
    ERROR_VARIABLE _doc_stderr
)
if (_doc_result EQUAL 0)
    message(FATAL_ERROR "doc unexpectedly succeeded without Doxygen")
endif()

set(_doc_output "${_doc_stdout}\n${_doc_stderr}")
foreach(_expected_fragment IN ITEMS
    "Doxygen 1.9 or newer was not found when this build tree was configured."
    "Install Doxygen 1.9 or newer and reconfigure before building the doc target."
)
    if (NOT _doc_output MATCHES "${_expected_fragment}")
        message(FATAL_ERROR
            "doc failed without the expected missing-Doxygen diagnostic\n"
            "expected fragment:\n${_expected_fragment}\n"
            "stdout:\n${_doc_stdout}\n"
            "stderr:\n${_doc_stderr}")
    endif()
endforeach()
