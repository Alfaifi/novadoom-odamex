include(NovaDoomCopyLibs)
include(NovaDoomCopyWad)
include(NovaDoomTargetSettings)

# use unquoted #defines
if(COMMAND cmake_policy)
  cmake_policy(SET CMP0005 NEW)
endif(COMMAND cmake_policy)

# Enable default SIMD settings for standard builds.
option(USE_DEFAULT_SIMD "Use default SIMD optimization settings" ON)

# #define CLIENT_APP for use in the source code
add_definitions(-DCLIENT_APP)

# Client
set(CLIENT_DIR sdl src)
file(GLOB CLIENT_SOURCES src/*.cpp src/*.h)
file(GLOB CLIENT_SDL_SOURCES sdl/*.cpp sdl/*.h)
if(WIN32)
  configure_file(sdl/client.rc.in "${CMAKE_CURRENT_BINARY_DIR}/client.rc" @ONLY)
  list(APPEND CLIENT_SDL_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/client.rc")
endif()
if(APPLE)
  # Include SDLMain.m for macOS - provides Cocoa application delegate for URL scheme handling
  list(APPEND CLIENT_SDL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/sdl/SDLMain.m")
endif()

# Client GUI sources
file(GLOB CLIENT_GUI_SOURCES gui/*.cpp gui/*.h)

# Tag source files with correct directories
get_target_property(COMMON_SOURCES odamex-common INTERFACE_SOURCES)
source_group("Client" FILES ${CLIENT_SOURCES})
source_group("Common" FILES ${COMMON_SOURCES})
source_group("SDL" FILES ${CLIENT_SDL_SOURCES})
source_group("GUI" FILES ${CLIENT_GUI_SOURCES})

# Client definitions
include_directories(${COMMON_DIR} ${CLIENT_DIR})

# Make sure we don't find libraries that are in Program Files/Odamex
if(WIN32)
  list(REMOVE_ITEM CMAKE_SYSTEM_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
endif()

# X11 configuration
if(UNIX AND NOT APPLE)
  find_package(X11)
  if(X11_FOUND)
    add_definitions(-DX11)
    include_directories(${X11_INCLUDE_DIR})
    link_libraries(${X11_LIBRARIES})
  endif()
endif()

# PortMidi configuration

# PortMidi
if(ENABLE_PORTMIDI)
  find_package(PortMidi)
  if(NOT PORTMIDI_FOUND)
    # build the PortMidi library
    set(PORTMIDI_LIBRARY "portmidi")
    set(PORTMIDI_LIBRARIES ${PORTMIDI_LIBRARY})
    set(PORTMIDI_DIR ../libraries/portmidi)
    set(PORTMIDI_INCLUDE_DIR ${PORTMIDI_DIR}/pm_common/ ${PORTMIDI_DIR}/porttime/)

    if(APPLE)
      find_library(COREFOUNDATION_LIBRARY CoreFoundation)
      find_library(COREAUDIO_LIB CoreAudio)
      find_library(COREMIDI_LIB CoreMIDI)
      find_library(CORESERVICES_LIB CoreServices)

      set(PM_NEEDED_LIBS ${COREAUDIO_LIB} ${COREFOUNDATION_LIB} ${COREMIDI_LIB} ${CORESERVICES_LIB} CACHE INTERNAL "")
      file(GLOB PORTMIDI_PLATFORM_HEADERS ${PORTMIDI_DIR}/pm_mac/*.h)
      file(GLOB PORTMIDI_PLATFORM_SOURCES ${PORTMIDI_DIR}/pm_mac/*.c)
      list(APPEND PORTMIDI_PLATFORM_SOURCES ${PORTMIDI_DIR}/porttime/ptmacosx_mach.c)
    elseif(WIN32)
      set(PM_NEEDED_LIBS winmm.lib)
      file(GLOB PORTMIDI_PLATFORM_HEADERS ${PORTMIDI_DIR}/pm_win/*.h)
      file(GLOB PORTMIDI_PLATFORM_SOURCES ${PORTMIDI_DIR}/pm_win/*.c)
      list(APPEND PORTMIDI_PLATFORM_SOURCES ${PORTMIDI_DIR}/porttime/ptwinmm.c)
    elseif(UNIX)
      add_definitions(-DPMALSA)
      set(PM_NEEDED_LIBS pthread asound)
      file(GLOB PORTMIDI_PLATFORM_HEADERS ${PORTMIDI_DIR}/pm_linux/*.h)
      file(GLOB PORTMIDI_PLATFORM_SOURCES ${PORTMIDI_DIR}/pm_linux/*.c)
      list(APPEND PORTMIDI_PLATFORM_SOURCES ${PORTMIDI_DIR}/porttime/ptlinux.c)
    endif()

    file(GLOB PORTMIDI_HEADERS ${PORTMIDI_DIR}/pm_common/*.h)
    list(APPEND PORTMIDI_HEADERS ${PORTMIDI_DIR}/porttime/porttime.h)
    list(APPEND PORTMIDI_HEADERS ${PORTMIDI_PLATFORM_HEADERS})

    file(GLOB PORTMIDI_SOURCES ${PORTMIDI_DIR}/pm_common/*.c)
    list(APPEND PORTMIDI_SOURCES ${PORTMIDI_DIR}/porttime/porttime.c)
    list(APPEND PORTMIDI_SOURCES ${PORTMIDI_PLATFORM_SOURCES})

    add_library(${PORTMIDI_LIBRARY} STATIC ${PORTMIDI_SOURCES} ${PORTMIDI_HEADERS})
    target_link_libraries(${PORTMIDI_LIBRARY} ${PM_NEEDED_LIBS})
    message(STATUS "portmidi will be built and staticaly linked when compiling the client application.")
  endif()

  add_definitions(-DPORTMIDI)
  include_directories(${PORTMIDI_INCLUDE_DIR})
endif()

# Find Mac frameworks
if(APPLE)
  find_library(APPKIT_LIBRARY AppKit)
  find_library(CARBON_LIBRARY Carbon)
  find_library(AUDIOTBOX_LIBRARY AudioToolbox)
  find_library(AUDIOUNIT_LIBRARY AudioUnit)
  set(APPLE_FRAMEWORKS ${APPKIT_LIBRARY} ${CARBON_LIBRARY} ${AUDIOTBOX_LIBRARY}
    ${AUDIOUNIT_LIBRARY})
endif()

# FluidSynth configuration
option(ENABLE_FLUIDSYNTH "Enable FluidSynth for MIDI playback" ON)
cmake_dependent_option(USE_INTERNAL_FLUIDSYNTH "Use internal FluidSynth (static, no GLib on Windows)" OFF ENABLE_FLUIDSYNTH OFF)

if(ENABLE_FLUIDSYNTH)
  if(USE_INTERNAL_FLUIDSYNTH)
    # Use internal FluidSynth (ZDoom/ZMusic version with Windows GLib stubs)
    message(STATUS "Using internal FluidSynth (static library)")
    add_subdirectory(${CMAKE_SOURCE_DIR}/libraries/fluidsynth ${CMAKE_BINARY_DIR}/libraries/fluidsynth)
    set(FLUIDSYNTH_FOUND TRUE)
    set(FLUIDSYNTH_TARGET fluidsynth_static)
    add_definitions(-DFLUIDSYNTH)
  else()
    # Try CMake config-based detection first (works with vcpkg and Homebrew)
    find_package(FluidSynth CONFIG QUIET)
    if(FluidSynth_FOUND AND TARGET FluidSynth::libfluidsynth)
      set(FLUIDSYNTH_FOUND TRUE)
      set(FLUIDSYNTH_TARGET FluidSynth::libfluidsynth)
      add_definitions(-DFLUIDSYNTH)
      message(STATUS "FluidSynth found via CMake config")
    else()
      # Fall back to pkg-config (Unix systems)
      find_package(PkgConfig QUIET)
      if(PkgConfig_FOUND)
        pkg_check_modules(FLUIDSYNTH fluidsynth)
        if(FLUIDSYNTH_FOUND)
          add_definitions(-DFLUIDSYNTH)
          include_directories(${FLUIDSYNTH_INCLUDE_DIRS})
          message(STATUS "FluidSynth found via pkg-config: ${FLUIDSYNTH_VERSION}")
        endif()
      endif()
    endif()
  endif()

  if(NOT FLUIDSYNTH_FOUND)
    message(STATUS "FluidSynth not found, FluidSynth music system will not be available")
    set(ENABLE_FLUIDSYNTH OFF)
  endif()
endif()

# Client target
if(TARGET SDL2::SDL2 OR TARGET SDL::SDL)

  # Textscreen
  set(TEXTSCREEN_LIBRARY "textscreen")
  set(TEXTSCREEN_DIR ../libraries/textscreen)
  set(TEXTSCREEN_HEADERS ${TEXTSCREEN_DIR}/txt_sdl.h ${TEXTSCREEN_DIR}/txt_main.h)
  set(TEXTSCREEN_SOURCES ${TEXTSCREEN_DIR}/txt_sdl.cpp)

  include_directories(${TEXTSCREEN_DIR})
  add_library(${TEXTSCREEN_LIBRARY} STATIC ${TEXTSCREEN_SOURCES} ${TEXTSCREEN_HEADERS})

  if(TARGET SDL::SDL)
    target_link_libraries(${TEXTSCREEN_LIBRARY} SDL::SDL)
  else()
    target_link_libraries(${TEXTSCREEN_LIBRARY} SDL2::SDL2)
  endif()

  target_include_directories(${TEXTSCREEN_LIBRARY} PRIVATE ../common)

  add_executable(novadoom MACOSX_BUNDLE WIN32
    ${CLIENT_SOURCES} ${CLIENT_SDL_SOURCES} ${COMMON_SOURCES} ${CLIENT_GUI_SOURCES})
  novadoom_target_settings(novadoom)

  if(USE_DEFAULT_SIMD)
    if(ODAMEX_TARGET_ARCH STREQUAL "amd64")
      message(STATUS "Default SIMD flags not touched for AMD64")
    elseif(ODAMEX_TARGET_ARCH STREQUAL "i386")
      if(NOT MSVC)
        target_compile_options(novadoom PRIVATE -msse2)
      else()
        target_compile_options(novadoom PRIVATE /arch:SSE2)
      endif()
      message(STATUS "Default SIMD flags set to SSE2")
    elseif(ODAMEX_TARGET_ARCH MATCHES "ppc")
      if(APPLE)
        target_compile_options(novadoom PRIVATE -faltivec)
      else()
        target_compile_options(novadoom PRIVATE -maltivec)
      endif()
      message(STATUS "Default SIMD flags set to AltiVec")
    endif()
  else()
    message(STATUS "Default SIMD flags not used on user request")
  endif()

  if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    message(STATUS "GNU Detected, forcing GCC to link math.h")
    target_compile_options(novadoom PRIVATE -lm)
  endif()

  if(MSVC)
    # We supply our own manifest, don't use the default one.
    set_target_properties(novadoom PROPERTIES LINK_FLAGS "/MANIFEST:NO")
  endif()

  target_link_libraries(novadoom ${TEXTSCREEN_LIBRARY})
  target_link_libraries(novadoom odamex-common odaproto tinylibs)
  if(TARGET SDL::SDL)
    target_link_libraries(novadoom SDL::SDL)
    # On macOS we provide our own SDLMain.m, so don't link SDLmain
    if(TARGET SDL::SDLmain AND NOT APPLE)
      target_link_libraries(novadoom SDL::SDLmain)
    endif()
    target_link_libraries(novadoom SDL::mixer)
  else()
    target_link_libraries(novadoom SDL2::SDL2)
    # On macOS we provide our own SDLMain.m, so don't link SDL2main
    if(TARGET SDL2::SDL2main AND NOT APPLE)
      target_link_libraries(novadoom SDL2::SDL2main)
    endif()
    target_link_libraries(novadoom SDL2::mixer)
  endif()

  target_include_directories(novadoom PRIVATE gui)
  if(USE_INTERNAL_FLTK)
    target_link_libraries(novadoom fltk::fltk fltk::images)
  else()
    # Try CMake CONFIG first (vcpkg), then legacy FindFLTK module (Homebrew, system)
    find_package(FLTK 1.4 CONFIG QUIET)
    if(TARGET fltk::fltk-shared)
      target_link_libraries(novadoom fltk::fltk-shared fltk::images-shared)
      message(STATUS "FLTK found via CMake config")
    else()
      # Fall back to legacy FindFLTK module
      find_package(FLTK REQUIRED)
      target_include_directories(novadoom PRIVATE ${FLTK_INCLUDE_DIR})
      target_link_libraries(novadoom ${FLTK_LIBRARIES})
      message(STATUS "FLTK found via FindFLTK module: ${FLTK_LIBRARIES}")
    endif()
  endif()

  if(USE_INTERNAL_JSONCPP)
    target_link_libraries(novadoom jsoncpp_static)
  else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(JSONCPP jsoncpp REQUIRED IMPORTED_TARGET)
    target_link_libraries(novadoom PkgConfig::JSONCPP)
  endif()

  if(ENABLE_PORTMIDI)
    target_link_libraries(novadoom ${PORTMIDI_LIBRARY})
  endif()

  if(ENABLE_FLUIDSYNTH)
    if(DEFINED FLUIDSYNTH_TARGET)
      # Link via CMake target (vcpkg)
      target_link_libraries(novadoom ${FLUIDSYNTH_TARGET})
    else()
      # Link via pkg-config variables
      target_include_directories(novadoom PRIVATE ${FLUIDSYNTH_INCLUDE_DIRS})
      target_link_directories(odamex PRIVATE ${FLUIDSYNTH_LIBRARY_DIRS})
      target_link_libraries(novadoom ${FLUIDSYNTH_LIBRARIES})
    endif()
  endif()

  target_link_libraries(novadoom ZLIB::ZLIB PNG::PNG fmt::fmt minilzo cpptrace::cpptrace libADLMIDI::ADLMIDI_static curl_interface)

  if(WIN32)
    target_link_libraries(novadoom winmm wsock32 shlwapi)
  elseif(APPLE)
    target_link_libraries(novadoom ${APPLE_FRAMEWORKS})
  elseif(SOLARIS)
    target_link_libraries(novadoom socket nsl)
  endif()

  if(UNIX AND NOT APPLE)
    target_link_libraries(novadoom rt)
    if(X11_FOUND)
      target_link_libraries(novadoom X11)
    endif()
  endif()

  novadoom_copy_libs(novadoom)
  novadoom_copy_wad(novadoom)

  set(MACOSX_BUNDLE_BUNDLE_NAME ${CMAKE_PROJECT_NAME})
  set(MACOSX_BUNDLE_INFO_STRING "NovaDoom © ${PROJECT_COPYRIGHT} NovaDoom Team.")
  set(MACOSX_BUNDLE_LONG_VERSION_STRING "${PROJECT_VERSION}")
  set(MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}")
  set(MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}")
  set(MACOSX_BUNDLE_ICON_FILE novadoom.icns)
  set(MACOSX_BUNDLE_GUI_IDENTIFIER net.novadoom.client)

  # Use custom Info.plist template that includes URL scheme handler (novadoom://)
  set_target_properties(novadoom PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/cmake/modules/MacOSXBundleInfo.plist.in"
  )

  if(APPLE)
    add_custom_command(
      TARGET novadoom
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/Resources
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/media/${MACOSX_BUNDLE_ICON_FILE} ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/Resources
    )
    if(TARGET odawad)
      add_custom_command(
        TARGET novadoom
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/wad/novadoom.wad ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/MacOS)
    endif()

    set_directory_properties(
      PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES
      "${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/Resources/${MACOSX_BUNDLE_ICON_FILE};${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/MacOS/novadoom.wad"
    )

    #****
    # The remaining commands are issued on 'make install'. They make the app
    # bundle "stand-alone" by packaging dependencies inside.
    #****

    # Install into bundle under client directory
    set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR})

    # if(SDL2_FOUND AND SDL2_MIXER_FOUND)
    #     string(REPLACE "-framework Cocoa" "" SDL_DIR ${SDL2_LIBRARY})
    #     string(REPLACE "-framework Cocoa" "" SDLMIXER_DIR ${SDL2_MIXER_LIBRARY})
    # else(SDL2_FOUND AND SDL2_MIXER_FOUND)
    #     string(REPLACE "-framework Cocoa" "" SDL_DIR ${SDL_LIBRARY})
    #     string(REPLACE "-framework Cocoa" "" SDLMIXER_DIR ${SDLMIXER_LIBRARY})
    # endif()

    # Install the SDL framework into the bundle
    if(IS_DIRECTORY ${SDL_DIR})
      install(DIRECTORY ${SDL_DIR} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/Frameworks)
      install(CODE "execute_process(COMMAND
        install_name_tool -change @rpath/SDL.framework/Versions/A/SDL
        @executable_path/../Frameworks/SDL.framework/Versions/A/SDL
        ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/MacOS/novadoom)
        " )
    endif()

    # Install the SDL_mixer framework into the bundle
    if(IS_DIRECTORY ${SDLMIXER_DIR})
      install(DIRECTORY ${SDLMIXER_DIR} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/Frameworks)
    endif()

    # If PortMidi was built in install the PortMidi library into the bundle
    if(PortMidi_FOUND)
      install(FILES ${PORTMIDI_LIBRARIES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/Frameworks/)
      install(CODE "execute_process(COMMAND
        install_name_tool -change libportmidi.dylib
        @executable_path/../Frameworks/libportmidi.dylib
        ${CMAKE_CURRENT_BINARY_DIR}/novadoom.app/Contents/MacOS/novadoom)
        " )
    endif()
  elseif(WIN32)
    install(TARGETS novadoom
      RUNTIME DESTINATION .
      COMPONENT client)
  else()
    install(TARGETS novadoom
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT client)
  endif()
endif()

if(BUILD_OR_FAIL AND NOT TARGET novadoom)
  message(FATAL_ERROR "NovaDoom target could not be generated")
endif()
