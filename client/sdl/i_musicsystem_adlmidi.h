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
class AdlMidiMusicSystem : public MusicSystem
{
  public:
	AdlMidiMusicSystem();
	virtual ~AdlMidiMusicSystem();

	virtual void startSong(byte* data, size_t length, bool loop);
	virtual void stopSong();
	virtual void pauseSong();
	virtual void resumeSong();
	virtual void playChunk() { }
	virtual void setVolume(float volume);
	virtual void setTempo(float tempo) { }

	virtual bool isInitialized() const { return m_isInitialized; }

	virtual bool isMusCapable() const { return true; }
	virtual bool isMidiCapable() const { return true; }
	virtual bool isOggCapable() const { return true; }
	virtual bool isMp3Capable() const { return true; }
	virtual bool isModCapable() const { return true; }
	virtual bool isWaveCapable() const { return true; }

	void applyCVars();

  private:
	bool m_isInitialized;
	int m_songType;
	MusicHandler_t m_digitalSong;
	ADL_MIDIPlayer *m_midiPlayer;
	AdlMidiHookData m_midiHookData;

	void _StopSong();
	void _RegisterSong(byte* data, size_t length);
	void _UnregisterSong();
	void _UpdateMidiHook();
};
