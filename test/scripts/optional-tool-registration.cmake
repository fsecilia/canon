# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

foreach(_required_variable
    CANON_CTEST_COMMAND
    CANON_TEST_ROOT
)
    if (NOT DEFINED ${_required_variable} OR "${${_required_variable}}" STREQUAL "")
        message(FATAL_ERROR "${_required_variable} is required")
    endif()
endforeach()

execute_process(
    COMMAND "${CANON_CTEST_COMMAND}" --test-dir "${CANON_TEST_ROOT}" --show-only=json-v1
    RESULT_VARIABLE _ctest_result
    OUTPUT_VARIABLE _ctest_json
    ERROR_VARIABLE _ctest_stderr
)
if (NOT _ctest_result EQUAL 0)
    message(FATAL_ERROR
        "CTest inventory query failed\n"
        "${_ctest_stderr}")
endif()

function(_canon_require_test_state NAME EXPECT_ENABLED)
    string(JSON _test_count LENGTH "${_ctest_json}" tests)
    math(EXPR _last_test "${_test_count} - 1")

    set(_found FALSE)
    set(_disabled FALSE)
    foreach(_test_index RANGE 0 ${_last_test})
        string(JSON _test_name GET "${_ctest_json}" tests ${_test_index} name)
        if (NOT "${_test_name}" STREQUAL "${NAME}")
            continue()
        endif()

        set(_found TRUE)
        string(JSON _property_count LENGTH "${_ctest_json}" tests ${_test_index} properties)
        if (_property_count GREATER 0)
            math(EXPR _last_property "${_property_count} - 1")
            foreach(_property_index RANGE 0 ${_last_property})
                string(JSON _property_name
                    GET "${_ctest_json}" tests ${_test_index} properties ${_property_index} name)
                if ("${_property_name}" STREQUAL "DISABLED")
                    string(JSON _disabled
                        GET "${_ctest_json}" tests ${_test_index} properties ${_property_index} value)
                    break()
                endif()
            endforeach()
        endif()
        break()
    endforeach()

    if (NOT _found)
        message(FATAL_ERROR "optional test '${NAME}' is missing from the CTest inventory")
    endif()

    if (EXPECT_ENABLED AND _disabled)
        message(FATAL_ERROR "available optional test '${NAME}' is disabled")
    endif()
    if (NOT EXPECT_ENABLED AND NOT _disabled)
        message(FATAL_ERROR "unavailable optional test '${NAME}' is not disabled")
    endif()
endfunction()

if (DEFINED CANON_EXPECT_COVERAGE_ENABLED)
    foreach(_test IN ITEMS
        canon.integration.coverage
        canon.integration.coverage.empty-report
        canon.integration.presets.coverage
    )
        _canon_require_test_state("${_test}" "${CANON_EXPECT_COVERAGE_ENABLED}")
    endforeach()
endif()

if (DEFINED CANON_EXPECT_TIDY_ENABLED)
    foreach(_test IN ITEMS
        canon.integration.tidy
        canon.integration.presets.tidy
    )
        _canon_require_test_state("${_test}" "${CANON_EXPECT_TIDY_ENABLED}")
    endforeach()
endif()

if (DEFINED CANON_EXPECT_DOCUMENTATION_ENABLED)
    foreach(_test IN ITEMS
        canon.integration.documentation
        canon.integration.documentation.install
        canon.integration.documentation.nested
        canon.integration.documentation-warning
    )
        _canon_require_test_state("${_test}" "${CANON_EXPECT_DOCUMENTATION_ENABLED}")
    endforeach()
endif()
