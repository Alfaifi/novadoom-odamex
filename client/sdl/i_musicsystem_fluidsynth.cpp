//-----------------------------------------------------------------------------
//
// Copyright (C) 2006-2025 by The Odamex Team
// Portions Copyright (C) 2025 by The NovaDoom Team.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//  Plays music utilizing the FluidSynth library for high-quality MIDI
//  synthesis with SoundFont support. Configured to match GZDoom's output.
//
//-----------------------------------------------------------------------------

#include "novadoom.h"

#include "i_musicsystem_fluidsynth.h"

#include "i_sdl.h"
#include <SDL_mixer.h>
#include <fluidsynth.h>

#include "i_music.h"
#include "i_system.h"
#include "m_fileio.h"
#include "mus2midi.h"
#include "w_wad.h"
#include "cmdlib.h"
#include "c_dispatch.h"

EXTERN_CVAR(snd_samplerate)
EXTERN_CVAR(snd_musicvolume)

// FluidSynth configuration CVARs (defined in cl_cvarlist.cpp)
EXTERN_CVAR(snd_fluidsynthsoundfont)
EXTERN_CVAR(snd_fluidsynthgain)
EXTERN_CVAR(snd_fluidsynthreverb)
EXTERN_CVAR(snd_fluidsynthreverbroomsize)
EXTERN_CVAR(snd_fluidsynthreverbdamping)
EXTERN_CVAR(snd_fluidsynthreverbwidth)
EXTERN_CVAR(snd_fluidsynthreverblevel)
EXTERN_CVAR(snd_fluidsynthchorus)
EXTERN_CVAR(snd_fluidsynthchorusvoices)
EXTERN_CVAR(snd_fluidsynthchoruslevel)
EXTERN_CVAR(snd_fluidsynthchorusspeed)
EXTERN_CVAR(snd_fluidsynthchorusdepth)
EXTERN_CVAR(snd_fluidsynthchorustype)
EXTERN_CVAR(snd_fluidsynthpolyphony)
EXTERN_CVAR(snd_fluidsynthinterp)

extern MusicSystem* musicsystem;
extern MusicSystemType current_musicsystem_type;

// Callback implementations for CVAR changes
CVAR_FUNC_IMPL(snd_fluidsynthgain)
{
	if (current_musicsystem_type == MS_FLUIDSYNTH)
		static_cast<FluidSynthMusicSystem*>(musicsystem)->applyCVars();
}

CVAR_FUNC_IMPL(snd_fluidsynthreverb)
{
	if (current_musicsystem_type == MS_FLUIDSYNTH)
		static_cast<FluidSynthMusicSystem*>(musicsystem)->applyCVars();
}

CVAR_FUNC_IMPL(snd_fluidsynthchorus)
{
	if (current_musicsystem_type == MS_FLUIDSYNTH)
		static_cast<FluidSynthMusicSystem*>(musicsystem)->applyCVars();
}

CVAR_FUNC_IMPL(snd_fluidsynthpolyphony)
{
	if (current_musicsystem_type == MS_FLUIDSYNTH)
		static_cast<FluidSynthMusicSystem*>(musicsystem)->applyCVars();
}

CVAR_FUNC_IMPL(snd_fluidsynthinterp)
{
	if (current_musicsystem_type == MS_FLUIDSYNTH)
		static_cast<FluidSynthMusicSystem*>(musicsystem)->applyCVars();
}

// FluidSynth audio callback for SDL_Mixer hook
static void fluidsynth_music_hook(void* data, byte* stream, int len)
{
	FluidSynthHookData* hdata = static_cast<FluidSynthHookData*>(data);
	if (hdata->paused || !hdata->synth)
	{
		memset(stream, 0, len);
		return;
	}

	const std::lock_guard<std::mutex> lock(*hdata->mutex);

	// FluidSynth generates float samples, we need to convert to int16
	int samples = len / 4; // 2 channels * 2 bytes per sample

	// Generate audio from FluidSynth
	float* left = new float[samples];
	float* right = new float[samples];

	fluid_synth_write_float(hdata->synth, samples, left, 0, 1, right, 0, 1);

	// Convert float to int16 and interleave
	int16_t* out = reinterpret_cast<int16_t*>(stream);
	for (int i = 0; i < samples; i++)
	{
		float l = left[i] * hdata->volume;
		float r = right[i] * hdata->volume;

		// Clamp to int16 range
		l = clamp(l * 32767.0f, -32768.0f, 32767.0f);
		r = clamp(r * 32767.0f, -32768.0f, 32767.0f);

		out[i * 2] = static_cast<int16_t>(l);
		out[i * 2 + 1] = static_cast<int16_t>(r);
	}

	delete[] left;
	delete[] right;
}

FluidSynthMusicSystem::FluidSynthMusicSystem() : m_mutex()
{
	I_ResetMidiVolume();

	// Create FluidSynth settings
	m_settings = new_fluid_settings();
	if (!m_settings)
	{
		PrintFmt(PRINT_WARNING, "I_InitMusic: Failed to create FluidSynth settings\n");
		return;
	}

	// Configure settings to match GZDoom defaults
	fluid_settings_setnum(m_settings, "synth.sample-rate", static_cast<double>(snd_samplerate.asInt()));
	fluid_settings_setint(m_settings, "synth.polyphony", snd_fluidsynthpolyphony.asInt());
	fluid_settings_setnum(m_settings, "synth.gain", static_cast<double>(snd_fluidsynthgain.value()));

	// Interpolation: 0=none, 1=linear, 4=4th order, 7=7th order
	int interp = snd_fluidsynthinterp.asInt();
	int interpMethod = FLUID_INTERP_LINEAR;
	switch (interp)
	{
	case 0:
		interpMethod = FLUID_INTERP_NONE;
		break;
	case 1:
		interpMethod = FLUID_INTERP_LINEAR;
		break;
	case 4:
		interpMethod = FLUID_INTERP_4THORDER;
		break;
	case 7:
		interpMethod = FLUID_INTERP_7THORDER;
		break;
	}
	fluid_settings_setint(m_settings, "synth.interpolation", interpMethod);

	// Create synthesizer
	m_synth = new_fluid_synth(m_settings);
	if (!m_synth)
	{
		PrintFmt(PRINT_WARNING, "I_InitMusic: Failed to create FluidSynth synthesizer\n");
		delete_fluid_settings(m_settings);
		m_settings = nullptr;
		return;
	}

	// Configure reverb (GZDoom defaults)
	fluid_synth_reverb_on(m_synth, -1, snd_fluidsynthreverb ? 1 : 0);
	if (snd_fluidsynthreverb)
	{
		fluid_synth_set_reverb_group_roomsize(m_synth, -1, snd_fluidsynthreverbroomsize.value());
		fluid_synth_set_reverb_group_damp(m_synth, -1, snd_fluidsynthreverbdamping.value());
		fluid_synth_set_reverb_group_width(m_synth, -1, snd_fluidsynthreverbwidth.value());
		fluid_synth_set_reverb_group_level(m_synth, -1, snd_fluidsynthreverblevel.value());
	}

	// Configure chorus (GZDoom defaults)
	fluid_synth_chorus_on(m_synth, -1, snd_fluidsynthchorus ? 1 : 0);
	if (snd_fluidsynthchorus)
	{
		fluid_synth_set_chorus_group_nr(m_synth, -1, snd_fluidsynthchorusvoices.asInt());
		fluid_synth_set_chorus_group_level(m_synth, -1, snd_fluidsynthchoruslevel.value());
		fluid_synth_set_chorus_group_speed(m_synth, -1, snd_fluidsynthchorusspeed.value());
		fluid_synth_set_chorus_group_depth(m_synth, -1, snd_fluidsynthchorusdepth.value());
		fluid_synth_set_chorus_group_type(m_synth, -1, snd_fluidsynthchorustype.asInt());
	}

	// Load soundfont
	if (!_LoadSoundfont())
	{
		PrintFmt(PRINT_WARNING, "I_InitMusic: Failed to load soundfont\n");
		delete_fluid_synth(m_synth);
		delete_fluid_settings(m_settings);
		m_synth = nullptr;
		m_settings = nullptr;
		return;
	}

	PrintFmt(PRINT_HIGH, "I_InitMusic: Music playback enabled using FluidSynth.\n");
	m_isInitialized = true;
}

FluidSynthMusicSystem::~FluidSynthMusicSystem()
{
	if (!isInitialized())
		return;

	Mix_HaltMusic();
	_StopSong();

	if (m_player)
	{
		delete_fluid_player(m_player);
		m_player = nullptr;
	}

	if (m_synth)
	{
		if (m_soundfontId >= 0)
			fluid_synth_sfunload(m_synth, m_soundfontId, 1);
		delete_fluid_synth(m_synth);
		m_synth = nullptr;
	}

	if (m_settings)
	{
		delete_fluid_settings(m_settings);
		m_settings = nullptr;
	}

	m_isInitialized = false;
}

bool FluidSynthMusicSystem::_LoadSoundfont()
{
	std::string sfPath = snd_fluidsynthsoundfont.str();

	// Try to find the soundfont file
	std::string fullPath;

	// First try as absolute path
	if (M_FileExists(sfPath))
	{
		fullPath = sfPath;
	}
	else
	{
		// Try relative to executable
		std::string basePath = M_GetBinaryDir();
		fullPath = basePath + PATHSEP + sfPath;

		if (!M_FileExists(fullPath))
		{
			// Try in common locations
			std::vector<std::string> searchPaths = {
			    basePath + PATHSEP + "soundfonts" + PATHSEP + "gzdoom.sf2",
			    basePath + PATHSEP + "gzdoom.sf2",
#ifdef __APPLE__
			    // macOS app bundle: check Resources folder (../Resources from MacOS)
			    basePath + PATHSEP + ".." + PATHSEP + "Resources" + PATHSEP +
			        "soundfonts" + PATHSEP + "gzdoom.sf2",
			    basePath + PATHSEP + ".." + PATHSEP + "Resources" + PATHSEP + "gzdoom.sf2",
			    std::string(getenv("HOME") ? getenv("HOME") : "") +
			        "/Library/Audio/Sounds/Banks/gzdoom.sf2",
#endif
#ifdef UNIX
			    "/usr/share/sounds/sf2/gzdoom.sf2",
			    "/usr/share/soundfonts/gzdoom.sf2",
			    "/usr/local/share/soundfonts/gzdoom.sf2",
#endif
			};

			fullPath.clear();
			for (const auto& path : searchPaths)
			{
				if (M_FileExists(path))
				{
					fullPath = path;
					break;
				}
			}
		}
	}

	if (fullPath.empty())
	{
		PrintFmt(PRINT_WARNING,
		       "I_InitMusic: Could not find soundfont '{}'\n",
		       sfPath);
		return false;
	}

	m_soundfontId = fluid_synth_sfload(m_synth, fullPath.c_str(), 1);
	if (m_soundfontId < 0)
	{
		PrintFmt(PRINT_WARNING,
		       "I_InitMusic: Failed to load soundfont '{}'\n",
		       fullPath);
		return false;
	}

	PrintFmt(PRINT_HIGH, "I_InitMusic: Loaded soundfont '{}'\n", fullPath);
	return true;
}

void FluidSynthMusicSystem::startSong(byte* data, size_t length, bool loop, int order)
{
	if (!isInitialized())
		return;

	stopSong();

	if (!data || !length)
		return;

	_RegisterSong(data, length);

	if (!m_isPlaying)
		return;

	if (m_player)
	{
		fluid_player_set_loop(m_player, loop ? -1 : 0);
		fluid_player_play(m_player);
	}

	_UpdateHook();

	MusicSystem::startSong(data, length, loop, order);
}

void FluidSynthMusicSystem::_StopSong()
{
	if (!isInitialized() || !m_isPlaying)
		return;

	m_isPlaying = false;

	Mix_HookMusic(nullptr, nullptr);

	if (m_player)
	{
		fluid_player_stop(m_player);
		delete_fluid_player(m_player);
		m_player = nullptr;
	}

	// Reset all channels
	if (m_synth)
	{
		fluid_synth_system_reset(m_synth);
	}
}

void FluidSynthMusicSystem::stopSong()
{
	_StopSong();
	MusicSystem::stopSong();
}

void FluidSynthMusicSystem::pauseSong()
{
	MusicSystem::pauseSong();

	if (!m_isPlaying)
		return;

	_UpdateHook();
}

void FluidSynthMusicSystem::resumeSong()
{
	MusicSystem::resumeSong();

	if (!m_isPlaying)
		return;

	_UpdateHook();
}

void FluidSynthMusicSystem::setVolume(float volume)
{
	MusicSystem::setVolume(volume);
	_UpdateHook();
	Mix_VolumeMusic(int(getVolume() * MIX_MAX_VOLUME));
}

void FluidSynthMusicSystem::_UpdateHook()
{
	if (!m_isPlaying)
		return;

	SDL_LockAudio();
	m_hookData.synth = m_synth;
	m_hookData.paused = isPaused();
	m_hookData.volume = getVolume();
	m_hookData.mutex = &m_mutex;
	SDL_UnlockAudio();

	Mix_HookMusic(fluidsynth_music_hook, &m_hookData);
}

void FluidSynthMusicSystem::_RegisterSong(byte* data, size_t length)
{
	const std::lock_guard<std::mutex> lock(m_mutex);
	m_isPlaying = false;

	if (!S_MusicIsMus(data, length) && !S_MusicIsMidi(data, length))
		return;

	// Convert MUS to MIDI if necessary
	MEMFILE* midiData = nullptr;
	bool needsFree = false;

	if (S_MusicIsMus(data, length))
	{
		MEMFILE* musInput = mem_fopen_read(data, length);
		midiData = mem_fopen_write();

		int result = mus2mid(musInput, midiData);
		mem_fclose(musInput);

		if (result != 0)
		{
			mem_fclose(midiData);
			PrintFmt(PRINT_WARNING, "FluidSynth: Failed to convert MUS to MIDI\n");
			return;
		}

		needsFree = true;
	}
	else
	{
		midiData = mem_fopen_read(data, length);
	}

	// Create a new player for this song
	if (m_player)
	{
		fluid_player_stop(m_player);
		delete_fluid_player(m_player);
	}

	m_player = new_fluid_player(m_synth);
	if (!m_player)
	{
		PrintFmt(PRINT_WARNING, "FluidSynth: Failed to create player\n");
		mem_fclose(midiData);
		return;
	}

	// Get the MIDI data from the MEMFILE
	byte* midiBuffer;
	size_t midiLength;

	if (needsFree)
	{
		// MUS was converted, get data from write buffer
		mem_get_buf(midiData, reinterpret_cast<void**>(&midiBuffer), &midiLength);
	}
	else
	{
		// Already MIDI, use original data
		midiBuffer = data;
		midiLength = length;
	}

	// Add the MIDI data to the player
	if (fluid_player_add_mem(m_player, midiBuffer, midiLength) != FLUID_OK)
	{
		PrintFmt(PRINT_WARNING, "FluidSynth: Failed to load MIDI data\n");
		delete_fluid_player(m_player);
		m_player = nullptr;
		mem_fclose(midiData);
		return;
	}

	mem_fclose(midiData);
	m_isPlaying = true;
}

void FluidSynthMusicSystem::applyCVars()
{
	if (!m_synth)
		return;

	if (m_isPlaying)
		Mix_HookMusic(nullptr, nullptr);

	// Update gain
	fluid_synth_set_gain(m_synth, snd_fluidsynthgain.value());

	// Update reverb (GZDoom settings)
	fluid_synth_reverb_on(m_synth, -1, snd_fluidsynthreverb ? 1 : 0);
	if (snd_fluidsynthreverb)
	{
		fluid_synth_set_reverb_group_roomsize(m_synth, -1, snd_fluidsynthreverbroomsize.value());
		fluid_synth_set_reverb_group_damp(m_synth, -1, snd_fluidsynthreverbdamping.value());
		fluid_synth_set_reverb_group_width(m_synth, -1, snd_fluidsynthreverbwidth.value());
		fluid_synth_set_reverb_group_level(m_synth, -1, snd_fluidsynthreverblevel.value());
	}

	// Update chorus (GZDoom settings)
	fluid_synth_chorus_on(m_synth, -1, snd_fluidsynthchorus ? 1 : 0);
	if (snd_fluidsynthchorus)
	{
		fluid_synth_set_chorus_group_nr(m_synth, -1, snd_fluidsynthchorusvoices.asInt());
		fluid_synth_set_chorus_group_level(m_synth, -1, snd_fluidsynthchoruslevel.value());
		fluid_synth_set_chorus_group_speed(m_synth, -1, snd_fluidsynthchorusspeed.value());
		fluid_synth_set_chorus_group_depth(m_synth, -1, snd_fluidsynthchorusdepth.value());
		fluid_synth_set_chorus_group_type(m_synth, -1, snd_fluidsynthchorustype.asInt());
	}

	// Update polyphony
	fluid_synth_set_polyphony(m_synth, snd_fluidsynthpolyphony.asInt());

	// Update interpolation
	int interp = snd_fluidsynthinterp.asInt();
	int interpMethod = FLUID_INTERP_LINEAR;
	switch (interp)
	{
	case 0:
		interpMethod = FLUID_INTERP_NONE;
		break;
	case 1:
		interpMethod = FLUID_INTERP_LINEAR;
		break;
	case 4:
		interpMethod = FLUID_INTERP_4THORDER;
		break;
	case 7:
		interpMethod = FLUID_INTERP_7THORDER;
		break;
	}
	fluid_synth_set_interp_method(m_synth, -1, interpMethod);

	if (m_isPlaying)
		_UpdateHook();
}
