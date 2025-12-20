include(FindLibAgar)

if(NOT MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-attributes")
endif()

# API
set(API_DIR ../odalpapi)
file(GLOB API_HEADERS ${API_DIR}/*.h ${API_DIR}/threads/*.h)
file(GLOB API_SOURCES ${API_DIR}/*.cpp ${API_DIR}/threads/*.cpp)

# NovaLaunch
set(LAUNCH_DIR src)
file(GLOB LAUNCH_HEADERS src/*.h)
file(GLOB LAUNCH_SOURCES src/*.cpp)

# AG-NovaLaunch definitions
include_directories(${API_DIR} ${LAUNCH_DIR})

find_package(LibAgar)
if(LibAgar_FOUND)
  include_directories(${LibAgar_INCLUDE_DIRS})
  add_definitions(${LibAgar_DEFINITIONS})
  message("-- Agar libraries found, ag-novalaunch target generated.")
endif()

# AG-NovaLaunch target
if(LibAgar_FOUND)
  add_executable(ag-novalaunch MACOSX_BUNDLE WIN32
    ${API_SOURCES} ${API_HEADERS}
    ${LAUNCH_SOURCES} ${LAUNCH_HEADERS}
  )
  add_custom_command(
    TARGET ag-novalaunch
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/res
  )
  target_link_libraries(ag-novalaunch ${LibAgar_LIBRARIES})

  set(MACOSX_BUNDLE_BUNDLE_NAME AG-NovaLaunch)
  set(MACOSX_BUNDLE_INFO_STRING "NovaDoom © ${PROJECT_COPYRIGHT} NovaDoom Team.")
  set(MACOSX_BUNDLE_LONG_VERSION_STRING "${PROJECT_VERSION}")
  set(MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}")
  set(MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}")
  set(MACOSX_BUNDLE_ICON_FILE novalaunch.icns)
  set(MACOSX_BUNDLE_GUI_IDENTIFIER net.novadoom.ag-launcher)

  if(APPLE)
    add_custom_command(
      TARGET ag-novalaunch
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/ag-novalaunch.app/Contents/Resources
      COMMAND ${CMAKE_COMMAND} -E copy
      ${CMAKE_SOURCE_DIR}/media/${MACOSX_BUNDLE_ICON_FILE} ${CMAKE_CURRENT_BINARY_DIR}/ag-novalaunch.app/Contents/Resources/
    )

    set_directory_properties(
      PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES
      "${CMAKE_CURRENT_BINARY_DIR}/ag-novalaunch.app/Contents/Resources/${MACOSX_BUNDLE_ICON_FILE}"
    )
  endif()
endif()
