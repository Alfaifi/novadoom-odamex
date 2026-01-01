// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// $Id$
//
// Copyright (C) 1993-1996 by id Software, Inc.
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
//
// DESCRIPTION:
//	Main program, simply calls D_DoomMain high level loop.
//
//-----------------------------------------------------------------------------


#include "novadoom.h"

#ifdef UNIX
// for getuid and geteuid
#include <unistd.h>
#include <sys/types.h>
#endif

#include <new>
#include <stack>
#include <iostream>

#include "i_sdl.h"
#include "i_crash.h"
// [Russell] - Don't need SDLmain library
#ifdef _WIN32
#undef main
#endif // WIN32

// On macOS, SDLMain.m provides the entry point and calls SDL_main
#ifdef __APPLE__
#define main SDL_main
extern "C" int SDL_main(int argc, char *argv[]);
#endif


#include "m_argv.h"
#include "m_fileio.h"
#include "d_main.h"
#include "i_system.h"
#include "c_console.h"
#include "z_zone.h"

#ifdef _WIN32
#include "win32inc.h"
#include <shlwapi.h>

// Register novadoom:// URL protocol handler in Windows Registry
static bool RegisterURLHandler()
{
	char exePath[MAX_PATH];
	if (GetModuleFileNameA(NULL, exePath, MAX_PATH) == 0)
		return false;

	// Create the protocol key
	HKEY hKey;
	LONG result = RegCreateKeyExA(HKEY_CURRENT_USER,
		"Software\\Classes\\novadoom", 0, NULL,
		REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL);
	if (result != ERROR_SUCCESS)
		return false;

	// Set default value
	const char* protocolDesc = "URL:NovaDoom Protocol";
	RegSetValueExA(hKey, NULL, 0, REG_SZ, (BYTE*)protocolDesc, strlen(protocolDesc) + 1);

	// Set URL Protocol (empty string indicates this is a URL protocol)
	RegSetValueExA(hKey, "URL Protocol", 0, REG_SZ, (BYTE*)"", 1);
	RegCloseKey(hKey);

	// Create DefaultIcon key
	result = RegCreateKeyExA(HKEY_CURRENT_USER,
		"Software\\Classes\\novadoom\\DefaultIcon", 0, NULL,
		REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL);
	if (result == ERROR_SUCCESS)
	{
		char iconPath[MAX_PATH + 8];
		snprintf(iconPath, sizeof(iconPath), "\"%s\",0", exePath);
		RegSetValueExA(hKey, NULL, 0, REG_SZ, (BYTE*)iconPath, strlen(iconPath) + 1);
		RegCloseKey(hKey);
	}

	// Create shell\open\command key
	result = RegCreateKeyExA(HKEY_CURRENT_USER,
		"Software\\Classes\\novadoom\\shell\\open\\command", 0, NULL,
		REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL);
	if (result != ERROR_SUCCESS)
		return false;

	// Set command: "C:\path\to\novadoom.exe" "%1"
	char command[MAX_PATH * 2];
	snprintf(command, sizeof(command), "\"%s\" \"%%1\"", exePath);
	RegSetValueExA(hKey, NULL, 0, REG_SZ, (BYTE*)command, strlen(command) + 1);
	RegCloseKey(hKey);

	return true;
}

// Unregister novadoom:// URL protocol handler
static bool UnregisterURLHandler()
{
	// Delete the entire novadoom key tree
	LONG result = RegDeleteTreeA(HKEY_CURRENT_USER, "Software\\Classes\\novadoom");
	return (result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND);
}

// Check if URL handler is registered
static bool IsURLHandlerRegistered()
{
	HKEY hKey;
	LONG result = RegOpenKeyExA(HKEY_CURRENT_USER,
		"Software\\Classes\\novadoom\\shell\\open\\command",
		0, KEY_READ, &hKey);
	if (result == ERROR_SUCCESS)
	{
		RegCloseKey(hKey);
		return true;
	}
	return false;
}
#endif // _WIN32

// Use main() on windows for msvc
#if defined(_MSC_VER)
#    pragma comment(linker, "/subsystem:windows /ENTRY:mainCRTStartup")
#endif

EXTERN_CVAR (r_centerwindow)

DArgs Args;

// functions to be called at shutdown are stored in this stack
typedef void (STACK_ARGS *term_func_t)(void);
std::stack< std::pair<term_func_t, std::string> > TermFuncs;

void addterm (void (STACK_ARGS *func) (), const char *name)
{
	TermFuncs.push(std::pair<term_func_t, std::string>(func, name));
}

void STACK_ARGS call_terms (void)
{
	while (!TermFuncs.empty())
		TermFuncs.top().first(), TermFuncs.pop();
}

int main(int argc, char *argv[])
{
	// [AM] Set crash callbacks, so we get something useful from crashes.
#ifdef NDEBUG
	I_SetCrashCallbacks();
#endif

	try
	{

#if defined(UNIX)
		if(!getuid() || !geteuid())
			I_FatalError("root user detected, quitting novadoom immediately");
#endif

		// [ML] 2007/9/3: From Eternity (originally chocolate Doom) Thanks SoM & fraggle!
		::Args.SetArgs(argc, argv);

		if (::Args.CheckParm("--version"))
		{
#ifdef _WIN32
			FILE* fh = fopen("novadoom-version.txt", "w");
			if (!fh)
				exit(EXIT_FAILURE);

			const int ok = fprintf(fh, "NovaDoom %s\n", NiceVersion());
			if (!ok)
				exit(EXIT_FAILURE);

			fclose(fh);
#else
			fmt::print("NovaDoom {}\n", NiceVersion());
#endif
			exit(EXIT_SUCCESS);
		}

#ifdef _WIN32
		// Handle URL protocol registration commands
		if (::Args.CheckParm("--register-url") || ::Args.CheckParm("-registerurl"))
		{
			if (RegisterURLHandler())
			{
				MessageBoxA(NULL, "NovaDoom URL handler registered successfully!\n\n"
					"You can now click novadoom:// links in your browser to connect to servers.",
					"NovaDoom", MB_OK | MB_ICONINFORMATION);
				exit(EXIT_SUCCESS);
			}
			else
			{
				MessageBoxA(NULL, "Failed to register URL handler.\n\n"
					"Try running NovaDoom as administrator.",
					"NovaDoom", MB_OK | MB_ICONERROR);
				exit(EXIT_FAILURE);
			}
		}

		if (::Args.CheckParm("--unregister-url") || ::Args.CheckParm("-unregisterurl"))
		{
			if (UnregisterURLHandler())
			{
				MessageBoxA(NULL, "NovaDoom URL handler unregistered successfully.",
					"NovaDoom", MB_OK | MB_ICONINFORMATION);
				exit(EXIT_SUCCESS);
			}
			else
			{
				MessageBoxA(NULL, "Failed to unregister URL handler.",
					"NovaDoom", MB_OK | MB_ICONERROR);
				exit(EXIT_FAILURE);
			}
		}
#endif

		const char* crashdir = ::Args.CheckValue("-crashdir");
		if (crashdir)
		{
			I_SetCrashDir(crashdir);
		}
		else
		{
			std::string writedir = M_GetWriteDir();
			I_SetCrashDir(writedir.c_str());
		}

		const char* CON_FILE = ::Args.CheckValue("-confile");
		if (CON_FILE)
		{
			CON.open(CON_FILE, std::ios::in);
		}

		// Handle novadoom:// protocol URLs (e.g., novadoom://connect/host:port?password=xxx)
		if(argc == 2 && argv && argv[1])
		{
			static constexpr std::string_view protocol = "novadoom://";
			std::string_view uri = argv[1];

			if(uri.substr(0, protocol.length()) == protocol)
			{
				std::string_view remainder = uri.substr(protocol.length());

				// Check for "connect/" prefix (optional, for future extensibility)
				static constexpr std::string_view connect_prefix = "connect/";
				if(remainder.substr(0, connect_prefix.length()) == connect_prefix)
				{
					remainder = remainder.substr(connect_prefix.length());
				}

				// Split on '?' to separate host:port from query params
				size_t query_pos = remainder.find('?');
				std::string_view host_port = remainder.substr(0, query_pos);
				std::string_view query = (query_pos != std::string::npos)
					? remainder.substr(query_pos + 1)
					: std::string_view{};

				// Remove any trailing slashes from host:port
				while(!host_port.empty() && host_port.back() == '/')
					host_port.remove_suffix(1);

				if(!host_port.empty())
				{
					Args.AppendArg("-connect");
					Args.AppendArg(std::string(host_port).c_str());

					// Parse password from query string (password=xxx)
					static constexpr std::string_view pwd_prefix = "password=";
					size_t pwd_pos = query.find(pwd_prefix);
					if(pwd_pos != std::string::npos)
					{
						std::string_view password = query.substr(pwd_pos + pwd_prefix.length());
						// Find end of password value (& or end of string)
						size_t pwd_end = password.find('&');
						if(pwd_end != std::string::npos)
							password = password.substr(0, pwd_end);

						if(!password.empty())
						{
							Args.AppendArg(std::string(password).c_str());
						}
					}

					// Parse player name from query string (name=xxx)
					static constexpr std::string_view name_prefix = "name=";
					size_t name_pos = query.find(name_prefix);
					if(name_pos != std::string::npos)
					{
						std::string_view name = query.substr(name_pos + name_prefix.length());
						// Find end of name value (& or end of string)
						size_t name_end = name.find('&');
						if(name_end != std::string::npos)
							name = name.substr(0, name_end);

						if(!name.empty())
						{
							// Use -name parameter for explicit handling
							Args.AppendArg("-name");
							Args.AppendArg(std::string(name).c_str());
						}
					}
				}
			}
		}

		unsigned int sdl_flags = SDL_INIT_TIMER;

#ifdef _MSC_VER
		// [SL] per the SDL documentation, SDL's parachute, used to cleanup
		// after a crash, causes the MSVC debugger to be unusable
		sdl_flags |= SDL_INIT_NOPARACHUTE;
#endif

		if (SDL_Init(sdl_flags) == -1)
			I_FatalError("Could not initialize SDL:\n{}\n", SDL_GetError());

		atterm (SDL_Quit);

		/*
		killough 1/98:

		  This fixes some problems with exit handling
		  during abnormal situations.

			The old code called I_Quit() to end program,
			while now I_Quit() is installed as an exit
			handler and exit() is called to exit, either
			normally or abnormally.
		*/

        // But avoid calling this on windows!
        // Good on some platforms, useless on others
//		#ifndef _WIN32
//		atexit (call_terms);
//		#endif

		atterm (I_Quit);
		atterm (DObject::StaticShutdown);

		D_DoomMain(); // Usually does not return

		// If D_DoomMain does return (as is the case with the +demotest parameter)
		// proper termination needs to occur -- Hyper_Eye
		call_terms ();
	}
	catch (CDoomError &error)
	{
		if (LOG.is_open())
		{
			LOG << "=== ERROR: " << error.GetMsg() << " ===\n\n";
		}

		I_ErrorMessageBox(error.GetMsg().c_str());

		call_terms();
		exit(EXIT_FAILURE);
	}
#ifndef _DEBUG
	catch (...)
	{
		// If an exception is thrown, be sure to do a proper shutdown.
		// This is especially important if we are in fullscreen mode,
		// because the OS will only show the alert box if we are in
		// windowed mode. Graphics gets shut down first in case something
		// goes wrong calling the cleanup functions.
		call_terms ();
		// Now let somebody who understands the exception deal with it.
		throw;
	}
#endif
	return 0;
}

VERSION_CONTROL (i_main_cpp, "$Id$")
