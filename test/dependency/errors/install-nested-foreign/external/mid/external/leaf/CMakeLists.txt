project(LeafFixture LANGUAGES CXX)

add_library(leaf_fixture_runtime SHARED runtime.cpp)
add_library(LeafFixture::Runtime ALIAS leaf_fixture_runtime)
