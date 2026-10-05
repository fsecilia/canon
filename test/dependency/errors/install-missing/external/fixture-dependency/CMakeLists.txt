add_library(dependency_fixture_runtime SHARED ${CMAKE_CURRENT_LIST_DIR}/../../runtime.cpp)
add_library(DependencyFixture::Runtime ALIAS dependency_fixture_runtime)
