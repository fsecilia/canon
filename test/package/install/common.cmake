# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_GENERATOR
    CANON_CXX_COMPILER
)

function(_canon_configure_package_fixture BUILD_DIR)
    canon_test_make_configure_command(
        _configure_command
        "${CANON_SOURCE_DIR}/test/package/install"
        "${BUILD_DIR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCMAKE_INSTALL_LIBDIR=artifact-lib
        -DCMAKE_INSTALL_DATADIR=artifact-data
    )
    list(APPEND _configure_command ${ARGN})

    canon_test_run(
        DESCRIPTION "Canon package fixture configure"
        COMMAND ${_configure_command}
    )
endfunction()

function(_canon_install_package_fixture BUILD_DIR INSTALL_PREFIX)
    canon_test_run(
        DESCRIPTION "Canon package fixture build"
        COMMAND "${CMAKE_COMMAND}" --build "${BUILD_DIR}"
    )
    canon_test_run(
        DESCRIPTION "Canon package fixture install"
        COMMAND "${CMAKE_COMMAND}" --install "${BUILD_DIR}" --prefix "${INSTALL_PREFIX}"
    )
endfunction()

function(
    _canon_build_package_consumer
    INSTALL_PREFIX
    PACKAGE_DIRECTORY
    NAME
    VERSION
    TARGET
    ABSENT_TARGET
)
    string(MAKE_C_IDENTIFIER "${NAME}_${TARGET}" _consumer_name)
    set(_build_dir "${CANON_TEST_BINARY_DIR}/consumer-${_consumer_name}")

    set(_consumer_arguments
        "-DCANON_PACKAGE_NAME=${NAME}"
        "-DCANON_PACKAGE_TARGET=${TARGET}"
        "-D${NAME}_DIR=${INSTALL_PREFIX}/${PACKAGE_DIRECTORY}/${NAME}"
        -DCMAKE_BUILD_TYPE=Debug
    )
    if (NOT "${VERSION}" STREQUAL "")
        list(APPEND _consumer_arguments "-DCANON_PACKAGE_VERSION=${VERSION}")
    endif()
    if (NOT "${ABSENT_TARGET}" STREQUAL "")
        list(APPEND _consumer_arguments "-DCANON_ABSENT_TARGET=${ABSENT_TARGET}")
    endif()
    list(APPEND _consumer_arguments ${ARGN})
    canon_test_make_configure_command(
        _configure_command
        "${CANON_SOURCE_DIR}/test/package/consumer"
        "${_build_dir}"
        ${_consumer_arguments}
    )

    canon_test_run(
        DESCRIPTION "Consumer for ${NAME} configure"
        COMMAND ${_configure_command}
    )
    canon_test_run(
        DESCRIPTION "Consumer for ${NAME} build"
        COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
    )
endfunction()

function(_canon_check_package_version VERSION_FILE REQUEST EXPECT_COMPATIBLE)
    set(PACKAGE_FIND_VERSION "${REQUEST}")
    string(REPLACE "." ";" _version_parts "${REQUEST}")
    list(GET _version_parts 0 PACKAGE_FIND_VERSION_MAJOR)
    list(GET _version_parts 1 PACKAGE_FIND_VERSION_MINOR)
    set(PACKAGE_FIND_VERSION_RANGE "")
    unset(PACKAGE_VERSION_COMPATIBLE)
    unset(PACKAGE_VERSION_UNSUITABLE)

    include("${VERSION_FILE}")

    if (EXPECT_COMPATIBLE AND NOT PACKAGE_VERSION_COMPATIBLE)
        message(FATAL_ERROR "${VERSION_FILE} rejected compatible version '${REQUEST}'")
    endif()
    if (NOT EXPECT_COMPATIBLE AND PACKAGE_VERSION_COMPATIBLE)
        message(FATAL_ERROR "${VERSION_FILE} accepted incompatible version '${REQUEST}'")
    endif()
endfunction()

function(_canon_check_package_architecture VERSION_FILE REQUEST EXPECT_UNSUITABLE)
    set(PACKAGE_FIND_VERSION "${REQUEST}")
    string(REPLACE "." ";" _version_parts "${REQUEST}")
    list(GET _version_parts 0 PACKAGE_FIND_VERSION_MAJOR)
    list(GET _version_parts 1 PACKAGE_FIND_VERSION_MINOR)
    set(PACKAGE_FIND_VERSION_RANGE "")
    set(CMAKE_SIZEOF_VOID_P 99)
    unset(PACKAGE_VERSION_UNSUITABLE)

    include("${VERSION_FILE}")

    if (EXPECT_UNSUITABLE AND NOT PACKAGE_VERSION_UNSUITABLE)
        message(FATAL_ERROR "${VERSION_FILE} did not enforce architecture compatibility")
    endif()
    if (NOT EXPECT_UNSUITABLE AND PACKAGE_VERSION_UNSUITABLE)
        message(FATAL_ERROR "${VERSION_FILE} unexpectedly enforced architecture compatibility")
    endif()
endfunction()
