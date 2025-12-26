include(NovaDoomCopyWad)
include(NovaDoomTargetSettings)

# use unquoted #defines
if(COMMAND cmake_policy)
  cmake_policy(SET CMP0005 NEW)
endif(COMMAND cmake_policy)

# Server flags. [AM] TODO: Test -O3 again sometime.
if(NOT MSVC)
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O2")
endif()

# #define SERVER_APP for use in the source code
add_definitions(-DSERVER_APP)

# Server
file(GLOB SERVER_SOURCES src/*.cpp src/*.h)
if(WIN32)
  file(GLOB SERVER_WIN32_SOURCES win32/*.h)
  configure_file(win32/server.rc.in "${CMAKE_CURRENT_BINARY_DIR}/server.rc" @ONLY)
  list(APPEND SERVER_WIN32_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/server.rc")
endif()

# Tag source files with correct directories
get_target_property(COMMON_SOURCES odamex-common INTERFACE_SOURCES)
source_group("Common" FILES ${COMMON_SOURCES})
source_group("Server" FILES ${SERVER_SOURCES})
source_group("Win32" FILES ${SERVER_WIN32_SOURCES})

# Server definitions
if(USE_MINIUPNP)
  add_definitions(-DODA_HAVE_MINIUPNP)
endif()

if(WIN32 AND NOT MSVC)
  add_definitions(-DWINVER=0x0500)
endif()

add_executable(novasrv
  ${COMMON_SOURCES} ${SERVER_SOURCES} ${SERVER_WIN32_SOURCES})
novadoom_target_settings(novasrv)

target_include_directories(novasrv PRIVATE src)
if(WIN32)
  target_include_directories(novasrv PRIVATE win32)

  # We need to call SetProcessInformation to disable power throttling,
  # but the API itself doesn't exist until Windows 8.  Here we set the minimum
  # Windows version to 8.  (Windows Server 2012, BTW)
  target_compile_definitions(novasrv PRIVATE _WIN32_WINNT=0x0602)
endif()

target_link_libraries(novasrv fmt::fmt tinylibs ZLIB::ZLIB odamex-common odaproto minilzo cpptrace::cpptrace)

if(USE_INTERNAL_JSONCPP)
  target_link_libraries(novasrv jsoncpp_static)
else()
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(JSONCPP jsoncpp REQUIRED IMPORTED_TARGET)
  target_link_libraries(novasrv PkgConfig::JSONCPP)
endif()

if(USE_MINIUPNP)
  if(USE_INTERNAL_MINIUPNP)
    target_link_libraries(novasrv miniupnpc::miniupnpc)
  else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(MINIUPNPC miniupnpc REQUIRED IMPORTED_TARGET)
    target_link_libraries(novasrv PkgConfig::MINIUPNPC)
  endif()
endif()

if(WIN32)
  target_link_libraries(novasrv winmm wsock32 shlwapi)
elseif(SOLARIS)
  target_link_libraries(novasrv socket nsl)
elseif(UNIX)
  find_package(Threads REQUIRED)
  target_link_libraries(novasrv pthread)
endif()

if(UNIX AND NOT APPLE)
  target_link_libraries(novasrv rt)
endif()

novadoom_copy_wad(novasrv)

if(APPLE)
elseif(WIN32)
  install(TARGETS novasrv
    RUNTIME DESTINATION .
    COMPONENT server)
else()
  install(TARGETS novasrv
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT server)
endif()

# [AM] Not needed right now, but could be in the future...
if(BUILD_OR_FAIL AND NOT TARGET novasrv)
  message(FATAL_ERROR "NovaSrv target could not be generated")
endif()
