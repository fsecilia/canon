# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

# Configure the shared package fixture from a clean build tree.
function(_canon_configure_package_fixture BUILD_DIR)
    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/package-install"
        -B "${BUILD_DIR}"
        -G "${CANON_GENERATOR}"
        "-DCANON_SOURCE_DIR=${CANON_SOURCE_DIR}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
        -DCMAKE_INSTALL_LIBDIR=artifact-lib
    )
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    execute_process(
        COMMAND ${_configure_command}
        RESULT_VARIABLE _configure_result
        OUTPUT_VARIABLE _configure_stdout
        ERROR_VARIABLE _configure_stderr
    )
    if (NOT _configure_result EQUAL 0)
        message(FATAL_ERROR
            "Canon package fixture configure failed\n"
            "stdout:\n${_configure_stdout}\n"
            "stderr:\n${_configure_stderr}")
    endif()
endfunction()

# Configure and build one consumer against an installed generated package.
function(_canon_build_package_consumer INSTALL_PREFIX NAME VERSION TARGET ABSENT_TARGET)
    string(MAKE_C_IDENTIFIER "${NAME}_${TARGET}" _consumer_name)
    set(_build_dir "${CANON_TEST_BINARY_DIR}/consumer-${_consumer_name}")

    set(_configure_command
        "${CMAKE_COMMAND}"
        -S "${CANON_SOURCE_DIR}/test/package-consumer"
        -B "${_build_dir}"
        -G "${CANON_GENERATOR}"
        "-DCANON_PACKAGE_NAME=${NAME}"
        "-DCANON_PACKAGE_TARGET=${TARGET}"
        "-D${NAME}_DIR=${INSTALL_PREFIX}/artifact-lib/cmake/${NAME}"
        "-DCMAKE_CXX_COMPILER=${CANON_CXX_COMPILER}"
        -DCMAKE_BUILD_TYPE=Debug
    )
    if (NOT "${VERSION}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_PACKAGE_VERSION=${VERSION}")
    endif()
    if (NOT "${ABSENT_TARGET}" STREQUAL "")
        list(APPEND _configure_command "-DCANON_ABSENT_TARGET=${ABSENT_TARGET}")
    endif()
    if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
        list(APPEND _configure_command "-DCMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
    endif()

    execute_process(
        COMMAND ${_configure_command}
        RESULT_VARIABLE _configure_result
        OUTPUT_VARIABLE _configure_stdout
        ERROR_VARIABLE _configure_stderr
    )
    if (NOT _configure_result EQUAL 0)
        message(FATAL_ERROR
            "Consumer for ${NAME} failed to configure\n"
            "stdout:\n${_configure_stdout}\n"
            "stderr:\n${_configure_stderr}")
    endif()

    execute_process(
        COMMAND "${CMAKE_COMMAND}" --build "${_build_dir}"
        RESULT_VARIABLE _build_result
        OUTPUT_VARIABLE _build_stdout
        ERROR_VARIABLE _build_stderr
    )
    if (NOT _build_result EQUAL 0)
        message(FATAL_ERROR
            "Consumer for ${NAME} failed to build\n"
            "stdout:\n${_build_stdout}\n"
            "stderr:\n${_build_stderr}")
    endif()
endfunction()

# Load a generated version file with a normal architecture and version request.
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

# Load a version file with a deliberately incompatible pointer width.
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
