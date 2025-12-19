//-----------------------------------------------------------------------------
//
// Copyright (C) 2006-2025 by The Odamex Team.
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
//  Plays music utilizing FluidSynth library for MIDI synthesis with
//  SoundFont support, matching GZDoom's audio output.
//
//-----------------------------------------------------------------------------

#pragma once

#include "i_midi.h"
#include "i_music.h"
#include "i_musicsystem.h"
#include <mutex>
#include <fluidsynth.h>

struct FluidSynthHookData
{
	fluid_synth_t* synth;
	bool paused;
	float volume;
	std::mutex* mutex;
};

/**
 * @brief Plays music utilizing the FluidSynth library with SoundFont support.
 */
class FluidSynthMusicSystem : public MusicSystem
{
  public:
	FluidSynthMusicSystem();
	~FluidSynthMusicSystem() override;

	void startSong(byte* data, size_t length, bool loop, int order) override;
	void stopSong() override;
	void pauseSong() override;
	void resumeSong() override;
	void playChunk() override { }
	void setVolume(float volume) override;
	void setTempo(float tempo) override { }

	bool isInitialized() const override { return m_isInitialized; }

	void applyCVars();

	// Only plays midi-type music
	bool isMusCapable() const override { return true; }
	bool isMidiCapable() const override { return true; }

  private:
	bool m_isInitialized = false;
	bool m_isPlaying = false;
	fluid_settings_t* m_settings = nullptr;
	fluid_synth_t* m_synth = nullptr;
	fluid_player_t* m_player = nullptr;
	int m_soundfontId = -1;
	FluidSynthHookData m_hookData;
	std::mutex m_mutex;

	void _StopSong();
	void _RegisterSong(byte* data, size_t length);
	void _UpdateHook();
	bool _LoadSoundfont();
};
