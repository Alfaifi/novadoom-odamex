### libADLMIDI ###

if(BUILD_CLIENT)
  if(USE_INTERNAL_LIBADLMIDI)
    message(STATUS "Compiling internal libADLMIDI...")

    # Set vars so the finder can find them.
    set(libADLMIDI_INCLUDE_DIR
      "${CMAKE_CURRENT_BINARY_DIR}/local/include")
    set(libADLMIDI_LIBRARY
      "${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}adlMIDI${libsuffix}")

    # Generate the build.
    execute_process(COMMAND "${CMAKE_COMMAND}"
      -S "${CMAKE_CURRENT_SOURCE_DIR}/libadlmidi"
      -B "${CMAKE_CURRENT_BINARY_DIR}/libadlmidi-build"
      -G "${CMAKE_GENERATOR}"
      -A "${CMAKE_GENERATOR_PLATFORM}"
      -T "${CMAKE_GENERATOR_TOOLSET}"
      "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
      "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
      "-DCMAKE_LINKER=${CMAKE_LINKER}"
      "-DCMAKE_RC_COMPILER=${CMAKE_RC_COMPILER}"
      "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
      "-DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/local"
      )

    # Compile the library.
    execute_process(COMMAND "${CMAKE_COMMAND}"
      --build "${CMAKE_CURRENT_BINARY_DIR}/libadlmidi-build"
      --config RelWithDebInfo --target install)
  endif()

  find_package(libADLMIDI)
  if(TARGET libADLMIDI::ADLMIDI_static)
    set_target_properties(libADLMIDI::ADLMIDI_static PROPERTIES IMPORTED_GLOBAL True)
  endif()
endif()
