# FluidSynth - A Software Synthesizer
# Modified for NovaDoom static linking (from ZDoom/ZMusic)
#
# Copyright (C) 2003-2025 Peter Hanappe and others.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.

cmake_minimum_required(VERSION 3.13)
project(fluidsynth_static C CXX)

set(FLUIDSYNTH_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Source files
set(fluidsynth_SOURCES
    ${FLUIDSYNTH_SRC_DIR}/utils/fluid_conv.c
    ${FLUIDSYNTH_SRC_DIR}/utils/fluid_hash.c
    ${FLUIDSYNTH_SRC_DIR}/utils/fluid_list.c
    ${FLUIDSYNTH_SRC_DIR}/utils/fluid_ringbuffer.c
    ${FLUIDSYNTH_SRC_DIR}/utils/fluid_settings.c
    ${FLUIDSYNTH_SRC_DIR}/utils/fluid_sys.c
    ${FLUIDSYNTH_SRC_DIR}/sfloader/fluid_defsfont.c
    ${FLUIDSYNTH_SRC_DIR}/sfloader/fluid_sfont.c
    ${FLUIDSYNTH_SRC_DIR}/sfloader/fluid_sffile.c
    ${FLUIDSYNTH_SRC_DIR}/sfloader/fluid_samplecache.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_adsr_env.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_chorus.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_iir_filter.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_iir_filter_impl.cpp
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_lfo.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_rvoice.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_rvoice_dsp.cpp
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_rvoice_event.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_rvoice_mixer.c
    ${FLUIDSYNTH_SRC_DIR}/rvoice/fluid_rev.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_chan.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_event.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_gen.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_mod.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_synth.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_synth_monopoly.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_tuning.c
    ${FLUIDSYNTH_SRC_DIR}/synth/fluid_voice.c
    ${FLUIDSYNTH_SRC_DIR}/midi/fluid_midi.c
    ${FLUIDSYNTH_SRC_DIR}/midi/fluid_midi_router.c
    ${FLUIDSYNTH_SRC_DIR}/midi/fluid_seqbind.c
    ${FLUIDSYNTH_SRC_DIR}/midi/fluid_seqbind_notes.cpp
    ${FLUIDSYNTH_SRC_DIR}/midi/fluid_seq.c
    ${FLUIDSYNTH_SRC_DIR}/midi/fluid_seq_queue.cpp
    ${FLUIDSYNTH_SRC_DIR}/drivers/fluid_adriver.c
    ${FLUIDSYNTH_SRC_DIR}/drivers/fluid_mdriver.c
    ${FLUIDSYNTH_SRC_DIR}/bindings/fluid_filerenderer.c
    ${FLUIDSYNTH_SRC_DIR}/bindings/fluid_ladspa.c
)

# Add Windows GLib stubs on Windows
if(WIN32)
    list(APPEND fluidsynth_SOURCES
        ${FLUIDSYNTH_SRC_DIR}/utils/win32_glibstubs.c
    )
endif()

# Create static library
add_library(fluidsynth_static STATIC ${fluidsynth_SOURCES})

# Include directories
target_include_directories(fluidsynth_static PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_include_directories(fluidsynth_static PRIVATE
    ${FLUIDSYNTH_SRC_DIR}
    ${FLUIDSYNTH_SRC_DIR}/drivers
    ${FLUIDSYNTH_SRC_DIR}/synth
    ${FLUIDSYNTH_SRC_DIR}/rvoice
    ${FLUIDSYNTH_SRC_DIR}/midi
    ${FLUIDSYNTH_SRC_DIR}/utils
    ${FLUIDSYNTH_SRC_DIR}/sfloader
    ${FLUIDSYNTH_SRC_DIR}/bindings
)

# Platform-specific settings
if(WIN32)
    target_compile_definitions(fluidsynth_static PRIVATE
        WIN32
        _WIN32
        WITH_GLIB_STUBS
    )
elseif(UNIX AND NOT APPLE)
    # On Linux, we still need GLib
    find_package(PkgConfig REQUIRED)
    pkg_search_module(GLIB REQUIRED glib-2.0)
    target_include_directories(fluidsynth_static PUBLIC ${GLIB_INCLUDE_DIRS})
    target_link_libraries(fluidsynth_static PUBLIC ${GLIB_LIBRARIES})
elseif(APPLE)
    # On macOS, we still need GLib
    find_package(PkgConfig REQUIRED)
    pkg_search_module(GLIB REQUIRED glib-2.0)
    target_include_directories(fluidsynth_static PUBLIC ${GLIB_INCLUDE_DIRS})
    target_link_libraries(fluidsynth_static PUBLIC ${GLIB_LIBRARIES})
endif()

# Suppress some warnings
if(MSVC)
    target_compile_options(fluidsynth_static PRIVATE /wd4244 /wd4267 /wd4996)
else()
    target_compile_options(fluidsynth_static PRIVATE -Wno-unused-parameter -Wno-sign-compare)
endif()

# Set output name
set_target_properties(fluidsynth_static PROPERTIES OUTPUT_NAME "fluidsynth")
