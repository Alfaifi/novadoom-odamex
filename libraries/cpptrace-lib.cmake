### cpptrace ###

if(BUILD_CLIENT OR BUILD_SERVER)
  if(USE_INTERNAL_CPPTRACE)
      set(_CPPTRACE_BUILDGEN_PARAMS
        "-DCMAKE_DEBUG_POSTFIX=d"
        "-DCPPTRACE_USE_EXTERNAL_LIBDWARF=${USE_EXTERNAL_LIBDWARF}")


    if(USE_INTERNAL_ZLIB)
      list(APPEND _CPPTRACE_BUILDGEN_PARAMS
        "-DZLIB_ROOT=${CMAKE_CURRENT_BINARY_DIR}/local")
      list(APPEND _CPPTRACE_BUILDGEN_PARAMS
        "-DZLIB_INCLUDE_DIR=${CMAKE_CURRENT_BINARY_DIR}/local/include")
      if (WIN32)
        list(APPEND _CPPTRACE_BUILDGEN_PARAMS
          "-DZLIB_LIBRARY=${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}libzstatic${libsuffix}")
      else()
        list(APPEND _CPPTRACE_BUILDGEN_PARAMS
          "-DZLIB_LIBRARY=${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}z${libsuffix}")
      endif()
      # Set vars so the finder can find them.
      set(ZLIB_INCLUDE_DIR
        "${CMAKE_CURRENT_BINARY_DIR}/local/include")
      set(ZLIB_ROOT
        "${CMAKE_CURRENT_BINARY_DIR}/local")
      if(WIN32)
        set(ZLIB_LIBRARY
          "${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}zlibstatic${libsuffix}")
      else()
        set(ZLIB_LIBRARY
          "${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}z${libsuffix}")
      endif()
    endif()

    lib_buildgen(
      LIBRARY cpptrace
      PARAMS ${_CPPTRACE_BUILDGEN_PARAMS})
    lib_build(LIBRARY cpptrace)
  endif()

  find_package(cpptrace)
  if(TARGET cpptrace::cpptrace)
    set_target_properties(cpptrace::cpptrace PROPERTIES IMPORTED_GLOBAL True)
  endif()
endif()
