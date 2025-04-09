### SDL libraries ###

if(BUILD_CLIENT)

  ### SDL2 ###

  # if(NOT USE_SDL3)
  if(FALSE)
    if(WIN32)
      if(MSVC)
        file(DOWNLOAD
          "https://www.libsdl.org/release/SDL2-devel-2.32.4-VC.zip"
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2-VC.zip"
          EXPECTED_HASH SHA256=28681dbef9c31a2bb4af6cbda90fdabc27c7415d65b9393da83d5abd12c4a265)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xf
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2-VC.zip"
          WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

        set(SDL2_DIR "${CMAKE_CURRENT_BINARY_DIR}/SDL2-2.32.4")
        set(SDL2_INCLUDE_DIR "${SDL2_DIR}/include" CACHE PATH "")
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(SDL2_LIBRARY "${SDL2_DIR}/lib/x64/SDL2.lib" CACHE FILEPATH "")
          set(SDL2MAIN_LIBRARY "${SDL2_DIR}/lib/x64/SDL2main.lib" CACHE FILEPATH "")
        else()
          set(SDL2_LIBRARY "${SDL2_DIR}/lib/x86/SDL2.lib" CACHE FILEPATH "")
          set(SDL2MAIN_LIBRARY "${SDL2_DIR}/lib/x86/SDL2main.lib" CACHE FILEPATH "")
        endif()
      else()
        file(DOWNLOAD
          "https://www.libsdl.org/release/SDL2-devel-2.32.4-mingw.tar.gz"
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2-mingw.tar.gz"
          EXPECTED_HASH SHA256=c2ec09788ab99b23b8e8e472775e5f728da549ae27898280cedbb15da87f47c1)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xf
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2-mingw.tar.gz"
          WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(SDL2_DIR "${CMAKE_CURRENT_BINARY_DIR}/SDL2-2.32.4/x86_64-w64-mingw32")
        else()
          set(SDL2_DIR "${CMAKE_CURRENT_BINARY_DIR}/SDL2-2.32.4/i686-w64-mingw32")
        endif()
        set(SDL2_INCLUDE_DIR "${SDL2_DIR}/include/SDL2" CACHE PATH "")
        set(SDL2_LIBRARY "${SDL2_DIR}/lib/libSDL2.dll.a" CACHE FILEPATH "")
        set(SDL2MAIN_LIBRARY "${SDL2_DIR}/lib/libSDL2main.a" CACHE FILEPATH "")
      endif()
    endif()

    find_package(SDL2)

    if(SDL2_FOUND)
      # SDL2 target.
      add_library(SDL2::SDL2 UNKNOWN IMPORTED GLOBAL)
      set_target_properties(SDL2::SDL2 PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${SDL2_INCLUDE_DIR}"
        IMPORTED_LOCATION "${SDL2_LIBRARY}")

      if(SDL2MAIN_LIBRARY)
        # SDL2main target.
        if(MINGW)
          # Gross hack to get mingw32 first in the linker order.
          add_library(SDL2::_SDL2main_detail UNKNOWN IMPORTED GLOBAL)
          set_target_properties(SDL2::_SDL2main_detail PROPERTIES
            IMPORTED_LOCATION "${SDL2MAIN_LIBRARY}")

          # Ensure that SDL2main comes before SDL2 in the linker order.  CMake
          # isn't smart enough to keep proper ordering for indirect dependencies
          # so we have to spell it out here.
          target_link_libraries(SDL2::_SDL2main_detail INTERFACE SDL2::SDL2)

          add_library(SDL2::SDL2main INTERFACE IMPORTED GLOBAL)
          set_target_properties(SDL2::SDL2main PROPERTIES
            IMPORTED_LIBNAME mingw32)
          target_link_libraries(SDL2::SDL2main INTERFACE SDL2::_SDL2main_detail)
        else()
          add_library(SDL2::SDL2main UNKNOWN IMPORTED GLOBAL)
          set_target_properties(SDL2::SDL2main PROPERTIES
            IMPORTED_LOCATION "${SDL2MAIN_LIBRARY}")
        endif()
      endif()
    endif()
  else()

    ### SDL3 ###

    if(WIN32)
      if(MSVC)
        file(DOWNLOAD
          "https://www.libsdl.org/release/SDL3-devel-3.2.10-VC.zip"
          "${CMAKE_CURRENT_BINARY_DIR}/SDL3-VC.zip"
          EXPECTED_HASH SHA256=afcfafc7e389e048c3693e11fe645ea84392c35673e4f201fe21ac513719935d)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xf
          "${CMAKE_CURRENT_BINARY_DIR}/SDL3-VC.zip"
          WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

        set(SDL3_ROOT "${CMAKE_CURRENT_BINARY_DIR}/SDL3-3.2.10/cmake")
        set(SDL3_DIR "${SDL3_ROOT}/cmake")
        set(SDL3_INCLUDE_DIR "${SDL3_ROOT}/include" CACHE PATH "")
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(SDL3_LIBRARY "${SDL3_ROOT}/lib/x64/SDL3.lib" CACHE FILEPATH "")
        else()
          set(SDL3_LIBRARY "${SDL3_ROOT}/lib/x86/SDL3.lib" CACHE FILEPATH "")
        endif()
      else()
        file(DOWNLOAD
          "https://www.libsdl.org/release/SDL3-devel-3.2.10-mingw.tar.gz"
          "${CMAKE_CURRENT_BINARY_DIR}/SDL3-mingw.tar.gz"
          EXPECTED_HASH SHA256=7ae252153992997470918917f899ef7e414c77b33685f43232a4f56c9cb75ac3)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xf
          "${CMAKE_CURRENT_BINARY_DIR}/SDL3-mingw.tar.gz"
          WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(SDL3_ROOT "${CMAKE_CURRENT_BINARY_DIR}/SDL3-3.2.10/x86_64-w64-mingw32")
        else()
          set(SDL3_ROOT "${CMAKE_CURRENT_BINARY_DIR}/SDL3-3.2.10/i686-w64-mingw32")
        endif()
        set(SDL3_INCLUDE_DIR "${SDL3_ROOT}/include/SDL3" CACHE PATH "")
        set(SDL3_LIBRARY "${SDL3_ROOT}/lib/libSDL3.dll.a" CACHE FILEPATH "")
        set(SDL3_DIR "${SDL3_ROOT}/lib/cmake" CACHE PATH "")
      endif()
    endif()

    find_package(SDL3)
  endif()

  ### SDL2_mixer ###

  if(NOT USE_SDL12)
    if(WIN32)
      if(MSVC)
        file(DOWNLOAD
          "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-devel-2.6.2-VC.zip"
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-VC.zip"
          EXPECTED_HASH SHA256=7f050663ccc7911bb9c57b11e32ca79578b712490186b8645ddbbe4e7d2fe1c9)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xf
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-VC.zip"
          WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

        set(SDL2_MIXER_DIR "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-2.6.2")
        set(SDL2_MIXER_INCLUDE_DIR "${SDL2_MIXER_DIR}/include" CACHE PATH "")
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(SDL2_MIXER_LIBRARY "${SDL2_MIXER_DIR}/lib/x64/SDL2_mixer.lib" CACHE FILEPATH "")
        else()
          set(SDL2_MIXER_LIBRARY "${SDL2_MIXER_DIR}/lib/x86/SDL2_mixer.lib" CACHE FILEPATH "")
        endif()
      else()
        file(DOWNLOAD
          "https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-devel-2.6.2-mingw.tar.gz"
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-mingw.tar.gz"
          EXPECTED_HASH SHA256=6c414d05a3b867e0d59e0f9b28ea7e5e64527e612ccf961735dc2478391315b3)
        execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xf
          "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-mingw.tar.gz"
          WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
          set(SDL2_MIXER_DIR "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-2.6.2/x86_64-w64-mingw32")
        else()
          set(SDL2_MIXER_DIR "${CMAKE_CURRENT_BINARY_DIR}/SDL2_mixer-2.6.2/i686-w64-mingw32")
        endif()
        set(SDL2_MIXER_INCLUDE_DIR "${SDL2_MIXER_DIR}/include/SDL2" CACHE PATH "")
        set(SDL2_MIXER_LIBRARY "${SDL2_MIXER_DIR}/lib/libSDL2_mixer.dll.a" CACHE FILEPATH "")
      endif()
    endif()

    find_package(SDL2_mixer)

    if(SDL2_MIXER_FOUND)
      # SDL2_mixer target.
      add_library(SDL2::mixer UNKNOWN IMPORTED GLOBAL)
      set_target_properties(SDL2::mixer PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${SDL2_MIXER_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES SDL2::SDL2
        IMPORTED_LOCATION "${SDL2_MIXER_LIBRARY}")
    endif()
  endif()
endif()
