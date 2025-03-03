//-----------------------------------------------------------------------------
//
// Copyright (C) 2006-2020 by The Odamex Team.
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
//  Plays music utilizing libADLMIDI library for MIDI and SDL_Mixer
//  for other formats.
//
//-----------------------------------------------------------------------------

#pragma once

#include "i_midi.h"
#include "i_music.h"
#include "i_musicsystem.h"

struct ADL_MIDIPlayer;

struct AdlMidiHookData
{
	ADL_MIDIPlayer *player;
	bool paused;
	float volume;
};

/**
 * @brief Plays music utilizing the libADLMIDI music library.
 */
class AdlMidiMusicSystem : public MidiMusicSystem
{
  public:
	AdlMidiMusicSystem();
	~AdlMidiMusicSystem() override;

	void startSong(byte* data, size_t length, bool loop) override;
	void stopSong() override;
	void pauseSong() override;
	void resumeSong() override;
	void playChunk() override { }
	void setVolume(float volume) override;
	void setTempo(float tempo) override { }

	bool isInitialized() const override { return m_isInitialized; }

	void applyCVars();

	// TODO: actually see if these need real implementations
	void writeVolume(int time, byte channel, byte volume) override {};
	void writeControl(int time, byte channel, byte control, byte value) override {};
	void writeChannel(int time, byte channel, byte status, byte param1, byte param2 = 0) override {};
	void writeSysEx(int time, const byte *data, size_t length) override {};
	void allNotesOff() override {};
	void allSoundOff() override {};

  private:
	bool m_isInitialized = false;
	bool m_isPlaying = false;
	ADL_MIDIPlayer *m_midiPlayer;
	AdlMidiHookData m_midiHookData;

	void _StopSong();
	void _RegisterSong(byte* data, size_t length);
	void _UpdateMidiHook();
};
