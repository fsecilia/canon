# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

canon_install_dependency(
    fixture-dependency
    TARGETS DependencyFixture::Runtime
)

get_target_property(_excluded dependency_fixture_runtime EXCLUDE_FROM_ALL)
if (NOT _excluded)
    message(FATAL_ERROR
        "canon_install_dependency() changed the vendored target's EXCLUDE_FROM_ALL property")
endif()
