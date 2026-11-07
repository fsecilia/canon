# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

set(_build "${CANON_TEST_BINARY_DIR}/build")
canon_test_configure(SOURCE "${CANON_SOURCE_DIR}/test/consumer" BINARY "${_build}")
canon_test_build(BINARY "${_build}")

canon_test_build(BINARY "${_build}" TARGET visibility_exported)
canon_test_build(
    BINARY "${_build}"
    TARGET visibility_hidden
    DESCRIPTION "link against a symbol hidden by Canon's visibility policy"
    EXPECT_FAILURE
    EXPECTED_OUTPUT sampleHiddenAnswer
    EXPECTED_REGEX "undefined reference|undefined symbol|Undefined symbols|unresolved external symbol"
)

canon_test_cache_value(_warnings "${_build}" CANON_ENABLE_WARNINGS)
if(_warnings)
    canon_test_build(
        BINARY "${_build}"
        TARGET warning_probe
        DESCRIPTION "warning probe fails under Canon's strict warnings"
        EXPECT_FAILURE
    )
    canon_test_build(BINARY "${_build}" TARGET warning_probe_demoted)
else()
    canon_test_build(BINARY "${_build}" TARGET warning_probe)
endif()
