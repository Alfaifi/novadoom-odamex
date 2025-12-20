function(novadoom_copy_libs TARGET)
  # Skip DLL copying if requested (useful for CI where DLLs are copied manually)
  if(NOVADOOM_SKIP_DLL_COPY)
    return()
  endif()

  set(NOVADOOM_DLLS "")

  if(WIN32)
    if(MSVC)
      set(SDL2_DLL_DIR "$<TARGET_FILE_DIR:SDL2::SDL2>")
      set(SDL2_MIXER_DLL_DIR "$<TARGET_FILE_DIR:SDL2::mixer>")

      # SDL2
      list(APPEND NOVADOOM_DLLS "${SDL2_DLL_DIR}/SDL2.dll")

      # SDL2_mixer and optional codecs (only for MSVC with downloaded packages)
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/optional/libwavpack-1.dll")
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/optional/libgme.dll")
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/optional/libxmp.dll")
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/optional/libogg-0.dll")
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/optional/libopus-0.dll")
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/optional/libopusfile-0.dll")
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/SDL2_mixer.dll")
    else()
      # MinGW/MSYS2: Only copy main DLLs, skip optional codecs
      # (MSYS2 packages have codecs built-in, optional/ folder doesn't exist)
      set(SDL2_DLL_DIR "$<TARGET_FILE_DIR:SDL2::SDL2>/../bin")
      set(SDL2_MIXER_DLL_DIR "$<TARGET_FILE_DIR:SDL2::mixer>/../bin")

      # SDL2
      list(APPEND NOVADOOM_DLLS "${SDL2_DLL_DIR}/SDL2.dll")

      # SDL2_mixer (no optional codecs for MinGW - they're built-in)
      list(APPEND NOVADOOM_DLLS "${SDL2_MIXER_DLL_DIR}/SDL2_mixer.dll")
    endif()
  endif()

  # Copy library files to target directory.
  foreach(NOVADOOM_DLL ${NOVADOOM_DLLS})
    add_custom_command(TARGET ${TARGET} POST_BUILD
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${NOVADOOM_DLL}" $<TARGET_FILE_DIR:${TARGET}> VERBATIM)
  endforeach()
endfunction()
