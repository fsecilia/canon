# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

cmake_minimum_required(VERSION 3.31.6)
project(CanonTargetArguments LANGUAGES CXX)

include("${CMAKE_CURRENT_LIST_DIR}/../../../support/CanonSourceFixture.cmake")

add_library(sample STATIC sample.cpp)
canon_apply_target(sample unexpected)
