add_library(dependency_fixture_runtime SHARED ${CMAKE_CURRENT_LIST_DIR}/../../runtime.cpp)
set_target_properties(dependency_fixture_runtime PROPERTIES FRAMEWORK TRUE)
add_library(DependencyFixture::Runtime ALIAS dependency_fixture_runtime)
