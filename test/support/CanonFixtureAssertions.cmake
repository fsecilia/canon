# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

function(canon_test_require_target_property TARGET PROPERTY EXPECTED)
    get_target_property(_actual "${TARGET}" "${PROPERTY}")
    if(NOT "${_actual}" STREQUAL "${EXPECTED}")
        message(FATAL_ERROR
            "${TARGET} property ${PROPERTY}: expected '${EXPECTED}', got '${_actual}'")
    endif()
endfunction()

function(canon_test_require_target_property_unset TARGET PROPERTY)
    get_target_property(_actual "${TARGET}" "${PROPERTY}")
    if(NOT "${_actual}" STREQUAL "_actual-NOTFOUND")
        message(FATAL_ERROR
            "${TARGET} property ${PROPERTY}: expected unset, got '${_actual}'")
    endif()
endfunction()

function(canon_test_require_target_property_empty TARGET PROPERTY)
    get_target_property(_actual "${TARGET}" "${PROPERTY}")
    if(NOT "${_actual}" STREQUAL "_actual-NOTFOUND" AND NOT "${_actual}" STREQUAL "")
        message(FATAL_ERROR
            "${TARGET} property ${PROPERTY}: expected empty or unset, got '${_actual}'")
    endif()
endfunction()

function(canon_test_require_alias ALIAS TARGET)
    if(NOT TARGET "${ALIAS}")
        message(FATAL_ERROR "Expected alias target '${ALIAS}'")
    endif()

    get_target_property(_actual "${ALIAS}" ALIASED_TARGET)
    if(NOT "${_actual}" STREQUAL "${TARGET}")
        message(FATAL_ERROR
            "Alias '${ALIAS}': expected target '${TARGET}', got '${_actual}'")
    endif()
endfunction()

function(canon_test_require_target_list_value TARGET PROPERTY VALUE)
    get_target_property(_values "${TARGET}" "${PROPERTY}")
    if("${_values}" STREQUAL "_values-NOTFOUND")
        message(FATAL_ERROR "${TARGET} has no ${PROPERTY}")
    endif()

    if(NOT "${VALUE}" IN_LIST _values)
        message(FATAL_ERROR "${TARGET} ${PROPERTY} is missing '${VALUE}'")
    endif()
endfunction()

function(canon_test_forbid_target_list_value TARGET PROPERTY VALUE)
    get_target_property(_values "${TARGET}" "${PROPERTY}")
    if(NOT "${_values}" STREQUAL "_values-NOTFOUND" AND "${VALUE}" IN_LIST _values)
        message(FATAL_ERROR "${TARGET} ${PROPERTY} unexpectedly contains '${VALUE}'")
    endif()
endfunction()

function(canon_test_require_cxx_compile_option TARGET OPTION)
    canon_test_require_target_list_value(
        "${TARGET}"
        COMPILE_OPTIONS
        "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>"
    )
endfunction()

function(canon_test_require_cxx_compile_option_after TARGET OPTION EARLIER_OPTION)
    get_target_property(_options "${TARGET}" COMPILE_OPTIONS)
    if("${_options}" STREQUAL "_options-NOTFOUND")
        message(FATAL_ERROR "${TARGET} has no COMPILE_OPTIONS")
    endif()

    set(_required "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
    set(_earlier "$<$<COMPILE_LANGUAGE:CXX>:${EARLIER_OPTION}>")
    list(FIND _options "${_required}" _required_index)
    list(FIND _options "${_earlier}" _earlier_index)

    if("${_required_index}" EQUAL -1)
        message(FATAL_ERROR "${TARGET} COMPILE_OPTIONS is missing '${_required}'")
    endif()
    if("${_earlier_index}" EQUAL -1)
        message(FATAL_ERROR "${TARGET} COMPILE_OPTIONS is missing '${_earlier}'")
    endif()
    if("${_required_index}" LESS_EQUAL "${_earlier_index}")
        message(FATAL_ERROR
            "${TARGET} compile option '${OPTION}' must follow '${EARLIER_OPTION}'")
    endif()
endfunction()
