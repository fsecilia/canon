# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if(NOT "${VulkanFixture_FIND_VERSION}" STREQUAL "7.3")
    message(FATAL_ERROR "unexpected VulkanFixture version '${VulkanFixture_FIND_VERSION}'")
endif()
add_library(VulkanFixture::Vulkan INTERFACE IMPORTED)
set(VulkanFixture_FOUND TRUE)
