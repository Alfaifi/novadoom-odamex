### fmtlib ###

if(BUILD_CLIENT OR BUILD_SERVER)
  message(STATUS "Compiling {fmt}...")

  lib_buildgen(
    LIBRARY fmt
    PARAMS "-DFMT_DOC=OFF"
           "-DFMT_INSTALL=ON"
           "-DFMT_TEST=OFF")
  lib_build(LIBRARY fmt)

  # Force find_package to use our internal fmt, not any system-installed version
  find_package(fmt REQUIRED
    PATHS "${CMAKE_CURRENT_BINARY_DIR}/local"
    NO_DEFAULT_PATH)
  set_target_properties(fmt::fmt PROPERTIES IMPORTED_GLOBAL TRUE)

  # Ensure our internal fmt headers are found BEFORE any system fmt headers
  # This is critical when Homebrew packages (like ccache) install a newer fmt
  include_directories(BEFORE SYSTEM "${CMAKE_CURRENT_BINARY_DIR}/local/include")
endif()
