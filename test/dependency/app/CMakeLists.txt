# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Installs the vendored runtime from a subdirectory so its directory-scoped install target must build it.
canon_install_dependency(runtime TARGETS DependencyFixture::Runtime)
canon_test_require_target_property(fixture_runtime EXCLUDE_FROM_ALL TRUE)
