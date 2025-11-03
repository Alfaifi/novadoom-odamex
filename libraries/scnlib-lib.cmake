### fmtlib ###

if(BUILD_CLIENT OR BUILD_SERVER)
  message(STATUS "Compiling scnlib...")

  lib_buildgen(
    LIBRARY scnlib
    PARAMS "-DSCN_DISABLE_FAST_FLOAT=ON"
           "-DSCN_DISABLE_TOP_PROJECT=ON"
           "-DSCN_INSTALL=ON"
           "-DCMAKE_CXX_STANDARD=17"
           "-DCMAKE_DEBUG_POSTFIX=d")
  lib_build(LIBRARY scnlib)

  find_package(scn REQUIRED)
  set_target_properties(scn::scn PROPERTIES IMPORTED_GLOBAL TRUE)
endif()
