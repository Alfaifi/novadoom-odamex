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
//  Plays music utilizing the SDL_Mixer library and can handle a wide range
//  of music formats.
//
//-----------------------------------------------------------------------------

#include "odamex.h"

#include "i_musicsystem_adlmidi.h"

#include "i_sdl.h"
#include <SDL_mixer.h>
#include "adlmidi.h"

#include "i_music.h"

EXTERN_CVAR(snd_samplerate)
EXTERN_CVAR(snd_musicvolume)
EXTERN_CVAR(snd_oplcore)
EXTERN_CVAR(snd_oplpan)
EXTERN_CVAR(snd_oplchips)
EXTERN_CVAR(snd_oplbank)


extern MusicSystem* musicsystem;
extern MusicSystemType current_musicsystem_type;

CVAR_FUNC_IMPL (snd_oplcore)
{
	if (current_musicsystem_type == MS_LIBADLMIDI)
		static_cast<AdlMidiMusicSystem *>(musicsystem)->applyCVars();
}
CVAR_FUNC_IMPL (snd_oplpan)
{
	if (current_musicsystem_type == MS_LIBADLMIDI)
		static_cast<AdlMidiMusicSystem *>(musicsystem)->applyCVars();
}
CVAR_FUNC_IMPL (snd_oplchips)
{
	if (current_musicsystem_type == MS_LIBADLMIDI)
		static_cast<AdlMidiMusicSystem *>(musicsystem)->applyCVars();
}
CVAR_FUNC_IMPL (snd_oplbank)
{
	if (current_musicsystem_type == MS_LIBADLMIDI)
		static_cast<AdlMidiMusicSystem *>(musicsystem)->applyCVars();
}


typedef enum
{
	SONGTYPE_NONE = 0,
	SONGTYPE_MIDI = 1,
	SONGTYPE_DIGITAL = 2
} SongType;

static int oplCoreMap[] = {ADLMIDI_EMU_DOSBOX, ADLMIDI_EMU_NUKED_174, ADLMIDI_EMU_NUKED};
static int oplBankMap[] = {16, 14, 72};


AdlMidiMusicSystem::AdlMidiMusicSystem() : m_isInitialized(false), m_songType(SONGTYPE_NONE), m_digitalSong()
{
	// Midi mapper volume can interfere with PCM volume on some windows versions, ensure that it's set properly
	I_ResetMidiVolume();

	m_midiPlayer = adl_init(static_cast<int>(snd_samplerate));
	if (!m_midiPlayer)
	{
		Printf(PRINT_WARNING, "I_InitMusic: Failed to initialize libADLMIDI with sample rate %shz", snd_samplerate.cstring());
		return;
	}
	else
		Printf("I_InitMusic: Music playback enabled using libADLMIDI.\n");

	m_isInitialized = true;

	applyCVars();
}

AdlMidiMusicSystem::~AdlMidiMusicSystem()
{
	if (!isInitialized())
		return;

	Mix_HaltMusic();
	_StopSong();

	adl_close(m_midiPlayer);
}


// adlmidi_music_hook()
// Mix_HookMusic callback installed during OPL music playback
static void adlmidi_music_hook (void *data, byte *stream, int len)
{
	AdlMidiHookData *hdata = static_cast<AdlMidiHookData *>(data);
	if (hdata->paused)
		return;

	ADLMIDI_AudioFormat fmt;
	fmt.type = ADLMIDI_SampleType_S16;
	fmt.containerSize = 2;
	fmt.sampleOffset = 4;

	// Generate samples to fill the music buffer
	int out_count = adl_playFormat(hdata->player, len / fmt.containerSize, stream, stream + fmt.containerSize, &fmt);
	if (out_count < 0)
		memset(stream, 0, len);

	// Samples are generated at full volume, so iterate over them and scale them by the specified volume
	for (int i = 0; i < len; i += 2)
	{
		int16_t samp;
		memcpy(&samp, stream + i, 2);
		samp = clamp(samp * hdata->volume, -32768.f, 32767.f);
		memcpy(stream + i, &samp, 2);
	}
}


void AdlMidiMusicSystem::startSong(byte* data, size_t length, bool loop)
{
	if (!isInitialized())
		return;

	stopSong();

	if (!data || !length)
		return;

	_RegisterSong(data, length);

	switch (m_songType)
	{
	case SONGTYPE_NONE: return;

	case SONGTYPE_MIDI:
		adl_setLoopEnabled(m_midiPlayer, loop);
		_UpdateMidiHook();
		break;

	case SONGTYPE_DIGITAL:
		Mix_HaltMusic();
		if (Mix_PlayMusic(m_digitalSong.Track, loop ? -1 : 1) == -1)
		{
			Printf(PRINT_WARNING, "Mix_PlayMusic: %s\n", Mix_GetError());
			_UnregisterSong();
			return;
		}
		break;
	}

	MusicSystem::startSong(data, length, loop);
}

//
// AdlMidiMusicSystem::_StopSong()
//
// Fades the current music out and frees the data structures used for the
// current song with _UnregisterSong().
//
void AdlMidiMusicSystem::_StopSong()
{
	if (!isInitialized() || !isPlaying())
		return;

	switch (m_songType)
	{
	case SONGTYPE_NONE: return;

	case SONGTYPE_MIDI:
		Mix_HookMusic(NULL, NULL);
		break;
	case SONGTYPE_DIGITAL:
		if (!isPaused())
			Mix_FadeOutMusic(100);
		break;
	}

	_UnregisterSong();
}

//
// AdlMidiMusicSystem::stopSong()
//
// [SL] 2011-12-16 - This function simply calls _StopSong().  Since stopSong()
// is a virtual function, calls to it should be avoided in ctors & dtors.  Our
// dtor calls the non-virtual function _StopSong() instead and the virtual
// function stopSong() might as well reuse the code in _StopSong().
//
void AdlMidiMusicSystem::stopSong()
{
	_StopSong();
	MusicSystem::stopSong();
}

void AdlMidiMusicSystem::pauseSong()
{
	MusicSystem::pauseSong();

	switch (m_songType)
	{
	case SONGTYPE_NONE: return;

	case SONGTYPE_MIDI:
		_UpdateMidiHook();
		break;
	case SONGTYPE_DIGITAL:
		Mix_PauseMusic();
		break;
	}
}

void AdlMidiMusicSystem::resumeSong()
{
	MusicSystem::resumeSong();

	switch (m_songType)
	{
	case SONGTYPE_NONE: return;

	case SONGTYPE_MIDI:
		_UpdateMidiHook();
		break;
	case SONGTYPE_DIGITAL:
		Mix_ResumeMusic();
		break;
	}
}



//
// AdlMidiMusicSystem::setVolume
//
// Sanity checks the volume parameter and then sets the volume for the midi
// output mixer channel.  Note that Windows Vista/7 combines the volume control
// for the audio and midi channels and changing the midi volume also changes
// the SFX volume.
void AdlMidiMusicSystem::setVolume(float volume)
{
	MusicSystem::setVolume(volume);

	_UpdateMidiHook();
	Mix_VolumeMusic(int(getVolume() * MIX_MAX_VOLUME));
}


void AdlMidiMusicSystem::_UpdateMidiHook()
{
	if (m_songType != SONGTYPE_MIDI)
		return;

	SDL_LockAudio();
	m_midiHookData.player = m_midiPlayer;
	m_midiHookData.paused = isPaused();
	m_midiHookData.volume = getVolume();
	SDL_UnlockAudio();

	Mix_HookMusic(adlmidi_music_hook, &m_midiHookData);
}


//
// AdlMidiMusicSystem::_UnregisterSong
//
// Frees the data structures that store the song.  Called when stopping song.
//
void AdlMidiMusicSystem::_UnregisterSong()
{
	if (!isInitialized())
		return;

	if (m_digitalSong.Track)
		Mix_FreeMusic(m_digitalSong.Track);

	m_digitalSong.Track = NULL;
	m_digitalSong.Data = NULL;
	if (m_digitalSong.Mem != NULL)
	{
		mem_fclose(m_digitalSong.Mem);
		m_digitalSong.Mem = NULL;
	}

	m_songType = SONGTYPE_NONE;
}

//
// AdlMidiMusicSystem::_RegisterSong
//
// Determines the format of music data and allocates the memory for the music
// data if appropriate.  Note that _UnregisterSong should be called after
// playing to free the allocated memory.
void AdlMidiMusicSystem::_RegisterSong(byte* data, size_t length)
{
	_UnregisterSong();

	if (S_MusicIsMus(data, length) || S_MusicIsMidi(data, length))
	{
		adl_reset(m_midiPlayer);
		if (adl_openData(m_midiPlayer, data, length) < 0)
		{
			Printf(PRINT_WARNING, "Mix_PlayMusic: %s\n", adl_errorInfo(m_midiPlayer));
			return;
		}

		m_songType = SONGTYPE_MIDI;
	}
	else
	{
		m_digitalSong.Data = SDL_RWFromMem(data, length);

		if (!m_digitalSong.Data)
		{
			Printf(PRINT_WARNING, "SDL_RWFromMem: %s\n", SDL_GetError());
			return;
		}

	// We can read the midi data directly from memory
	#ifdef SDL20
		m_digitalSong.Track = Mix_LoadMUS_RW(m_digitalSong.Data, 0);
	#elif defined SDL12
		m_digitalSong.Track = Mix_LoadMUS_RW(m_digitalSong.Data);
	#endif // SDL12

		if (!m_digitalSong.Track)
		{
			Printf(PRINT_WARNING, "Mix_LoadMUS_RW: %s\n", Mix_GetError());
			return;
		}

		m_songType = SONGTYPE_DIGITAL;
	}
}


void AdlMidiMusicSystem::applyCVars()
{
	if (m_songType == SONGTYPE_MIDI)
		Mix_HookMusic(NULL, NULL);

	adl_switchEmulator(m_midiPlayer, oplCoreMap[static_cast<int>(snd_oplcore)]);
	adl_setSoftPanEnabled(m_midiPlayer, snd_oplpan);
	adl_setNumChips(m_midiPlayer, snd_oplchips);
	adl_setBank(m_midiPlayer, oplBankMap[static_cast<int>(snd_oplbank)]);

	if (m_songType == SONGTYPE_MIDI)
		_UpdateMidiHook();
}