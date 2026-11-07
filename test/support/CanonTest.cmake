# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Script-mode helpers for Canon integration-test drivers.
#
# A driver runs through the spec file that test/CMakeLists.txt generates for each test. The spec defines the toolchain,
# the per-test binary directory, and any registration-time settings before it includes the driver, so a driver begins
# directly with the lifecycle it exercises.

include_guard(GLOBAL)

foreach(_canon_required_variable IN ITEMS CANON_SOURCE_DIR CANON_TEST_BINARY_DIR CANON_GENERATOR CANON_TEST_CONFIG)
    if(NOT DEFINED ${_canon_required_variable} OR "${${_canon_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_canon_required_variable} is required; run this driver through its generated test spec")
    endif()
endforeach()

file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
file(MAKE_DIRECTORY "${CANON_TEST_BINARY_DIR}")

set(_CANON_TEST_EXPECTATION_OPTIONS EXPECT_FAILURE)
set(_CANON_TEST_EXPECTATION_LISTS EXPECTED_OUTPUT EXPECTED_REGEX)

# Fails the test when any listed variable is undefined or empty.
function(canon_test_require_variables)
    foreach(_variable IN LISTS ARGN)
        if(NOT DEFINED ${_variable} OR "${${_variable}}" STREQUAL "")
            message(FATAL_ERROR "${_variable} is required")
        endif()
    endforeach()
endfunction()

# Runs one command and checks its result and output.
#
# EXPECTED_OUTPUT fragments match literally after collapsing whitespace, so wrapped diagnostics still match.
# EXPECTED_REGEX patterns match the raw combined output.
function(canon_test_run)
    cmake_parse_arguments(
        PARSE_ARGV 0
        _test
        "${_CANON_TEST_EXPECTATION_OPTIONS}"
        "DESCRIPTION"
        "COMMAND;${_CANON_TEST_EXPECTATION_LISTS}"
    )
    if(_test_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "canon_test_run(): unexpected arguments: ${_test_UNPARSED_ARGUMENTS}")
    endif()
    canon_test_require_variables(_test_DESCRIPTION _test_COMMAND)

    message(STATUS "${_test_DESCRIPTION}")
    execute_process(
        COMMAND ${_test_COMMAND}
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
    )
    list(JOIN _test_COMMAND " " _command_text)
    set(_report "command:\n  ${_command_text}\nresult: ${_result}\nstdout:\n${_stdout}\nstderr:\n${_stderr}")

    if(_test_EXPECT_FAILURE)
        if("${_result}" STREQUAL "0")
            message(FATAL_ERROR "${_test_DESCRIPTION} unexpectedly succeeded\n${_report}")
        endif()
    elseif(NOT "${_result}" STREQUAL "0")
        message(FATAL_ERROR "${_test_DESCRIPTION} failed\n${_report}")
    endif()

    string(REGEX REPLACE "[ \t\r\n]+" " " _normalized_output "${_stdout}\n${_stderr}")
    foreach(_fragment IN LISTS _test_EXPECTED_OUTPUT)
        string(REGEX REPLACE "[ \t\r\n]+" " " _normalized_fragment "${_fragment}")
        string(FIND "${_normalized_output}" "${_normalized_fragment}" _position)
        if("${_position}" EQUAL -1)
            message(FATAL_ERROR "${_test_DESCRIPTION} did not report expected output\nexpected:\n${_fragment}\n${_report}")
        endif()
    endforeach()
    foreach(_pattern IN LISTS _test_EXPECTED_REGEX)
        if(NOT "${_stdout}\n${_stderr}" MATCHES "${_pattern}")
            message(FATAL_ERROR "${_test_DESCRIPTION} did not report expected output\npattern:\n${_pattern}\n${_report}")
        endif()
    endforeach()
endfunction()

# Parses a lifecycle helper's arguments and collects its expectations for canon_test_run().
macro(_canon_test_parse_step OPTIONS ONE_VALUE MULTI_VALUE)
    cmake_parse_arguments(
        PARSE_ARGV 0
        _step
        "${_CANON_TEST_EXPECTATION_OPTIONS};${OPTIONS}"
        "DESCRIPTION;${ONE_VALUE}"
        "${_CANON_TEST_EXPECTATION_LISTS};${MULTI_VALUE}"
    )
    if(_step_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(): unexpected arguments: ${_step_UNPARSED_ARGUMENTS}")
    endif()

    set(_step_expectations)
    if(_step_EXPECT_FAILURE)
        list(APPEND _step_expectations EXPECT_FAILURE)
    endif()
    foreach(_step_list IN LISTS _CANON_TEST_EXPECTATION_LISTS)
        if(DEFINED _step_${_step_list})
            list(APPEND _step_expectations ${_step_list} ${_step_${_step_list}})
        endif()
    endforeach()
endmacro()

# Reports whether the configured generator builds several configurations in one tree.
function(_canon_test_is_multi_config OUT_MULTI_CONFIG)
    if("${CANON_GENERATOR}" MATCHES "Multi-Config|^Visual Studio|^Xcode$")
        set(${OUT_MULTI_CONFIG} TRUE PARENT_SCOPE)
    else()
        set(${OUT_MULTI_CONFIG} FALSE PARENT_SCOPE)
    endif()
endfunction()

# Configures one fixture with the test toolchain.
#
# Arguments apply in this order, so later values win: toolchain, tool overrides discovered by the outer project,
# registration-time ARGS, then this call's ARGS.
function(canon_test_configure)
    _canon_test_parse_step("" "SOURCE;BINARY" "ARGS")
    canon_test_require_variables(_step_SOURCE _step_BINARY)
    if("${_step_DESCRIPTION}" STREQUAL "")
        cmake_path(GET _step_SOURCE FILENAME _fixture_name)
        set(_step_DESCRIPTION "configure ${_fixture_name}")
    endif()

    set(_command
        "${CMAKE_COMMAND}"
        -S "${_step_SOURCE}"
        -B "${_step_BINARY}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
    )
    if(NOT "${CANON_CXX_COMPILER}" STREQUAL "")
        list(APPEND _command "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}")
    endif()
    if(NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()
    _canon_test_is_multi_config(_multi_config)
    if(NOT _multi_config)
        list(APPEND _command "-DCMAKE_BUILD_TYPE=${CANON_TEST_CONFIG}")
    endif()
    list(APPEND _command ${CANON_TEST_TOOL_ARGUMENTS} ${CANON_TEST_CONFIGURE_ARGUMENTS} ${_step_ARGS})

    canon_test_run(DESCRIPTION "${_step_DESCRIPTION}" COMMAND ${_command} ${_step_expectations})
endfunction()

# Builds the default target, or one named target, of a configured tree.
function(canon_test_build)
    _canon_test_parse_step("" "BINARY;TARGET" "")
    canon_test_require_variables(_step_BINARY)
    set(_command "${CMAKE_COMMAND}" --build "${_step_BINARY}" --config "${CANON_TEST_CONFIG}")
    if(NOT "${_step_TARGET}" STREQUAL "")
        list(APPEND _command --target "${_step_TARGET}")
    endif()
    if("${_step_DESCRIPTION}" STREQUAL "")
        string(STRIP "build ${_step_TARGET}" _step_DESCRIPTION)
    endif()
    canon_test_run(DESCRIPTION "${_step_DESCRIPTION}" COMMAND ${_command} ${_step_expectations})
endfunction()

# Installs a configured tree, optionally one component, into PREFIX.
function(canon_test_install)
    _canon_test_parse_step("" "BINARY;PREFIX;COMPONENT" "")
    canon_test_require_variables(_step_BINARY _step_PREFIX)
    set(_command
        "${CMAKE_COMMAND}" --install "${_step_BINARY}"
        --config "${CANON_TEST_CONFIG}"
        --prefix "${_step_PREFIX}"
    )
    if(NOT "${_step_COMPONENT}" STREQUAL "")
        list(APPEND _command --component "${_step_COMPONENT}")
    endif()
    if("${_step_DESCRIPTION}" STREQUAL "")
        string(STRIP "install ${_step_COMPONENT}" _step_DESCRIPTION)
    endif()
    canon_test_run(DESCRIPTION "${_step_DESCRIPTION}" COMMAND ${_command} ${_step_expectations})
endfunction()

# Runs the CTest tests registered by a configured fixture.
function(canon_test_ctest)
    _canon_test_parse_step("" "BINARY" "")
    canon_test_require_variables(_step_BINARY)
    if("${_step_DESCRIPTION}" STREQUAL "")
        set(_step_DESCRIPTION "fixture tests")
    endif()
    canon_test_run(
        DESCRIPTION "${_step_DESCRIPTION}"
        COMMAND
            "${CMAKE_CTEST_COMMAND}"
            --test-dir "${_step_BINARY}"
            --build-config "${CANON_TEST_CONFIG}"
            --output-on-failure
            --no-tests=error
        ${_step_expectations}
    )
endfunction()

# Runs one executable built at the top of a configured tree.
function(canon_test_execute)
    _canon_test_parse_step("" "BINARY;TARGET" "")
    canon_test_require_variables(_step_BINARY _step_TARGET)
    _canon_test_is_multi_config(_multi_config)
    if(_multi_config)
        set(_executable "${_step_BINARY}/${CANON_TEST_CONFIG}/${_step_TARGET}${CANON_EXECUTABLE_SUFFIX}")
    else()
        set(_executable "${_step_BINARY}/${_step_TARGET}${CANON_EXECUTABLE_SUFFIX}")
    endif()
    if("${_step_DESCRIPTION}" STREQUAL "")
        set(_step_DESCRIPTION "run ${_step_TARGET}")
    endif()
    canon_test_run(DESCRIPTION "${_step_DESCRIPTION}" COMMAND "${_executable}" ${_step_expectations})
endfunction()

# Reads one cache entry's value from a configured tree, failing if the entry is absent.
function(canon_test_cache_value OUT_VALUE BINARY NAME)
    set(_cache "${BINARY}/CMakeCache.txt")
    if(NOT EXISTS "${_cache}")
        message(FATAL_ERROR "'${BINARY}' has not been configured")
    endif()
    file(STRINGS "${_cache}" _line REGEX "^${NAME}:[A-Z]+=")
    if("${_line}" STREQUAL "")
        message(FATAL_ERROR "'${_cache}' has no ${NAME} entry")
    endif()
    string(REGEX REPLACE "^[^=]*=" "" _value "${_line}")
    set(${OUT_VALUE} "${_value}" PARENT_SCOPE)
endfunction()

# Fails unless every listed path exists.
function(canon_test_require_paths)
    foreach(_path IN LISTS ARGN)
        if(NOT EXISTS "${_path}")
            message(FATAL_ERROR "expected '${_path}' to exist")
        endif()
    endforeach()
endfunction()

# Fails if any listed path exists.
function(canon_test_forbid_paths)
    foreach(_path IN LISTS ARGN)
        if(EXISTS "${_path}")
            message(FATAL_ERROR "expected '${_path}' not to exist")
        endif()
    endforeach()
endfunction()

# Checks an installation against the manifest that canon_fixture_expect_installed() wrote at configure time.
function(canon_test_check_install_manifest BINARY PREFIX)
    set(_manifest "${BINARY}/canon-install-manifest-${CANON_TEST_CONFIG}.txt")
    canon_test_require_paths("${_manifest}")
    file(STRINGS "${_manifest}" _entries)
    if(NOT _entries)
        message(FATAL_ERROR "install manifest '${_manifest}' is empty")
    endif()
    foreach(_entry IN LISTS _entries)
        string(REGEX MATCH "^(present|absent) (.+)$" _matched "${_entry}")
        if("${_matched}" STREQUAL "")
            message(FATAL_ERROR "malformed install manifest entry '${_entry}'")
        endif()
        if("${CMAKE_MATCH_1}" STREQUAL "present")
            canon_test_require_paths("${PREFIX}/${CMAKE_MATCH_2}")
        else()
            canon_test_forbid_paths("${PREFIX}/${CMAKE_MATCH_2}")
        endif()
    endforeach()
endfunction()

# Concatenates every file below DIRECTORY that matches GLOB, skipping names that match EXCLUDE_REGEX.
function(canon_test_read_files OUT_TEXT DIRECTORY GLOB)
    cmake_parse_arguments(PARSE_ARGV 3 _read "" "EXCLUDE_REGEX" "")
    file(GLOB_RECURSE _files LIST_DIRECTORIES FALSE "${DIRECTORY}/${GLOB}")
    if(NOT _files)
        message(FATAL_ERROR "no files match '${DIRECTORY}/${GLOB}'")
    endif()
    set(_text "")
    foreach(_file IN LISTS _files)
        if(NOT "${_read_EXCLUDE_REGEX}" STREQUAL "" AND "${_file}" MATCHES "${_read_EXCLUDE_REGEX}")
            continue()
        endif()
        file(READ "${_file}" _contents)
        string(APPEND _text "\n${_contents}")
    endforeach()
    set(${OUT_TEXT} "${_text}" PARENT_SCOPE)
endfunction()

# Fails unless TEXT matches every listed pattern. LABEL names the text in diagnostics.
function(canon_test_require_matches TEXT LABEL)
    foreach(_pattern IN LISTS ARGN)
        if(NOT "${TEXT}" MATCHES "${_pattern}")
            message(FATAL_ERROR "${LABEL} does not match '${_pattern}'")
        endif()
    endforeach()
endfunction()

# Fails if TEXT matches any listed pattern. LABEL names the text in diagnostics.
function(canon_test_forbid_matches TEXT LABEL)
    foreach(_pattern IN LISTS ARGN)
        if("${TEXT}" MATCHES "${_pattern}")
            message(FATAL_ERROR "${LABEL} unexpectedly matches '${_pattern}'")
        endif()
    endforeach()
endfunction()

# Fails unless a generated Doxyfile assigns NAME exactly once, to VALUE.
function(canon_test_require_doxygen_setting DOXYFILE NAME VALUE)
    file(STRINGS "${DOXYFILE}" _lines REGEX "^${NAME}[\t ]*=")
    list(LENGTH _lines _count)
    if(NOT "${_count}" EQUAL 1)
        message(FATAL_ERROR "expected one Doxygen ${NAME} setting in '${DOXYFILE}', found ${_count}")
    endif()
    string(REGEX REPLACE "^[^=]*=[\t ]*" "" _actual "${_lines}")
    string(STRIP "${_actual}" _actual)
    if(NOT "${_actual}" STREQUAL "${VALUE}")
        message(FATAL_ERROR "expected Doxygen '${NAME} = ${VALUE}', found '${_lines}'")
    endif()
endfunction()
