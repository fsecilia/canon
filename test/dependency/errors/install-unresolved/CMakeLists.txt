# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)
project(CanonDependencyInstallUnresolved LANGUAGES NONE)
include("${CANON_SOURCE_DIR}/test/support/CanonSourceFixture.cmake")
canon_install_dependency(fixture-dependency TARGETS Missing::Target)
