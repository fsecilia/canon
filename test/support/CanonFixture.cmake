# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Configure-time support for Canon integration-test fixtures.
#
# Including this file loads Canon from the source tree unless the fixture already loaded it another way, provides
# property assertions, and finally includes the registration-time case code named by CANON_TEST_CASE_FILE, if any.

include_guard(GLOBAL)

if(NOT COMMAND canon_apply_target)
    if(NOT DEFINED CANON_SOURCE_DIR OR "${CANON_SOURCE_DIR}" STREQUAL "")
        message(FATAL_ERROR "CANON_SOURCE_DIR is required")
    endif()
    include("${CANON_SOURCE_DIR}/cmake/Canon.cmake")
endif()

function(canon_test_require_target_property TARGET PROPERTY EXPECTED)
    get_target_property(_actual "${TARGET}" "${PROPERTY}")
    if(NOT "${_actual}" STREQUAL "${EXPECTED}")
        message(FATAL_ERROR "${TARGET} property ${PROPERTY}: expected '${EXPECTED}', got '${_actual}'")
    endif()
endfunction()

# Fails unless PROPERTY is unset, or empty when ALLOW_EMPTY is given.
function(canon_test_require_target_property_unset TARGET PROPERTY)
    get_property(_set TARGET "${TARGET}" PROPERTY "${PROPERTY}" SET)
    get_property(_actual TARGET "${TARGET}" PROPERTY "${PROPERTY}")
    if(_set AND NOT ("ALLOW_EMPTY" IN_LIST ARGN AND "${_actual}" STREQUAL ""))
        message(FATAL_ERROR "${TARGET} property ${PROPERTY}: expected unset, got '${_actual}'")
    endif()
endfunction()

function(canon_test_require_target_list_value TARGET PROPERTY VALUE)
    get_property(_values TARGET "${TARGET}" PROPERTY "${PROPERTY}")
    if(NOT "${VALUE}" IN_LIST _values)
        message(FATAL_ERROR "${TARGET} ${PROPERTY} is missing '${VALUE}': '${_values}'")
    endif()
endfunction()

function(canon_test_forbid_target_list_value TARGET PROPERTY VALUE)
    get_property(_values TARGET "${TARGET}" PROPERTY "${PROPERTY}")
    if("${VALUE}" IN_LIST _values)
        message(FATAL_ERROR "${TARGET} ${PROPERTY} unexpectedly contains '${VALUE}'")
    endif()
endfunction()

# Fails unless TARGET compiles C++ with each OPTION, in the given order.
function(canon_test_require_cxx_compile_options TARGET)
    get_property(_options TARGET "${TARGET}" PROPERTY COMPILE_OPTIONS)
    set(_previous_index -1)
    foreach(_option IN LISTS ARGN)
        list(FIND _options "$<$<COMPILE_LANGUAGE:CXX>:${_option}>" _index)
        if("${_index}" EQUAL -1)
            message(FATAL_ERROR "${TARGET} COMPILE_OPTIONS is missing '${_option}'")
        endif()
        if("${_index}" LESS_EQUAL "${_previous_index}")
            message(FATAL_ERROR "${TARGET} compile option '${_option}' must follow '${_previous_option}'")
        endif()
        set(_previous_index "${_index}")
        set(_previous_option "${_option}")
    endforeach()
endfunction()

# Records what canon_test_check_install_manifest() must find after installation.
#
# PRESENT_TARGETS and ABSENT_TARGETS name shared libraries or executables in the platform runtime directory.
# ABSENT_NAMELINKS names versioned shared libraries whose development symlink must not be installed. PRESENT and ABSENT
# name paths relative to the installation prefix and may use generator expressions.
function(canon_fixture_expect_installed)
    cmake_parse_arguments(PARSE_ARGV 0 _expect "" "" "PRESENT_TARGETS;ABSENT_TARGETS;ABSENT_NAMELINKS;PRESENT;ABSENT")
    if(_expect_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "canon_fixture_expect_installed(): unexpected arguments: ${_expect_UNPARSED_ARGUMENTS}")
    endif()

    include(GNUInstallDirs)
    if(WIN32)
        set(_runtime_dir "${CMAKE_INSTALL_BINDIR}")
    else()
        set(_runtime_dir "${CMAKE_INSTALL_LIBDIR}")
    endif()

    set(_content "")
    foreach(_kind IN ITEMS PRESENT ABSENT)
        string(TOLOWER "${_kind}" _state)
        foreach(_target IN LISTS _expect_${_kind}_TARGETS)
            string(APPEND _content "${_state} ${_runtime_dir}/$<TARGET_FILE_NAME:${_target}>\n")
        endforeach()
        foreach(_path IN LISTS _expect_${_kind})
            string(APPEND _content "${_state} ${_path}\n")
        endforeach()
    endforeach()
    if(NOT WIN32)
        foreach(_target IN LISTS _expect_ABSENT_NAMELINKS)
            string(APPEND _content "absent ${CMAKE_INSTALL_LIBDIR}/$<TARGET_LINKER_FILE_NAME:${_target}>\n")
        endforeach()
    endif()
    file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/canon-install-manifest-$<CONFIG>.txt" CONTENT "${_content}")
endfunction()

if(DEFINED CANON_TEST_CASE_FILE AND NOT "${CANON_TEST_CASE_FILE}" STREQUAL "")
    include("${CANON_TEST_CASE_FILE}")
endif()
