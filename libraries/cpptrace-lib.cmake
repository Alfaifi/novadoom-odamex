### cpptrace ###

if(BUILD_CLIENT OR BUILD_SERVER)
  if(USE_INTERNAL_CPPTRACE)
      set(_CPPTRACE_BUILDGEN_PARAMS
        "-DCMAKE_DEBUG_POSTFIX=d"
        "-DCPPTRACE_USE_EXTERNAL_LIBDWARF=${USE_EXTERNAL_LIBDWARF}")


    if(USE_INTERNAL_ZLIB)
      list(APPEND _CPPTRACE_BUILDGEN_PARAMS
        "-DZLIB_INCLUDE_DIR=${CMAKE_CURRENT_BINARY_DIR}/local/include")
      list(APPEND _CPPTRACE_BUILDGEN_PARAMS
        "-DZLIB_LIBRARY=${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}zlibstatic${libsuffix}")
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
