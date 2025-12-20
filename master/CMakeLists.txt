include(NovaDoomTargetSettings)

# Master
file(GLOB MASTER_SOURCES *.cpp *.h)

# Master target
add_executable(novamast ${MASTER_SOURCES})
novadoom_target_settings(novamast)
set_property(TARGET novamast PROPERTY CXX_STANDARD 98)

if(WIN32)
  target_link_libraries(novamast wsock32)
elseif(SOLARIS)
  target_link_libraries(novamast socket nsl)
endif()

if(UNIX)
	install( TARGETS novamast DESTINATION ${CMAKE_INSTALL_BINDIR} )
endif()

if(BUILD_OR_FAIL AND NOT TARGET novamast)
  message(FATAL_ERROR "NovaDoom metaserver target could not be generated")
endif()
