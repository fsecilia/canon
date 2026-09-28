# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

option(CANON_ENABLE_ASAN "Enable AddressSanitizer on Canon-managed targets." OFF)
option(CANON_ENABLE_COVERAGE "Enable coverage instrumentation on Canon-managed targets." OFF)
option(CANON_ENABLE_TIDY "Run clang-tidy as part of compiling Canon-managed targets." OFF)
option(CANON_ENABLE_WARNINGS "Enable Canon's strict compiler warnings." OFF)

function(_canon_apply_cxx_option TARGET OPTION)
    target_compile_options("${TARGET}" PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
endfunction()

# Applies the compiler-specific build policy shared by Canon-managed compiled targets.
function(_canon_apply_compiler_policy TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(_build_options
            -fdiagnostics-color=always
            -fstrict-aliasing
            -fsized-deallocation
            -ftemplate-backtrace-limit=1
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(_build_options
            -fcolor-diagnostics
            -fstrict-aliasing
            -fsized-deallocation
        )
    else()
        message(FATAL_ERROR
            "Canon does not provide compiler policy for '${CMAKE_CXX_COMPILER_ID}'")
    endif()

    foreach(_option IN LISTS _build_options)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()
endfunction()

# Enables Release IPO when the active C++ toolchain supports it.
function(_canon_apply_ipo_if_supported TARGET)
    get_property(_ipo_supported GLOBAL PROPERTY _CANON_IPO_SUPPORTED)
    if ("${_ipo_supported}" STREQUAL "")
        include(CheckIPOSupported)
        check_ipo_supported(
            RESULT _ipo_supported
            OUTPUT _ipo_output
            LANGUAGES CXX
        )
        set_property(GLOBAL PROPERTY _CANON_IPO_SUPPORTED "${_ipo_supported}")

        if (NOT _ipo_supported)
            message(STATUS "Canon: IPO is unavailable; Release builds will continue without it")
            message(VERBOSE "Canon IPO probe failed:\n${_ipo_output}")
        endif()
    endif()

    if (_ipo_supported)
        set_property(
            TARGET "${TARGET}"
            PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
        )
    endif()
endfunction()

# Applies Canon's strict compiler-specific warning policy.
function(_canon_apply_warnings TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(_warning_options
            -Wall
            -Wextra
            -Wpedantic
            -Werror
            -Wstrict-aliasing=2
            -Wdouble-promotion
            -Wfloat-conversion
            -Wshadow
        )
        set(_warning_suppressions)
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(_warning_options
            -Weverything
            -Werror
            -Wswitch
            -Wdouble-promotion
            -Wfloat-conversion
            -Wshadow-all
        )
        set(_warning_suppressions
            -Wno-c++98-compat
        )
    else()
        message(FATAL_ERROR
            "Canon does not provide warning policy for '${CMAKE_CXX_COMPILER_ID}'")
    endif()

    foreach(_option IN LISTS _warning_options _warning_suppressions)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()
endfunction()

# Adds AddressSanitizer instrumentation to managed C++ compilation and linking.
function(_canon_apply_asan TARGET)
    _canon_apply_cxx_option("${TARGET}" "-fsanitize=address")
    _canon_apply_cxx_option("${TARGET}" "-fno-omit-frame-pointer")
    target_link_options("${TARGET}" PRIVATE -fsanitize=address)
endfunction()

# Selects the compiler-matched gcov backend used by gcovr.
function(_canon_find_coverage_backend OUT_COMMAND)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        if (NOT CANON_GCOV_EXECUTABLE)
            execute_process(
                COMMAND "${CMAKE_CXX_COMPILER}" -print-prog-name=gcov
                OUTPUT_VARIABLE _gcov_candidate
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY
            )
            if (IS_ABSOLUTE "${_gcov_candidate}" AND EXISTS "${_gcov_candidate}")
                set(
                    CANON_GCOV_EXECUTABLE
                    "${_gcov_candidate}"
                    CACHE FILEPATH "gcov executable used by Canon coverage"
                )
            else()
                find_program(
                    CANON_GCOV_EXECUTABLE
                    NAMES "${_gcov_candidate}" gcov
                    REQUIRED
                    DOC "gcov executable used by Canon coverage"
                )
            endif()
        endif()
        set(${OUT_COMMAND} "${CANON_GCOV_EXECUTABLE}" PARENT_SCOPE)
        return()
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        get_filename_component(_compiler_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
        find_program(
            CANON_LLVM_COV_EXECUTABLE
            NAMES llvm-cov
            HINTS "${_compiler_dir}"
            REQUIRED
            DOC "llvm-cov executable used by Canon coverage"
        )
        set(${OUT_COMMAND} "${CANON_LLVM_COV_EXECUTABLE} gcov" PARENT_SCOPE)
        return()
    endif()

    message(FATAL_ERROR
        "Canon coverage does not support compiler '${CMAKE_CXX_COMPILER_ID}'")
endfunction()

# Creates cleanup and report targets for the top-level project that owns the coverage build.
function(_canon_add_coverage_targets)
    find_program(
        CANON_GCOVR_EXECUTABLE
        NAMES gcovr
        REQUIRED
        DOC "gcovr executable used by Canon coverage"
    )
    _canon_find_coverage_backend(_gcov_command)

    add_custom_target(
        coverage-clean
        COMMAND
            "${CMAKE_COMMAND}"
            "-DCANON_COVERAGE_BINARY_DIR=${CMAKE_BINARY_DIR}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CanonCoverageClean.cmake"
        COMMENT "Cleaning coverage data"
        VERBATIM
    )

    set(_output_dir "${CMAKE_BINARY_DIR}/coverage")
    add_custom_target(
        coverage-report
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${_output_dir}"
        COMMAND
            "${CANON_GCOVR_EXECUTABLE}"
            --root "${CMAKE_SOURCE_DIR}"
            "${CMAKE_BINARY_DIR}"
            --gcov-executable "${_gcov_command}"
            --exclude ".*_test\\.cpp$"
            --exclude ".*/external/.*"
            --html-details "${_output_dir}/index.html"
            --delete
            --print-summary
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        COMMENT "Generating coverage report"
        USES_TERMINAL
        VERBATIM
    )
endfunction()

# Adds gcov-compatible instrumentation and top-level reporting helpers.
function(_canon_apply_coverage TARGET)
    _canon_apply_cxx_option("${TARGET}" "--coverage")
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        _canon_apply_cxx_option("${TARGET}" "-fprofile-abs-path")
    endif()
    target_link_options("${TARGET}" PRIVATE --coverage)

    if (PROJECT_IS_TOP_LEVEL)
        get_property(_targets_added GLOBAL PROPERTY _CANON_COVERAGE_TARGETS_ADDED)
        if (NOT _targets_added)
            _canon_add_coverage_targets()
            set_property(GLOBAL PROPERTY _CANON_COVERAGE_TARGETS_ADDED TRUE)
        endif()
    endif()
endfunction()

# Lets CMake drive clang-tidy with the real compile command for each source file.
function(_canon_apply_tidy TARGET)
    find_program(
        CANON_CLANG_TIDY_EXECUTABLE
        NAMES clang-tidy
        REQUIRED
        DOC "clang-tidy executable used by Canon"
    )
    set_property(TARGET "${TARGET}" PROPERTY CXX_CLANG_TIDY "${CANON_CLANG_TIDY_EXECUTABLE}")
endfunction()

# Applies Canon's private build policy to a target that compiles C++ sources.
function(canon_apply_target TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_target(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT _type STREQUAL "EXECUTABLE"
        AND NOT _type STREQUAL "STATIC_LIBRARY"
        AND NOT _type STREQUAL "SHARED_LIBRARY"
        AND NOT _type STREQUAL "MODULE_LIBRARY"
        AND NOT _type STREQUAL "OBJECT_LIBRARY")
        message(FATAL_ERROR
            "canon_apply_target(): target '${TARGET}' has type '${_type}', which has no compiled-target Canon policy")
    endif()

    set_target_properties("${TARGET}" PROPERTIES
        CXX_SCAN_FOR_MODULES FALSE
        CXX_STANDARD 26
        CXX_STANDARD_REQUIRED TRUE
        POSITION_INDEPENDENT_CODE TRUE
        VISIBILITY_INLINES_HIDDEN TRUE
        CXX_VISIBILITY_PRESET hidden
    )

    _canon_apply_compiler_policy("${TARGET}")
    _canon_apply_ipo_if_supported("${TARGET}")
    if (CANON_ENABLE_WARNINGS)
        _canon_apply_warnings("${TARGET}")
    endif()
    if (CANON_ENABLE_ASAN)
        _canon_apply_asan("${TARGET}")
    endif()
    if (CANON_ENABLE_COVERAGE)
        _canon_apply_coverage("${TARGET}")
    endif()
    if (CANON_ENABLE_TIDY)
        _canon_apply_tidy("${TARGET}")
    endif()
endfunction()

# Returns the conventional install directory for this project's CMake package files.
function(_canon_package_install_directory OUT_DIRECTORY)
    include(GNUInstallDirs)
    set(
        "${OUT_DIRECTORY}"
        "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
        PARENT_SCOPE
    )
endfunction()

# Selects Canon's package compatibility policy from the project's major version.
function(_canon_package_version_compatibility OUT_COMPATIBILITY)
    if (PROJECT_VERSION_MAJOR EQUAL 0)
        set(_compatibility SameMinorVersion)
    else()
        set(_compatibility SameMajorVersion)
    endif()
    set("${OUT_COMPATIBILITY}" "${_compatibility}" PARENT_SCOPE)
endfunction()

# Regenerates the package version file from the project's current install policy.
function(_canon_write_package_version_file)
    if ("${PROJECT_VERSION}" STREQUAL "")
        return()
    endif()

    get_property(
        _package_registered
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_REGISTERED
    )
    if (NOT _package_registered)
        return()
    endif()

    _canon_package_version_compatibility(_compatibility)

    get_property(
        _has_binary
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_HAS_BINARY
    )
    set(_architecture_arguments)
    if (NOT _has_binary)
        list(APPEND _architecture_arguments ARCH_INDEPENDENT)
    endif()

    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
        "${PROJECT_BINARY_DIR}/canon/package/${PROJECT_NAME}ConfigVersion.cmake"
        VERSION "${PROJECT_VERSION}"
        COMPATIBILITY "${_compatibility}"
        ${_architecture_arguments}
    )
endfunction()

# Records that this project's installed package contains an architecture-specific artifact.
function(_canon_mark_package_binary)
    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_HAS_BINARY TRUE
    )
    _canon_write_package_version_file()
endfunction()

# Quotes one argument for a generated CMake package configuration call.
function(_canon_quote_package_argument OUT_ARGUMENT ARGUMENT)
    string(REPLACE "\\" "\\\\" _argument "${ARGUMENT}")
    string(REPLACE "\"" "\\\"" _argument "${_argument}")
    string(REPLACE "$" "\$" _argument "${_argument}")
    set("${OUT_ARGUMENT}" "\"${_argument}\"" PARENT_SCOPE)
endfunction()

# Formats one find_dependency() call for the generated package configuration.
function(_canon_format_package_dependency OUT_CALL PACKAGE)
    _canon_quote_package_argument(_package "${PACKAGE}")
    set(_call "find_dependency(${_package}")
    foreach(_argument IN LISTS ARGN)
        _canon_quote_package_argument(_argument "${_argument}")
        string(APPEND _call " ${_argument}")
    endforeach()
    string(APPEND _call ")")
    set("${OUT_CALL}" "${_call}" PARENT_SCOPE)
endfunction()

# Writes this project's relocatable CMake package configuration.
function(_canon_write_package_config_file)
    set(_package_dir "${PROJECT_BINARY_DIR}/canon/package")
    file(MAKE_DIRECTORY "${_package_dir}")

    set(CANON_PACKAGE_DEPENDENCIES "")
    get_property(
        _dependency_keys
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_DEPENDENCY_KEYS
    )
    if (_dependency_keys)
        string(APPEND CANON_PACKAGE_DEPENDENCIES "include(CMakeFindDependencyMacro)\n\n")
        foreach(_dependency_key IN LISTS _dependency_keys)
            get_property(
                _dependency_call
                DIRECTORY "${PROJECT_SOURCE_DIR}"
                PROPERTY "_CANON_PACKAGE_DEPENDENCY_${_dependency_key}"
            )
            string(APPEND CANON_PACKAGE_DEPENDENCIES "${_dependency_call}\n")
        endforeach()
        string(APPEND CANON_PACKAGE_DEPENDENCIES "\n")
    endif()

    set(_config_input "${_package_dir}/${PROJECT_NAME}Config.cmake.in")
    file(WRITE "${_config_input}" [=[@PACKAGE_INIT@

@CANON_PACKAGE_DEPENDENCIES@
include("${CMAKE_CURRENT_LIST_DIR}/@CANON_PACKAGE_TARGETS_FILE@")

check_required_components(@CANON_PACKAGE_NAME@)
]=])

    set(CANON_PACKAGE_NAME "${PROJECT_NAME}")
    set(CANON_PACKAGE_TARGETS_FILE "${PROJECT_NAME}Targets.cmake")
    _canon_package_install_directory(_install_directory)

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        "${_config_input}"
        "${_package_dir}/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION "${_install_directory}"
        NO_SET_AND_CHECK_MACRO
    )
endfunction()

# Registers the project-wide export and package configuration for managed libraries.
function(_canon_register_package)
    get_property(
        _package_registered
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_REGISTERED
    )
    if (_package_registered)
        return()
    endif()

    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_REGISTERED TRUE
    )

    _canon_package_install_directory(_install_directory)
    _canon_write_package_config_file()
    _canon_write_package_version_file()

    install(
        EXPORT "${PROJECT_NAME}Targets"
        FILE "${PROJECT_NAME}Targets.cmake"
        NAMESPACE "${PROJECT_NAME}::"
        DESTINATION "${_install_directory}"
    )

    set(_package_files
        "${PROJECT_BINARY_DIR}/canon/package/${PROJECT_NAME}Config.cmake"
    )
    if (NOT "${PROJECT_VERSION}" STREQUAL "")
        list(APPEND _package_files
            "${PROJECT_BINARY_DIR}/canon/package/${PROJECT_NAME}ConfigVersion.cmake"
        )
    endif()
    install(FILES ${_package_files} DESTINATION "${_install_directory}")
endfunction()

# Records how this project's installed package recovers one external dependency.
function(canon_apply_dependency PACKAGE)
    if ("${PACKAGE}" STREQUAL "")
        message(FATAL_ERROR "canon_apply_dependency(): package name must not be empty")
    endif()

    foreach(_argument IN LISTS ARGN)
        if (_argument STREQUAL "REQUIRED" OR _argument STREQUAL "QUIET")
            message(FATAL_ERROR
                "canon_apply_dependency(): '${_argument}' is inherited from the outer find_package() call")
        endif()
    endforeach()

    _canon_format_package_dependency(_dependency_call "${PACKAGE}" ${ARGN})
    string(SHA256 _dependency_key "${_dependency_call}")
    set(_dependency_property "_CANON_PACKAGE_DEPENDENCY_${_dependency_key}")

    get_property(
        _dependency_recorded
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY "${_dependency_property}"
        SET
    )
    if (_dependency_recorded)
        get_property(
            _existing_call
            DIRECTORY "${PROJECT_SOURCE_DIR}"
            PROPERTY "${_dependency_property}"
        )
        if (NOT _existing_call STREQUAL _dependency_call)
            message(FATAL_ERROR
                "canon_apply_dependency(): internal dependency-key collision for package '${PACKAGE}'")
        endif()
        return()
    endif()

    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        APPEND PROPERTY _CANON_PACKAGE_DEPENDENCY_KEYS "${_dependency_key}"
    )
    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY "${_dependency_property}" "${_dependency_call}"
    )

    get_property(
        _package_registered
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_REGISTERED
    )
    if (_package_registered)
        _canon_write_package_config_file()
    endif()
endfunction()

# Applies Canon's compiled-target policy and conventional installation to an executable.
function(canon_apply_executable TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_executable(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT _type STREQUAL "EXECUTABLE")
        message(FATAL_ERROR
            "canon_apply_executable(): target '${TARGET}' must be an executable")
    endif()

    get_target_property(_macosx_bundle "${TARGET}" MACOSX_BUNDLE)
    if (_macosx_bundle)
        message(FATAL_ERROR
            "canon_apply_executable(): MACOSX_BUNDLE target '${TARGET}' is not supported")
    endif()

    canon_apply_target("${TARGET}")

    include(GNUInstallDirs)
    install(
        TARGETS "${TARGET}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    )
    _canon_mark_package_binary()
endfunction()

# Installs a managed library and each of its public HEADERS file sets.
function(_canon_install_library TARGET)
    include(GNUInstallDirs)

    get_property(_header_sets TARGET "${TARGET}" PROPERTY INTERFACE_HEADER_SETS)
    set(_file_set_arguments)
    foreach(_header_set IN LISTS _header_sets)
        list(APPEND _file_set_arguments
            FILE_SET "${_header_set}"
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        )
    endforeach()

    install(
        TARGETS "${TARGET}"
        EXPORT "${PROJECT_NAME}Targets"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        ${_file_set_arguments}
    )
endfunction()

# Applies Canon's library policy and conventional installation to a library.
function(canon_apply_library TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_library(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT _type STREQUAL "STATIC_LIBRARY"
        AND NOT _type STREQUAL "SHARED_LIBRARY"
        AND NOT _type STREQUAL "MODULE_LIBRARY"
        AND NOT _type STREQUAL "INTERFACE_LIBRARY")
        message(FATAL_ERROR
            "canon_apply_library(): target '${TARGET}' must be a STATIC, SHARED, MODULE, or INTERFACE library")
    endif()

    get_target_property(_framework "${TARGET}" FRAMEWORK)
    if (_framework)
        message(FATAL_ERROR
            "canon_apply_library(): FRAMEWORK target '${TARGET}' is not supported")
    endif()

    if (_type STREQUAL "INTERFACE_LIBRARY")
        target_compile_features("${TARGET}" INTERFACE cxx_std_26)
        _canon_install_library("${TARGET}")
        _canon_register_package()
        return()
    endif()

    _canon_mark_package_binary()
    canon_apply_target("${TARGET}")
    target_compile_features("${TARGET}" PUBLIC cxx_std_26)

    string(MAKE_C_IDENTIFIER "${TARGET}" _api_name)
    string(TOLOWER "${_api_name}" _api_name)

    include(GenerateExportHeader)
    get_target_property(_target_binary_dir "${TARGET}" BINARY_DIR)
    set(_include_dir "${_target_binary_dir}/canon/include")
    set(_header "${_include_dir}/${TARGET}/export.hpp")
    file(MAKE_DIRECTORY "${_include_dir}/${TARGET}")

    generate_export_header(
        "${TARGET}"
        EXPORT_FILE_NAME "${_header}"
        EXPORT_MACRO_NAME "${_api_name}_api"
    )
    target_sources(
        "${TARGET}"
        PUBLIC
            FILE_SET canon_export_header
            TYPE HEADERS
            BASE_DIRS "${_include_dir}"
            FILES "${_header}"
    )

    _canon_install_library("${TARGET}")
    _canon_register_package()
endfunction()

# Adds conventional documentation targets using CMake's native FindDoxygen integration.
function(canon_add_documentation)
    include(GNUInstallDirs)
    find_package(Doxygen 1.9 QUIET OPTIONAL_COMPONENTS dot)

    set(_output_directory "${PROJECT_BINARY_DIR}/doxygen")
    set(_warning_log "${PROJECT_BINARY_DIR}/doxygen-warnings.log")

    install(
        DIRECTORY "${_output_directory}/html/"
        TYPE DOC
        COMPONENT Documentation
        EXCLUDE_FROM_ALL
    )

    add_custom_target(
        doc-clean
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${_output_directory}"
        COMMAND "${CMAKE_COMMAND}" -E rm -f "${_warning_log}"
        COMMENT "Cleaning generated API documentation"
        VERBATIM
    )

    if (NOT Doxygen_FOUND)
        add_custom_target(
            doc
            COMMAND
                "${CMAKE_COMMAND}" -E echo
                "Doxygen 1.9 or newer was not found when this build tree was configured."
            COMMAND
                "${CMAKE_COMMAND}" -E echo
                "Install Doxygen 1.9 or newer and reconfigure before building the doc target."
            COMMAND "${CMAKE_COMMAND}" -E false
            COMMENT "Unable to generate API documentation"
            VERBATIM
        )
        return()
    endif()

    set(_readme "${PROJECT_SOURCE_DIR}/README.md")
    if (EXISTS "${_readme}")
        set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${_readme}")
    endif()

    set(DOXYGEN_OUTPUT_DIRECTORY "${_output_directory}")
    set(DOXYGEN_EXCLUDE
        "${PROJECT_BINARY_DIR}"
        "${PROJECT_SOURCE_DIR}/build"
        "${PROJECT_SOURCE_DIR}/external"
        "${PROJECT_SOURCE_DIR}/standards"
        "${PROJECT_SOURCE_DIR}/test"
    )
    set(DOXYGEN_EXCLUDE_PATTERNS "*_test.cpp")
    set(DOXYGEN_STRIP_FROM_PATH "${PROJECT_SOURCE_DIR}")
    set(DOXYGEN_QUIET YES)
    set(DOXYGEN_WARN_AS_ERROR FAIL_ON_WARNINGS)
    set(DOXYGEN_WARN_LOGFILE "${_warning_log}")
    set(DOXYGEN_JAVADOC_AUTOBRIEF YES)
    set(DOXYGEN_QT_AUTOBRIEF YES)
    set(DOXYGEN_ENABLE_PREPROCESSING YES)
    set(DOXYGEN_EXTRACT_ALL NO)
    set(DOXYGEN_EXCLUDE_SYMBOLS "*::detail*")

    doxygen_add_docs(
        doc
        "${PROJECT_SOURCE_DIR}"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        COMMENT "Generating API documentation"
    )
endfunction()
