# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

set(_CANON_MINIMUM_CMAKE_VERSION 3.31.6)
if ("${CMAKE_VERSION}" VERSION_LESS "${_CANON_MINIMUM_CMAKE_VERSION}")
    message(FATAL_ERROR
        "Canon requires CMake ${_CANON_MINIMUM_CMAKE_VERSION} or newer; "
        "found ${CMAKE_VERSION}")
endif()

include_guard(GLOBAL)

cmake_policy(PUSH)
cmake_policy(VERSION ${_CANON_MINIMUM_CMAKE_VERSION})

option(CANON_ENABLE_ASAN "Enable AddressSanitizer on Canon-managed targets." OFF)
option(CANON_ENABLE_COVERAGE "Enable coverage instrumentation on Canon-managed targets." OFF)
option(CANON_ENABLE_TIDY "Run clang-tidy as part of compiling Canon-managed targets." OFF)
option(CANON_ENABLE_WARNINGS "Enable Canon's strict compiler warnings." OFF)

set(
    CANON_GCOV_EXECUTABLE
    ""
    CACHE FILEPATH "Override the gcov executable used by Canon coverage."
)
set(
    CANON_LLVM_COV_EXECUTABLE
    ""
    CACHE FILEPATH "Override the llvm-cov executable used by Canon coverage."
)

# Reports the semantic version printed by a candidate clang-tidy executable.
function(_canon_get_clang_tidy_version EXECUTABLE OUT_VERSION)
    execute_process(
        COMMAND "${EXECUTABLE}" --version
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
    )
    if (NOT "${_result}" EQUAL 0)
        set(${OUT_VERSION} "" PARENT_SCOPE)
        return()
    endif()

    string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" _version "${_stdout}\n${_stderr}")
    set(${OUT_VERSION} "${_version}" PARENT_SCOPE)
endfunction()

function(_canon_apply_cxx_option TARGET OPTION)
    target_compile_options("${TARGET}" PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
endfunction()

# Escapes one literal value for use inside a regular expression.
function(_canon_regex_escape_literal VALUE OUT_VALUE)
    string(REGEX REPLACE "([][+.*()^$?|\\\\])" "\\\\\\1" _escaped "${VALUE}")
    set(${OUT_VALUE} "${_escaped}" PARENT_SCOPE)
endfunction()

# Reports whether the active C++ compiler accepts one optional warning flag.
function(_canon_cxx_warning_option_supported OPTION OUT_SUPPORTED)
    include(CheckCXXCompilerFlag)
    string(SHA256 _option_key
        "${CMAKE_CXX_COMPILER};${CMAKE_CXX_COMPILER_ID};${CMAKE_CXX_COMPILER_VERSION};${OPTION}")
    set(_probe_variable "_CANON_CXX_WARNING_OPTION_${_option_key}")
    check_cxx_compiler_flag("${OPTION}" "${_probe_variable}")
    set(${OUT_SUPPORTED} "${${_probe_variable}}" PARENT_SCOPE)
endfunction()

# Applies compiler-specific build options when Canon has policy for the active toolchain.
function(_canon_apply_compiler_policy TARGET)
    set(_build_options)
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        list(APPEND _build_options -fstrict-aliasing)
    elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"
        AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU")
        list(APPEND _build_options -fstrict-aliasing)
    endif()

    foreach(_option IN LISTS _build_options)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()
endfunction()

# Enables Release IPO on final-link targets when the active C++ toolchain supports it.
function(_canon_apply_ipo_if_supported TARGET)
    get_target_property(_type "${TARGET}" TYPE)
    if (NOT "${_type}" STREQUAL "EXECUTABLE"
        AND NOT "${_type}" STREQUAL "SHARED_LIBRARY"
        AND NOT "${_type}" STREQUAL "MODULE_LIBRARY")
        return()
    endif()

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

# Reports Canon's Clang warning exceptions, including options absent from older frontends.
function(_canon_get_clang_warning_policy
    OUT_SUPPRESSIONS
    OUT_OPTIONAL_SUPPRESSIONS
    OUT_REENABLES
)
    set(_suppressions
        -Wno-c++98-compat
        -Wno-c++98-compat-pedantic
        -Wno-c++20-compat
        -Wno-ctad-maybe-unsupported
        -Wno-documentation
        -Wno-documentation-unknown-command
        -Wno-exit-time-destructors
        -Wno-global-constructors
        -Wno-missing-prototypes
        -Wno-padded
        -Wno-shadow-field-in-constructor
        -Wno-switch-default
        -Wno-switch-enum
        -Wno-unused-function
        -Wno-unused-member-function
        -Wno-unused-template
    )
    set(_optional_suppressions
        -Wno-c++23-compat
        -Wno-unsafe-buffer-usage-in-libc-call
    )
    # Re-enable child groups that broader cemetery entries would otherwise disable.
    set(_reenables
        -Wshadow-field-in-constructor-modified
    )

    set(${OUT_SUPPRESSIONS} "${_suppressions}" PARENT_SCOPE)
    set(${OUT_OPTIONAL_SUPPRESSIONS} "${_optional_suppressions}" PARENT_SCOPE)
    set(${OUT_REENABLES} "${_reenables}" PARENT_SCOPE)
endfunction()

# Applies Canon's strict compiler-specific warning policy.
function(_canon_apply_warnings TARGET)
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
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
        set(_warning_reenables)
    elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"
        AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU")
        set(_warning_options
            -Weverything
            -Werror
        )
        _canon_get_clang_warning_policy(
            _warning_suppressions
            _optional_warning_suppressions
            _warning_reenables
        )
        foreach(_optional_suppression IN LISTS _optional_warning_suppressions)
            string(REGEX REPLACE "^-Wno-" "-W" _optional_warning "${_optional_suppression}")
            _canon_cxx_warning_option_supported("${_optional_warning}" _supported)
            if (_supported)
                list(APPEND _warning_suppressions "${_optional_suppression}")
            endif()
        endforeach()
    else()
        message(FATAL_ERROR
            "Canon warnings do not support compiler '${CMAKE_CXX_COMPILER_ID}' "
            "with frontend '${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}'")
    endif()

    foreach(_option IN LISTS _warning_options _warning_suppressions _warning_reenables)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()
endfunction()

# Adds AddressSanitizer instrumentation and propagates required runtime linking.
function(_canon_apply_asan TARGET)
    if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU"
        AND NOT ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"
            AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU"))
        message(FATAL_ERROR
            "Canon ASan does not support compiler '${CMAKE_CXX_COMPILER_ID}' "
            "with frontend '${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}'")
    endif()

    _canon_apply_cxx_option("${TARGET}" "-fsanitize=address")
    _canon_apply_cxx_option("${TARGET}" "-fno-omit-frame-pointer")

    get_target_property(_type "${TARGET}" TYPE)
    if ("${_type}" STREQUAL "STATIC_LIBRARY" OR "${_type}" STREQUAL "OBJECT_LIBRARY")
        target_link_options("${TARGET}" INTERFACE -fsanitize=address)
    elseif ("${_type}" STREQUAL "SHARED_LIBRARY")
        target_link_options("${TARGET}" PUBLIC -fsanitize=address)
    else()
        target_link_options("${TARGET}" PRIVATE -fsanitize=address)
    endif()
endfunction()

# Validates the family and major version reported by a coverage companion.
function(_canon_validate_coverage_version_output OUTPUT FAMILY EXPECTED_MAJOR OUT_VALID OUT_REASON)
    if ("${FAMILY}" STREQUAL "GNU")
        string(REGEX MATCH "^[^\r\n]*" _first_line "${OUTPUT}")
        string(REGEX MATCH "^gcov([ \t(]|$)" _family_match "${_first_line}")
        if ("${_family_match}" STREQUAL "")
            set(${OUT_VALID} FALSE PARENT_SCOPE)
            set(${OUT_REASON} "does not identify itself as GNU gcov" PARENT_SCOPE)
            return()
        endif()
        string(REGEX MATCH "[0-9]+(\\.[0-9]+)+" _version "${_first_line}")
    elseif ("${FAMILY}" STREQUAL "LLVM")
        string(REGEX MATCH "LLVM version[ \t]+([0-9]+(\\.[0-9]+)+)" _family_match "${OUTPUT}")
        if ("${_family_match}" STREQUAL "")
            set(${OUT_VALID} FALSE PARENT_SCOPE)
            set(${OUT_REASON} "does not identify itself as LLVM llvm-cov" PARENT_SCOPE)
            return()
        endif()
        set(_version "${CMAKE_MATCH_1}")
    else()
        message(FATAL_ERROR "Canon internal error: unknown coverage family '${FAMILY}'")
    endif()

    if ("${_version}" STREQUAL "")
        set(${OUT_VALID} FALSE PARENT_SCOPE)
        set(${OUT_REASON} "does not report a recognizable version" PARENT_SCOPE)
        return()
    endif()

    string(REGEX MATCH "^[0-9]+" _tool_major "${_version}")
    if (NOT "${_tool_major}" STREQUAL "${EXPECTED_MAJOR}")
        set(${OUT_VALID} FALSE PARENT_SCOPE)
        set(
            ${OUT_REASON}
            "reports major version ${_tool_major}, but the compiler uses major version ${EXPECTED_MAJOR}"
            PARENT_SCOPE
        )
        return()
    endif()

    set(${OUT_VALID} TRUE PARENT_SCOPE)
    set(${OUT_REASON} "" PARENT_SCOPE)
endfunction()

# Validates one candidate coverage companion executable.
function(_canon_validate_coverage_tool EXECUTABLE FAMILY EXPECTED_MAJOR OUT_VALID OUT_REASON)
    execute_process(
        COMMAND "${EXECUTABLE}" --version
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
    )
    if (NOT "${_result}" STREQUAL "0")
        set(${OUT_VALID} FALSE PARENT_SCOPE)
        set(
            ${OUT_REASON}
            "could not be executed with --version (result: ${_result})"
            PARENT_SCOPE
        )
        return()
    endif()

    set(_output "${_stdout}${_stderr}")
    _canon_validate_coverage_version_output(
        "${_output}"
        "${FAMILY}"
        "${EXPECTED_MAJOR}"
        _valid
        _reason
    )
    set(${OUT_VALID} "${_valid}" PARENT_SCOPE)
    set(${OUT_REASON} "${_reason}" PARENT_SCOPE)
endfunction()

# Resolves exactly the program name reported by the compiler driver.
function(_canon_resolve_reported_coverage_tool CANDIDATE OUT_EXECUTABLE)
    if (IS_ABSOLUTE "${CANDIDATE}")
        if (EXISTS "${CANDIDATE}" AND NOT IS_DIRECTORY "${CANDIDATE}")
            set(${OUT_EXECUTABLE} "${CANDIDATE}" PARENT_SCOPE)
        else()
            set(${OUT_EXECUTABLE} "" PARENT_SCOPE)
        endif()
        return()
    endif()

    if ("${CANDIDATE}" MATCHES "[/\\\\]")
        if (EXISTS "${CANDIDATE}" AND NOT IS_DIRECTORY "${CANDIDATE}")
            get_filename_component(_absolute_candidate "${CANDIDATE}" ABSOLUTE)
            set(${OUT_EXECUTABLE} "${_absolute_candidate}" PARENT_SCOPE)
        else()
            set(${OUT_EXECUTABLE} "" PARENT_SCOPE)
        endif()
        return()
    endif()

    set(_coverage_executable "_coverage_executable-NOTFOUND")
    find_program(_coverage_executable NAMES "${CANDIDATE}" NO_CACHE)
    if (_coverage_executable)
        set(${OUT_EXECUTABLE} "${_coverage_executable}" PARENT_SCOPE)
    else()
        set(${OUT_EXECUTABLE} "" PARENT_SCOPE)
    endif()
endfunction()

# Selects and validates the compiler-matched gcov backend used by gcovr.
function(_canon_find_coverage_backend OUT_COMMAND)
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        set(_program_name gcov)
        set(_family GNU)
        set(_override_variable CANON_GCOV_EXECUTABLE)
        set(_command_suffix "")
    elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang"
        AND "${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}" STREQUAL "GNU")
        set(_program_name llvm-cov)
        set(_family LLVM)
        set(_override_variable CANON_LLVM_COV_EXECUTABLE)
        set(_command_suffix " gcov")
    else()
        message(FATAL_ERROR
            "Canon coverage does not support compiler '${CMAKE_CXX_COMPILER_ID}' "
            "with frontend '${CMAKE_CXX_COMPILER_FRONTEND_VARIANT}'")
    endif()

    string(REGEX MATCH "^[0-9]+" _compiler_major "${CMAKE_CXX_COMPILER_VERSION}")
    if ("${_compiler_major}" STREQUAL "")
        message(FATAL_ERROR
            "Canon could not determine the major version of compiler "
            "'${CMAKE_CXX_COMPILER_VERSION}'")
    endif()

    set(_explicit_override FALSE)
    if (NOT "${${_override_variable}}" STREQUAL "")
        set(_coverage_executable "${${_override_variable}}")
        set(_explicit_override TRUE)
    endif()

    if (NOT _explicit_override)
        execute_process(
            COMMAND "${CMAKE_CXX_COMPILER}" "-print-prog-name=${_program_name}"
            RESULT_VARIABLE _driver_result
            OUTPUT_VARIABLE _reported_program
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if (NOT "${_driver_result}" STREQUAL "0" OR "${_reported_program}" STREQUAL "")
            message(WARNING
                "Canon coverage reporting is disabled: compiler '${CMAKE_CXX_COMPILER}' "
                "did not report a usable ${_program_name} companion")
            set(${OUT_COMMAND} "" PARENT_SCOPE)
            return()
        endif()

        _canon_resolve_reported_coverage_tool("${_reported_program}" _coverage_executable)
        if ("${_coverage_executable}" STREQUAL "")
            message(WARNING
                "Canon coverage reporting is disabled: compiler '${CMAKE_CXX_COMPILER}' "
                "reported '${_reported_program}' for ${_program_name}, but that exact program "
                "could not be resolved")
            set(${OUT_COMMAND} "" PARENT_SCOPE)
            return()
        endif()
    endif()

    _canon_validate_coverage_tool(
        "${_coverage_executable}"
        "${_family}"
        "${_compiler_major}"
        _valid
        _reason
    )
    if (NOT _valid)
        if (_explicit_override)
            message(FATAL_ERROR
                "Canon coverage override ${_override_variable}='${_coverage_executable}' is invalid: "
                "${_reason}")
        endif()

        message(WARNING
            "Canon coverage reporting is disabled: compiler '${CMAKE_CXX_COMPILER}' reported "
            "'${_reported_program}' for ${_program_name}; '${_coverage_executable}' ${_reason}")
        set(${OUT_COMMAND} "" PARENT_SCOPE)
        return()
    endif()

    set(${OUT_COMMAND} "${_coverage_executable}${_command_suffix}" PARENT_SCOPE)
endfunction()

# Rebuilds report exclusions from every Canon project with coverage-enabled targets.
function(_canon_update_coverage_exclusions)
    if (NOT TARGET coverage-report)
        return()
    endif()

    get_property(_project_source_dirs GLOBAL PROPERTY _CANON_COVERAGE_PROJECT_SOURCE_DIRS)
    list(SORT _project_source_dirs)

    set(_exclude_arguments)
    foreach(_project_source_dir IN LISTS _project_source_dirs)
        cmake_path(
            CONVERT "${_project_source_dir}/external"
            TO_CMAKE_PATH_LIST _external_directory
            NORMALIZE
        )

        set(_exclude_external TRUE)
        set(_protected_patterns)
        foreach(_candidate_source_dir IN LISTS _project_source_dirs)
            if ("${_candidate_source_dir}" STREQUAL "${_project_source_dir}")
                continue()
            endif()

            cmake_path(
                IS_PREFIX _external_directory "${_candidate_source_dir}"
                NORMALIZE _inside_external
            )
            if (NOT _inside_external)
                continue()
            endif()

            # A managed project that owns this external directory must remain reportable.
            if ("${_candidate_source_dir}" STREQUAL "${_external_directory}")
                set(_exclude_external FALSE)
                break()
            endif()

            # Preserve managed project subtrees while excluding their unmanaged siblings.
            cmake_path(
                RELATIVE_PATH _candidate_source_dir
                BASE_DIRECTORY "${_external_directory}"
                OUTPUT_VARIABLE _relative_source_dir
            )
            _canon_regex_escape_literal("${_relative_source_dir}" _relative_source_regex)
            list(APPEND _protected_patterns "${_relative_source_regex}(?:/|$)")
        endforeach()

        if (NOT _exclude_external)
            continue()
        endif()

        _canon_regex_escape_literal("${_external_directory}" _external_regex)
        if (_protected_patterns)
            list(JOIN _protected_patterns "|" _protected_regex)
            set(_external_regex "${_external_regex}/(?!${_protected_regex})")
        else()
            set(_external_regex "${_external_regex}/")
        endif()

        list(APPEND _exclude_arguments --exclude "${_external_regex}")
    endforeach()

    set_property(
        TARGET coverage-report
        PROPERTY _CANON_COVERAGE_EXCLUDE_ARGUMENTS "${_exclude_arguments}"
    )
endfunction()

# Registers the active project as a coverage-report source boundary.
function(_canon_register_coverage_project)
    file(REAL_PATH "${PROJECT_SOURCE_DIR}" _project_source_dir)
    cmake_path(
        CONVERT "${_project_source_dir}"
        TO_CMAKE_PATH_LIST _project_source_dir
        NORMALIZE
    )

    get_property(_project_source_dirs GLOBAL PROPERTY _CANON_COVERAGE_PROJECT_SOURCE_DIRS)
    if ("${_project_source_dir}" IN_LIST _project_source_dirs)
        return()
    endif()

    list(APPEND _project_source_dirs "${_project_source_dir}")
    set_property(
        GLOBAL
        PROPERTY _CANON_COVERAGE_PROJECT_SOURCE_DIRS "${_project_source_dirs}"
    )
    _canon_update_coverage_exclusions()
endfunction()

# Creates build-wide cleanup and report targets for coverage-enabled Canon targets.
function(_canon_add_coverage_targets)
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

    if ("${_gcov_command}" STREQUAL "")
        return()
    endif()

    find_program(
        CANON_GCOVR_EXECUTABLE
        NAMES gcovr
        REQUIRED
        DOC "gcovr executable used by Canon coverage"
    )

    set(_output_dir "${CMAKE_BINARY_DIR}/coverage")
    set(_summary_file "${_output_dir}/summary.json")
    add_custom_target(
        coverage-report
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${_output_dir}"
        COMMAND
            "${CANON_GCOVR_EXECUTABLE}"
            --root "${CMAKE_SOURCE_DIR}"
            "${CMAKE_BINARY_DIR}"
            --gcov-executable "${_gcov_command}"
            --exclude ".*_test\\.cpp$"
            "$<TARGET_PROPERTY:coverage-report,_CANON_COVERAGE_EXCLUDE_ARGUMENTS>"
            --html-details "${_output_dir}/index.html"
            --json-summary "${_summary_file}"
            --delete
            --print-summary
        COMMAND
            "${CMAKE_COMMAND}"
            "-DCANON_COVERAGE_SUMMARY_FILE=${_summary_file}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CanonCoverageVerify.cmake"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMENT "Generating coverage report"
        USES_TERMINAL
        COMMAND_EXPAND_LISTS
        VERBATIM
    )
    _canon_update_coverage_exclusions()
endfunction()

# Adds gcov-compatible instrumentation and build-wide reporting helpers.
function(_canon_apply_coverage TARGET)
    _canon_register_coverage_project()

    _canon_apply_cxx_option("${TARGET}" "--coverage")
    if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
        _canon_apply_cxx_option("${TARGET}" "-fprofile-abs-path")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if ("${_type}" STREQUAL "STATIC_LIBRARY" OR "${_type}" STREQUAL "OBJECT_LIBRARY")
        target_link_options("${TARGET}" INTERFACE --coverage)
    else()
        target_link_options("${TARGET}" PRIVATE --coverage)
    endif()

    get_property(_targets_added GLOBAL PROPERTY _CANON_COVERAGE_TARGETS_ADDED)
    if (NOT _targets_added)
        _canon_add_coverage_targets()
        set_property(GLOBAL PROPERTY _CANON_COVERAGE_TARGETS_ADDED TRUE)
    endif()
endfunction()

# Lets CMake drive clang-tidy with the real compile command for each source file.
function(_canon_apply_tidy TARGET)
    set(_minimum_version 21.1.6)

    find_program(
        CANON_CLANG_TIDY_EXECUTABLE
        NAMES clang-tidy
        REQUIRED
        DOC "clang-tidy executable used by Canon"
    )

    string(SHA256 _tidy_key "${CANON_CLANG_TIDY_EXECUTABLE}")
    set(_validation_property "_CANON_CLANG_TIDY_VALIDATED_${_tidy_key}")
    get_property(_validated GLOBAL PROPERTY "${_validation_property}")
    if (NOT _validated)
        _canon_get_clang_tidy_version("${CANON_CLANG_TIDY_EXECUTABLE}" _version)
        if ("${_version}" STREQUAL "")
            message(FATAL_ERROR
                "Canon could not determine the clang-tidy version from "
                "'${CANON_CLANG_TIDY_EXECUTABLE}'")
        endif()
        if ("${_version}" VERSION_LESS "${_minimum_version}")
            message(FATAL_ERROR
                "Canon requires clang-tidy ${_minimum_version} or newer; "
                "found ${_version} at '${CANON_CLANG_TIDY_EXECUTABLE}'")
        endif()
        set_property(GLOBAL PROPERTY "${_validation_property}" TRUE)
    endif()

    file(REAL_PATH "${PROJECT_SOURCE_DIR}" _project_source_dir)
    cmake_path(
        CONVERT "${_project_source_dir}/external"
        TO_CMAKE_PATH_LIST _external_directory
        NORMALIZE
    )
    _canon_regex_escape_literal("${_external_directory}" _external_regex)
    set(_tidy_command
        "${CANON_CLANG_TIDY_EXECUTABLE}"
        "--exclude-header-filter=^${_external_regex}/"
    )
    if (CANON_ENABLE_WARNINGS)
        # clang-tidy uses a Clang frontend even when the configured compiler is GCC.
        # Pass only options guaranteed by Canon's minimum clang-tidy version rather
        # than masking unsupported options with -Wno-unknown-warning-option.
        _canon_get_clang_warning_policy(
            _warning_suppressions
            _optional_warning_suppressions
            _warning_reenables
        )
        foreach(_option IN LISTS
            _warning_suppressions
            _optional_warning_suppressions
            _warning_reenables
        )
            list(APPEND _tidy_command "--extra-arg=${_option}")
        endforeach()
    endif()
    set_property(TARGET "${TARGET}" PROPERTY CXX_CLANG_TIDY "${_tidy_command}")
endfunction()

# Applies Canon's private build policy to a target that compiles C++ sources.
function(canon_apply_target TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_target(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT "${_type}" STREQUAL "EXECUTABLE"
        AND NOT "${_type}" STREQUAL "STATIC_LIBRARY"
        AND NOT "${_type}" STREQUAL "SHARED_LIBRARY"
        AND NOT "${_type}" STREQUAL "MODULE_LIBRARY"
        AND NOT "${_type}" STREQUAL "OBJECT_LIBRARY")
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

# Returns the install directory for this project's finalized package architecture.
function(_canon_package_install_directory OUT_DIRECTORY)
    get_property(
        _architecture_specific
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_ARCHITECTURE_SPECIFIC
    )
    if (_architecture_specific)
        include(GNUInstallDirs)
        set(_install_directory "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
    else()
        if (DEFINED CMAKE_INSTALL_DATADIR AND NOT "${CMAKE_INSTALL_DATADIR}" STREQUAL "")
            set(_data_directory "${CMAKE_INSTALL_DATADIR}")
        else()
            set(_data_directory share)
        endif()
        set(_install_directory "${_data_directory}/cmake/${PROJECT_NAME}")
    endif()

    set("${OUT_DIRECTORY}" "${_install_directory}" PARENT_SCOPE)
endfunction()

# Selects Canon's package compatibility policy from the project's major version.
function(_canon_package_version_compatibility OUT_COMPATIBILITY)
    if ("${PROJECT_VERSION_MAJOR}" EQUAL 0)
        set(_compatibility SameMinorVersion)
    else()
        set(_compatibility SameMajorVersion)
    endif()
    set("${OUT_COMPATIBILITY}" "${_compatibility}" PARENT_SCOPE)
endfunction()

# Writes the package version file from the project's finalized install policy.
function(_canon_write_package_version_file)
    if ("${PROJECT_VERSION}" STREQUAL "")
        return()
    endif()

    _canon_package_version_compatibility(_compatibility)

    get_property(
        _architecture_specific
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_ARCHITECTURE_SPECIFIC
    )
    set(_architecture_arguments)
    if (NOT _architecture_specific)
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

# Raises this project's package architecture to architecture-specific.
function(_canon_mark_package_architecture_specific)
    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_ARCHITECTURE_SPECIFIC TRUE
    )
endfunction()

# Serializes one already-evaluated package argument as CMake source.
function(_canon_serialize_package_argument OUT_ARGUMENT ARGUMENT)
    set(_equals "=")
    while (TRUE)
        set(_closing_bracket "]${_equals}]")
        string(FIND "${ARGUMENT}" "${_closing_bracket}" _closing_bracket_position)
        if ("${_closing_bracket_position}" EQUAL -1)
            break()
        endif()
        string(APPEND _equals "=")
    endwhile()

    set(_opening_bracket "[${_equals}[")
    set(_leading_newline "")
    if (NOT "${ARGUMENT}" STREQUAL "")
        string(SUBSTRING "${ARGUMENT}" 0 1 _first_character)
        if ("${_first_character}" STREQUAL "\n" OR "${_first_character}" STREQUAL "\r")
            set(_leading_newline "\n")
        endif()
    endif()

    set(
        "${OUT_ARGUMENT}"
        "${_opening_bracket}${_leading_newline}${ARGUMENT}${_closing_bracket}"
        PARENT_SCOPE
    )
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

# Finalizes the project-wide export and package configuration after target declarations.
function(_canon_finalize_package)
    get_property(
        _package_registered
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_REGISTERED
    )
    if (NOT _package_registered)
        get_property(
            _dependency_keys
            DIRECTORY "${PROJECT_SOURCE_DIR}"
            PROPERTY _CANON_PACKAGE_DEPENDENCY_KEYS
        )
        if (_dependency_keys)
            message(FATAL_ERROR
                "canon_propagate_dependency(): package dependencies were declared, but project "
                "'${PROJECT_NAME}' has no installable Canon package")
        endif()
        return()
    endif()

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

# Schedules one package finalization at the end of this project's source directory.
function(_canon_schedule_package_finalization)
    get_property(
        _finalizer_scheduled
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_FINALIZER_SCHEDULED
    )
    if (_finalizer_scheduled)
        return()
    endif()

    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_FINALIZER_SCHEDULED TRUE
    )
    cmake_language(
        DEFER DIRECTORY "${PROJECT_SOURCE_DIR}"
        CALL _canon_finalize_package
    )
endfunction()

# Records that a managed library makes this project an installable CMake package.
function(_canon_register_package)
    set_property(
        DIRECTORY "${PROJECT_SOURCE_DIR}"
        PROPERTY _CANON_PACKAGE_REGISTERED TRUE
    )
    _canon_schedule_package_finalization()
endfunction()

# Splits required dependency targets into those already present and those still missing.
function(_canon_partition_dependency_targets OUT_PRESENT OUT_MISSING)
    set(_present)
    set(_missing)
    foreach(_target IN LISTS ARGN)
        if (TARGET "${_target}")
            list(APPEND _present "${_target}")
        else()
            list(APPEND _missing "${_target}")
        endif()
    endforeach()
    set(${OUT_PRESENT} "${_present}" PARENT_SCOPE)
    set(${OUT_MISSING} "${_missing}" PARENT_SCOPE)
endfunction()

# Resolves one vendored-or-installed dependency for the active build.
function(_canon_resolve_dependency)
    set(_one_value_arguments NAME PACKAGE VERSION SOURCE_DIR BINARY_DIR VENDORED_HINT)
    set(_multi_value_arguments TARGETS)
    cmake_parse_arguments(
        PARSE_ARGV 0
        _dependency
        ""
        "${_one_value_arguments}"
        "${_multi_value_arguments}"
    )

    if (_dependency_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "_canon_resolve_dependency(): unexpected arguments: ${_dependency_UNPARSED_ARGUMENTS}")
    endif()

    message(CHECK_START "finding dependency '${_dependency_PACKAGE}'")

    _canon_partition_dependency_targets(
        _present_targets
        _missing_targets
        ${_dependency_TARGETS}
    )
    if (NOT _missing_targets)
        message(CHECK_PASS "already provided")
        return()
    endif()
    if (_present_targets)
        string(JOIN ", " _present_text ${_present_targets})
        string(JOIN ", " _missing_text ${_missing_targets})
        message(CHECK_FAIL "partially provided")
        message(FATAL_ERROR
            "dependency '${_dependency_PACKAGE}' is only partially available; "
            "present targets: ${_present_text}; missing targets: ${_missing_text}")
    endif()

    if (EXISTS "${_dependency_SOURCE_DIR}/CMakeLists.txt")
        add_subdirectory(
            "${_dependency_SOURCE_DIR}"
            "${_dependency_BINARY_DIR}"
            EXCLUDE_FROM_ALL
        )

        _canon_partition_dependency_targets(
            _present_targets
            _missing_targets
            ${_dependency_TARGETS}
        )
        if (_missing_targets)
            string(JOIN ", " _missing_text ${_missing_targets})
            message(CHECK_FAIL "vendored dependency is incomplete")
            message(FATAL_ERROR
                "vendored dependency '${_dependency_NAME}' did not provide required targets: "
                "${_missing_text}")
        endif()

        message(CHECK_PASS "using vendored '${_dependency_NAME}'")
        return()
    endif()

    find_package(
        "${_dependency_PACKAGE}"
        "${_dependency_VERSION}"
        CONFIG
        QUIET
    )

    _canon_partition_dependency_targets(
        _present_targets
        _missing_targets
        ${_dependency_TARGETS}
    )
    if (_missing_targets)
        string(JOIN ", " _missing_text ${_missing_targets})
        message(CHECK_FAIL "unavailable")
        message(FATAL_ERROR
            "dependency '${_dependency_PACKAGE}' version '${_dependency_VERSION}' is unavailable; "
            "${_dependency_VENDORED_HINT}, or install a compatible package providing: "
            "${_missing_text}")
    endif()

    message(CHECK_PASS "using installed package '${_dependency_PACKAGE}'")
endfunction()

# Resolves one project dependency from external/ or an installed package.
function(canon_resolve_dependency EXTERNAL_NAME)
    if ("${EXTERNAL_NAME}" STREQUAL "")
        message(FATAL_ERROR "canon_resolve_dependency(): external name must not be empty")
    endif()

    set(_one_value_arguments PACKAGE VERSION)
    set(_multi_value_arguments TARGETS)
    cmake_parse_arguments(
        PARSE_ARGV 1
        _dependency
        ""
        "${_one_value_arguments}"
        "${_multi_value_arguments}"
    )

    if (_dependency_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "canon_resolve_dependency(): unexpected arguments: ${_dependency_UNPARSED_ARGUMENTS}")
    endif()
    if ("${_dependency_PACKAGE}" STREQUAL "")
        set(_dependency_PACKAGE "${EXTERNAL_NAME}")
    endif()
    if ("${_dependency_VERSION}" STREQUAL "")
        message(FATAL_ERROR "canon_resolve_dependency(): VERSION is required")
    endif()
    if (NOT _dependency_TARGETS)
        message(FATAL_ERROR "canon_resolve_dependency(): TARGETS is required")
    endif()

    _canon_resolve_dependency(
        NAME "${EXTERNAL_NAME}"
        PACKAGE "${_dependency_PACKAGE}"
        VERSION "${_dependency_VERSION}"
        SOURCE_DIR "${PROJECT_SOURCE_DIR}/external/${EXTERNAL_NAME}"
        BINARY_DIR "${PROJECT_BINARY_DIR}/external/${EXTERNAL_NAME}"
        VENDORED_HINT "initialize vendored dependency 'external/${EXTERNAL_NAME}'"
        TARGETS ${_dependency_TARGETS}
    )
endfunction()

# Makes Canon's GoogleTest policy available lazily to projects that need tests.
function(canon_require_googletest)
    set(BUILD_GMOCK ON)
    set(INSTALL_GTEST OFF)

    set(_source_dir "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../external/googletest")
    cmake_path(NORMAL_PATH _source_dir)

    _canon_resolve_dependency(
        NAME googletest
        PACKAGE GTest
        VERSION "1.18.0...<2.0.0"
        SOURCE_DIR "${_source_dir}"
        BINARY_DIR "${CMAKE_BINARY_DIR}/canon/external/googletest"
        VENDORED_HINT "initialize Canon submodule 'external/googletest'"
        TARGETS
            GTest::gmock_main
            GTest::gtest_main
    )
endfunction()

# Propagates one dependency requirement to this project's installed package.
function(canon_propagate_dependency PACKAGE)
    if ("${PACKAGE}" STREQUAL "")
        message(FATAL_ERROR "canon_propagate_dependency(): package name must not be empty")
    endif()

    set(_dependency_call "find_dependency(")
    math(EXPR _last_argument "${ARGC} - 1")
    foreach(_argument_index RANGE 0 ${_last_argument})
        set(_argument_name "ARGV${_argument_index}")
        set(_argument "${${_argument_name}}")
        if ("${_argument_index}" GREATER 0
            AND ("${_argument}" STREQUAL "REQUIRED" OR "${_argument}" STREQUAL "QUIET"))
            message(FATAL_ERROR
                "canon_propagate_dependency(): '${_argument}' is inherited from the outer find_package() call")
        endif()

        _canon_serialize_package_argument(_serialized_argument "${_argument}")
        if ("${_argument_index}" GREATER 0)
            string(APPEND _dependency_call " ")
        endif()
        string(APPEND _dependency_call "${_serialized_argument}")
    endforeach()
    string(APPEND _dependency_call ")")

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
        if (NOT "${_existing_call}" STREQUAL "${_dependency_call}")
            message(FATAL_ERROR
                "canon_propagate_dependency(): internal dependency-key collision for package '${PACKAGE}'")
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

    _canon_schedule_package_finalization()
endfunction()

# Applies Canon's compiled-target policy and conventional installation to an executable.
function(canon_apply_executable TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_executable(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT "${_type}" STREQUAL "EXECUTABLE")
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
    _canon_mark_package_architecture_specific()
endfunction()

# Installs a managed library and each of its public HEADERS file sets.
function(_canon_install_library TARGET)
    get_property(_header_sets TARGET "${TARGET}" PROPERTY INTERFACE_HEADER_SETS)

    get_target_property(_type "${TARGET}" TYPE)
    if ("${_type}" STREQUAL "INTERFACE_LIBRARY")
        set(_file_set_arguments)
        foreach(_header_set IN LISTS _header_sets)
            list(APPEND _file_set_arguments FILE_SET "${_header_set}")
        endforeach()
        install(
            TARGETS "${TARGET}"
            EXPORT "${PROJECT_NAME}Targets"
            ${_file_set_arguments}
        )
        return()
    endif()

    include(GNUInstallDirs)
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

# Returns the library name used by Canon's public package target.
function(_canon_library_public_name TARGET OUT_NAME)
    get_target_property(_public_name "${TARGET}" EXPORT_NAME)
    if ("${_public_name}" STREQUAL "_public_name-NOTFOUND")
        set(_public_name "${TARGET}")
    endif()
    set("${OUT_NAME}" "${_public_name}" PARENT_SCOPE)
endfunction()

# Returns a deterministic export-identity component for a name.
function(_canon_default_export_identity NAME OUT_NAME)
    string(MAKE_C_IDENTIFIER "${NAME}" _identity)
    string(REGEX REPLACE "([a-z0-9])([A-Z])" "\\1_\\2" _identity "${_identity}")
    string(TOUPPER "${_identity}" _identity)
    set("${OUT_NAME}" "${_identity}" PARENT_SCOPE)
endfunction()

# Returns the configured or derived public export identity for a library.
function(_canon_export_identity TARGET OUT_NAME)
    get_target_property(_identity "${TARGET}" CANON_EXPORT_IDENTITY)
    if ("${_identity}" STREQUAL "_identity-NOTFOUND")
        _canon_library_public_name("${TARGET}" _public_name)
        _canon_default_export_identity("${_public_name}" _identity)
    elseif (NOT "${_identity}" MATCHES "^[A-Z_][A-Z0-9_]*$")
        message(FATAL_ERROR
            "canon_apply_library(): CANON_EXPORT_IDENTITY for '${TARGET}' must be an uppercase C identifier")
    endif()

    set("${OUT_NAME}" "${_identity}" PARENT_SCOPE)
endfunction()

# Claims one generated export macro across all Canon-managed libraries in this build tree.
function(_canon_claim_export_macro TARGET MACRO)
    string(HEX "${MACRO}" _macro_key)
    set(_property "_CANON_EXPORT_MACRO_${_macro_key}")
    get_property(_owner GLOBAL PROPERTY "${_property}")

    _canon_library_public_name("${TARGET}" _public_name)
    set(_claim "${PROJECT_NAME}::${_public_name} (target '${TARGET}')")
    if (NOT "${_owner}" STREQUAL "" AND NOT "${_owner}" STREQUAL "${_claim}")
        message(FATAL_ERROR
            "canon_apply_library(): export macro '${MACRO}' for library '${_claim}' "
            "conflicts with library '${_owner}'; set a distinct CANON_EXPORT_IDENTITY")
    endif()

    set_property(GLOBAL PROPERTY "${_property}" "${_claim}")
endfunction()

# Claims a generated export-header path for one library in the current project.
function(_canon_claim_export_header TARGET HEADER)
    string(HEX "${HEADER}" _header_key)
    set(_property "_CANON_EXPORT_HEADER_${_header_key}")
    get_property(_owner DIRECTORY "${PROJECT_SOURCE_DIR}" PROPERTY "${_property}")

    if (NOT "${_owner}" STREQUAL "" AND NOT "${_owner}" STREQUAL "${TARGET}")
        message(FATAL_ERROR
            "canon_apply_library(): generated export header '${HEADER}' for target '${TARGET}' "
            "conflicts with target '${_owner}'; set a distinct CANON_EXPORT_IDENTITY")
    endif()

    set_property(DIRECTORY "${PROJECT_SOURCE_DIR}" PROPERTY "${_property}" "${TARGET}")
endfunction()

# Adds the build-tree alias that matches the installed package target name.
function(_canon_add_build_tree_alias TARGET)
    _canon_library_public_name("${TARGET}" _public_name)
    set(_alias "${PROJECT_NAME}::${_public_name}")
    if (TARGET "${_alias}")
        get_target_property(_aliased_target "${_alias}" ALIASED_TARGET)
        if ("${_aliased_target}" STREQUAL "${TARGET}")
            return()
        endif()
        message(FATAL_ERROR
            "canon_apply_library(): public target '${_alias}' already exists")
    endif()

    add_library("${_alias}" ALIAS "${TARGET}")
endfunction()

# Applies Canon's library policy and conventional installation to a library.
function(canon_apply_library TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_library(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT "${_type}" STREQUAL "STATIC_LIBRARY"
        AND NOT "${_type}" STREQUAL "SHARED_LIBRARY"
        AND NOT "${_type}" STREQUAL "MODULE_LIBRARY"
        AND NOT "${_type}" STREQUAL "INTERFACE_LIBRARY")
        message(FATAL_ERROR
            "canon_apply_library(): target '${TARGET}' must be a STATIC, SHARED, MODULE, or INTERFACE library")
    endif()

    get_target_property(_framework "${TARGET}" FRAMEWORK)
    if (_framework)
        message(FATAL_ERROR
            "canon_apply_library(): FRAMEWORK target '${TARGET}' is not supported")
    endif()

    _canon_add_build_tree_alias("${TARGET}")

    if ("${_type}" STREQUAL "INTERFACE_LIBRARY")
        target_compile_features("${TARGET}" INTERFACE cxx_std_26)
        _canon_install_library("${TARGET}")
        _canon_register_package()
        return()
    endif()

    _canon_mark_package_architecture_specific()
    canon_apply_target("${TARGET}")
    target_compile_features("${TARGET}" PUBLIC cxx_std_26)

    _canon_library_public_name("${TARGET}" _public_name)
    _canon_default_export_identity("${PROJECT_NAME}" _package_identity)
    _canon_export_identity("${TARGET}" _public_identity)
    string(TOLOWER "${_package_identity}" _package_path)
    string(TOLOWER "${_public_identity}" _public_path)

    if ("${_public_name}" STREQUAL "${PROJECT_NAME}")
        set(_header_directory "${_public_path}")
        set(_api_name "${_public_identity}")
    else()
        set(_header_directory "${_package_path}/${_public_path}")
        set(_api_name "${_package_identity}_${_public_identity}")
    endif()

    set(_header_path "${_header_directory}/export.hpp")
    _canon_claim_export_header("${TARGET}" "${_header_path}")
    _canon_claim_export_macro("${TARGET}" "${_api_name}_API")

    include(GenerateExportHeader)
    get_target_property(_target_binary_dir "${TARGET}" BINARY_DIR)
    set(_include_dir "${_target_binary_dir}/generated")
    set(_header "${_include_dir}/${_header_path}")
    file(MAKE_DIRECTORY "${_include_dir}/${_header_directory}")

    generate_export_header(
        "${TARGET}"
        BASE_NAME "${_api_name}"
        EXPORT_FILE_NAME "${_header}"
        EXPORT_MACRO_NAME "${_api_name}_API"
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
    if (ARGC EQUAL 0)
        message(FATAL_ERROR
            "canon_add_documentation(): at least one documentation input path is required")
    endif()

    set(_inputs)
    foreach(_input IN LISTS ARGN)
        if (IS_ABSOLUTE "${_input}")
            set(_absolute_input "${_input}")
        else()
            get_filename_component(
                _absolute_input
                "${_input}"
                ABSOLUTE
                BASE_DIR "${PROJECT_SOURCE_DIR}"
            )
        endif()
        if (NOT EXISTS "${_absolute_input}")
            message(FATAL_ERROR
                "canon_add_documentation(): input '${_input}' does not exist")
        endif()
        list(APPEND _inputs "${_absolute_input}")
    endforeach()

    include(GNUInstallDirs)
    find_package(Doxygen 1.9 QUIET OPTIONAL_COMPONENTS dot)

    set(_doc_target "${PROJECT_NAME}-doc")
    set(_clean_target "${PROJECT_NAME}-doc-clean")
    set(_output_directory "${PROJECT_BINARY_DIR}/doxygen")
    set(_warning_log "${PROJECT_BINARY_DIR}/doxygen-warnings.log")

    if (PROJECT_IS_TOP_LEVEL)
        install(
            DIRECTORY "${_output_directory}/html/"
            TYPE DOC
            COMPONENT Documentation
            EXCLUDE_FROM_ALL
        )
    endif()

    add_custom_target(
        "${_clean_target}"
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${_output_directory}"
        COMMAND "${CMAKE_COMMAND}" -E rm -f "${_warning_log}"
        COMMENT "Cleaning generated API documentation"
        VERBATIM
    )

    if (PROJECT_IS_TOP_LEVEL)
        add_custom_target(doc-clean)
        add_dependencies(doc-clean "${_clean_target}")
    endif()

    if (NOT Doxygen_FOUND)
        add_custom_target(
            "${_doc_target}"
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
        if (PROJECT_IS_TOP_LEVEL)
            add_custom_target(doc)
            add_dependencies(doc "${_doc_target}")
        endif()
        return()
    endif()

    set(_readme "${PROJECT_SOURCE_DIR}/README.md")
    if (EXISTS "${_readme}" AND NOT DEFINED DOXYGEN_USE_MDFILE_AS_MAINPAGE)
        set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${_readme}")
        list(APPEND _inputs "${_readme}")
    elseif (DEFINED DOXYGEN_USE_MDFILE_AS_MAINPAGE
        AND NOT "${DOXYGEN_USE_MDFILE_AS_MAINPAGE}" STREQUAL "")
        if (IS_ABSOLUTE "${DOXYGEN_USE_MDFILE_AS_MAINPAGE}")
            set(_main_page "${DOXYGEN_USE_MDFILE_AS_MAINPAGE}")
        else()
            get_filename_component(
                _main_page
                "${DOXYGEN_USE_MDFILE_AS_MAINPAGE}"
                ABSOLUTE
                BASE_DIR "${PROJECT_SOURCE_DIR}"
            )
        endif()
        if (EXISTS "${_main_page}")
            list(APPEND _inputs "${_main_page}")
        endif()
    endif()
    list(REMOVE_DUPLICATES _inputs)

    set(DOXYGEN_OUTPUT_DIRECTORY "${_output_directory}")
    set(DOXYGEN_HTML_OUTPUT html)
    set(DOXYGEN_GENERATE_HTML YES)
    set(DOXYGEN_WARN_AS_ERROR FAIL_ON_WARNINGS)
    set(DOXYGEN_WARN_LOGFILE "${_warning_log}")

    list(APPEND DOXYGEN_EXCLUDE
        "${PROJECT_BINARY_DIR}"
        "${PROJECT_SOURCE_DIR}/external"
        "${PROJECT_SOURCE_DIR}/standards"
        "${PROJECT_SOURCE_DIR}/test"
    )
    list(APPEND DOXYGEN_EXCLUDE_PATTERNS "*_test.cpp")
    list(APPEND DOXYGEN_EXCLUDE_SYMBOLS detail "*::detail")

    if (NOT DEFINED DOXYGEN_STRIP_FROM_PATH)
        set(DOXYGEN_STRIP_FROM_PATH "${PROJECT_SOURCE_DIR}")
    endif()
    if (NOT DEFINED DOXYGEN_QUIET)
        set(DOXYGEN_QUIET YES)
    endif()
    if (NOT DEFINED DOXYGEN_JAVADOC_AUTOBRIEF)
        set(DOXYGEN_JAVADOC_AUTOBRIEF YES)
    endif()
    if (NOT DEFINED DOXYGEN_QT_AUTOBRIEF)
        set(DOXYGEN_QT_AUTOBRIEF YES)
    endif()
    if (NOT DEFINED DOXYGEN_ENABLE_PREPROCESSING)
        set(DOXYGEN_ENABLE_PREPROCESSING YES)
    endif()
    if (NOT DEFINED DOXYGEN_EXTRACT_ALL)
        set(DOXYGEN_EXTRACT_ALL NO)
    endif()

    doxygen_add_docs(
        "${_doc_target}"
        ${_inputs}
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        COMMENT "Generating API documentation"
    )

    if (PROJECT_IS_TOP_LEVEL)
        add_custom_target(doc)
        add_dependencies(doc "${_doc_target}")
    endif()
endfunction()

cmake_policy(POP)
