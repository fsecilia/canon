add_library(DependencyFixture::Runtime SHARED IMPORTED GLOBAL)
set_target_properties(DependencyFixture::Runtime PROPERTIES IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/libfixture.so")
