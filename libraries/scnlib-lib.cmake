### scnlib ###

if(BUILD_CLIENT OR BUILD_SERVER)
  message(STATUS "Compiling scnlib...")

  include(CheckCXXSourceCompiles)
  check_cxx_source_compiles("
  #include <charconv>
  int main() {
    const char* s = \"1.23\";
    float f;
    auto result = std::from_chars(s, s + 4, f);
  }
  " HAVE_STD_FROM_CHARS_FLOAT)


  if(HAVE_STD_FROM_CHARS_FLOAT)
    message(STATUS "std::from_chars float supported — disabling fast_float")
    set(DISABLE_FAST_FLOAT ON)
  else()
    message(STATUS "std::from_chars float not supported — enabling fast_float")
    set(DISABLE_FAST_FLOAT OFF)
  endif()

  lib_buildgen(
    LIBRARY scnlib
    PARAMS "-DSCN_DISABLE_FAST_FLOAT=${DISABLE_FAST_FLOAT}"
           "-DSCN_DISABLE_TOP_PROJECT=ON"
           "-DSCN_INSTALL=ON"
           "-DCMAKE_CXX_STANDARD=17"
           "-DCMAKE_DEBUG_POSTFIX=d")
  lib_build(LIBRARY scnlib)

  find_package(scn REQUIRED)
  set_target_properties(scn::scn PROPERTIES IMPORTED_GLOBAL TRUE)
endif()
