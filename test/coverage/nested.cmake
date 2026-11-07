# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Proves report exclusions respect every Canon project in the build, not only the top-level one.

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

# Runs the coverage lifecycle for one layout and checks which sources the report names.
function(_check_layout NAME FIXTURE)
    cmake_parse_arguments(PARSE_ARGV 2 _layout "" "" "ARGS;REPORTED;EXCLUDED")
    set(_build "${CANON_TEST_BINARY_DIR}/${NAME}")
    canon_test_configure(SOURCE "${CANON_SOURCE_DIR}/test/coverage/${FIXTURE}" BINARY "${_build}" ARGS ${_layout_ARGS})
    canon_test_build(BINARY "${_build}")
    canon_test_ctest(BINARY "${_build}")
    canon_test_build(BINARY "${_build}" TARGET coverage-report)

    canon_test_read_files(_report "${_build}/coverage" index.html)
    foreach(_source IN LISTS _layout_REPORTED)
        canon_test_require_matches("${_report}" "${NAME} coverage report" "[\">/]${_source}\\.cpp")
    endforeach()
    foreach(_source IN LISTS _layout_EXCLUDED)
        canon_test_forbid_matches("${_report}" "${NAME} coverage report" "[\">/]${_source}\\.cpp")
    endforeach()
endfunction()

_check_layout(root-first nested
    ARGS -DCANON_TEST_COVERAGE_CHILD_FIRST=OFF
    REPORTED root child
    EXCLUDED root_vendor child_vendor
)
_check_layout(child-first nested
    ARGS -DCANON_TEST_COVERAGE_CHILD_FIRST=ON
    REPORTED root child
    EXCLUDED root_vendor child_vendor
)
_check_layout(owner owner
    REPORTED root owned
    EXCLUDED owned_vendor
)
