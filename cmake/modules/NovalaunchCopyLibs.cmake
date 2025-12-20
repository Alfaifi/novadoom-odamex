function(odalaunch_copy_libs TARGET)
  set(NOVADOOM_DLLS "")

  if(WIN32)
    if(MSVC_VERSION GREATER_EQUAL 1900)
      if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(WX_DLL_DIR "${CMAKE_BINARY_DIR}/libraries/wxWidgets/lib/vc14x_x64_dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxbase315ud_net_vc14x_x64.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxbase315ud_vc14x_x64.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxbase315ud_xml_vc14x_x64.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxmsw315ud_core_vc14x_x64.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxmsw315ud_html_vc14x_x64.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxmsw315ud_xrc_vc14x_x64.dll")
      else()
        set(WX_DLL_DIR "${CMAKE_BINARY_DIR}/libraries/wxWidgets/lib/vc14x_dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxbase315ud_net_vc14x.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxbase315ud_vc14x.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxbase315ud_xml_vc14x.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxmsw315ud_core_vc14x.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxmsw315ud_html_vc14x.dll")
        list(APPEND NOVADOOM_DLLS "${WX_DLL_DIR}/wxmsw315ud_xrc_vc14x.dll")
      endif()
    endif()
  endif()

  # Copy library files to target directory.
  foreach(NOVADOOM_DLL ${NOVADOOM_DLLS})
    string(REPLACE "315ud_" "315u_" NOVADOOM_RELEASE_DLL "${NOVADOOM_DLL}")
    add_custom_command(TARGET ${TARGET} POST_BUILD
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      $<$<CONFIG:Debug>:${NOVADOOM_DLL}>
      $<$<CONFIG:Release>:${NOVADOOM_RELEASE_DLL}>
      $<$<CONFIG:RelWithDebInfo>:${NOVADOOM_RELEASE_DLL}>
      $<$<CONFIG:MinSizeRel>:${NOVADOOM_RELEASE_DLL}>
      $<TARGET_FILE_DIR:${TARGET}> VERBATIM)
  endforeach()
endfunction()
