# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

function(canon_test_require_variables)
    foreach(_required_variable IN LISTS ARGN)
        if(NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
            message(FATAL_ERROR "${_required_variable} is required")
        endif()
    endforeach()
endfunction()

function(canon_test_run)
    set(_options EXPECT_FAILURE)
    set(_one_value_arguments DESCRIPTION)
    set(_multi_value_arguments COMMAND EXPECTED_OUTPUT EXPECTED_REGEX)
    cmake_parse_arguments(
        PARSE_ARGV 0
        _test
        "${_options}"
        "${_one_value_arguments}"
        "${_multi_value_arguments}"
    )

    if(_test_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "canon_test_run(): unexpected arguments: ${_test_UNPARSED_ARGUMENTS}")
    endif()
    if("${_test_DESCRIPTION}" STREQUAL "")
        message(FATAL_ERROR "canon_test_run(): DESCRIPTION is required")
    endif()
    if(NOT _test_COMMAND)
        message(FATAL_ERROR "canon_test_run(): COMMAND is required")
    endif()

    execute_process(
        COMMAND ${_test_COMMAND}
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
    )

    if(_test_EXPECT_FAILURE)
        if("${_result}" STREQUAL "0")
            message(FATAL_ERROR "${_test_DESCRIPTION} unexpectedly succeeded")
        endif()
    elseif(NOT "${_result}" STREQUAL "0")
        message(FATAL_ERROR
            "${_test_DESCRIPTION} failed with result '${_result}'\n"
            "stdout:\n${_stdout}\n"
            "stderr:\n${_stderr}")
    endif()

    if(DEFINED _test_EXPECTED_OUTPUT)
        set(_literal_output "${_stdout}\n${_stderr}")
        string(REGEX REPLACE "[ \t\r\n]+" " " _literal_output "${_literal_output}")
    endif()
    if(DEFINED _test_EXPECTED_REGEX)
        set(_regex_output "${_stdout}\n${_stderr}")
    endif()

    foreach(_expected_output IN LISTS _test_EXPECTED_OUTPUT)
        set(_expected_fragment "${_expected_output}")
        string(REGEX REPLACE
            "[ \t\r\n]+" " " _expected_fragment "${_expected_fragment}")

        string(FIND "${_literal_output}" "${_expected_fragment}" _expected_output_position)
        if("${_expected_output_position}" EQUAL -1)
            message(FATAL_ERROR
                "${_test_DESCRIPTION} did not report the expected output\n"
                "expected fragment:\n${_expected_output}\n"
                "stdout:\n${_stdout}\n"
                "stderr:\n${_stderr}")
        endif()
    endforeach()

    foreach(_expected_regex IN LISTS _test_EXPECTED_REGEX)
        if(NOT "${_regex_output}" MATCHES "${_expected_regex}")
            message(FATAL_ERROR
                "${_test_DESCRIPTION} did not report the expected output\n"
                "expected regular expression:\n${_expected_regex}\n"
                "stdout:\n${_stdout}\n"
                "stderr:\n${_stderr}")
        endif()
    endforeach()
endfunction()

function(canon_test_executable_path OUT_PATH BINARY_DIR TARGET)
    file(STRINGS
        "${BINARY_DIR}/CMakeCache.txt"
        _configuration_types
        REGEX "^CMAKE_CONFIGURATION_TYPES:"
        LIMIT_COUNT 1
    )
    if(_configuration_types)
        set(_path "${BINARY_DIR}/${CANON_TEST_CONFIG}/${TARGET}${CANON_EXECUTABLE_SUFFIX}")
    else()
        set(_path "${BINARY_DIR}/${TARGET}${CANON_EXECUTABLE_SUFFIX}")
    endif()
    set(${OUT_PATH} "${_path}" PARENT_SCOPE)
endfunction()

function(canon_test_make_configure_command OUT_COMMAND SOURCE_DIR BINARY_DIR)
    set(_command
        "${CMAKE_COMMAND}"
        -S "${SOURCE_DIR}"
        -B "${BINARY_DIR}"
        -G "${CANON_GENERATOR}"
    )
    if(DEFINED CANON_CXX_COMPILER AND NOT "${CANON_CXX_COMPILER}" STREQUAL "")
        list(APPEND _command "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}")
    endif()
    if(DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()
    list(APPEND _command ${ARGN})
    set(${OUT_COMMAND} "${_command}" PARENT_SCOPE)
endfunction()
