# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

function(canon_test_require_variables)
    foreach(_required_variable IN LISTS ARGN)
        if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
            message(FATAL_ERROR "${_required_variable} is required")
        endif()
    endforeach()
endfunction()

function(canon_test_run)
    set(_options EXPECT_FAILURE NORMALIZE_WHITESPACE)
    set(_one_value_arguments DESCRIPTION)
    set(_multi_value_arguments COMMAND EXPECTED_OUTPUT)
    cmake_parse_arguments(
        PARSE_ARGV 0
        _test
        "${_options}"
        "${_one_value_arguments}"
        "${_multi_value_arguments}"
    )

    if (_test_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "canon_test_run(): unexpected arguments: ${_test_UNPARSED_ARGUMENTS}")
    endif()
    if ("${_test_DESCRIPTION}" STREQUAL "")
        message(FATAL_ERROR "canon_test_run(): DESCRIPTION is required")
    endif()
    if (NOT _test_COMMAND)
        message(FATAL_ERROR "canon_test_run(): COMMAND is required")
    endif()

    execute_process(
        COMMAND ${_test_COMMAND}
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
    )

    if (_test_EXPECT_FAILURE)
        if ("${_result}" STREQUAL "0")
            message(FATAL_ERROR "${_test_DESCRIPTION} unexpectedly succeeded")
        endif()
    elseif (NOT "${_result}" STREQUAL "0")
        message(FATAL_ERROR
            "${_test_DESCRIPTION} failed with result '${_result}'\n"
            "stdout:\n${_stdout}\n"
            "stderr:\n${_stderr}")
    endif()

    if (DEFINED _test_EXPECTED_OUTPUT)
        set(_output "${_stdout}\n${_stderr}")
        if (_test_NORMALIZE_WHITESPACE)
            string(REGEX REPLACE "[ \t\r\n]+" " " _output "${_output}")
        endif()

        foreach(_expected_output IN LISTS _test_EXPECTED_OUTPUT)
            set(_expected_fragment "${_expected_output}")
            if (_test_NORMALIZE_WHITESPACE)
                string(REGEX REPLACE
                    "[ \t\r\n]+" " " _expected_fragment "${_expected_fragment}")
            endif()

            string(FIND "${_output}" "${_expected_fragment}" _expected_output_position)
            if ("${_expected_output_position}" EQUAL -1)
                message(FATAL_ERROR
                    "${_test_DESCRIPTION} did not report the expected output\n"
                    "expected fragment:\n${_expected_output}\n"
                    "stdout:\n${_stdout}\n"
                    "stderr:\n${_stderr}")
            endif()
        endforeach()
    endif()
endfunction()
