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
// DESCRIPTION:
//	File Input/Output Operations for windows-like platforms.
//
//-----------------------------------------------------------------------------


#if defined(_WIN32)

#if defined(UNIX)
#error "_WIN32 is mutually exclusive with UNIX"
#endif

#include "novadoom.h"

#include "m_fileio.h"

#include "win32inc.h"
#include <shlobj.h>
#include <shlwapi.h>
#include <nonstd/scope.hpp>
#include <cstdio>

#include <filesystem>
namespace fs = std::filesystem;

#include "i_system.h"

/**
 * @brief Helper to create the user directory and return its path.
 */
static std::string CreateAndGetUserDir()
{
	std::string userPath = M_GetUserDir();
	int ok = SHCreateDirectoryEx(NULL, userPath.c_str(), NULL);
	if (ok == ERROR_SUCCESS || ok == ERROR_ALREADY_EXISTS)
	{
		return M_CleanPath(userPath);
	}
	// I_FatalError does not return
	I_FatalError("Failed to create {} directory.\n", userPath);
	return "";  // Unreachable, but silences compiler warning
}

/**
 * @brief Test if we can write to the given directory.
 */
static bool CanWriteToDir(const std::string& dir)
{
	std::string testFile = dir + PATHSEP ".novadoom-write-test";
	FILE* f = fopen(testFile.c_str(), "w");
	if (f)
	{
		fclose(f);
		remove(testFile.c_str());
		return true;
	}
	return false;
}

std::string M_GetBinaryDir()
{
	std::string ret;

	char tmp[MAX_PATH]; // denis - todo - make separate function
	GetModuleFileName(NULL, tmp, sizeof(tmp));
	ret = tmp;

	M_FixPathSep(ret);

	size_t slash = ret.find_last_of(PATHSEPCHAR);
	if (slash == std::string::npos)
	{
		return "";
	}

	return ret.substr(0, slash);
}

std::string M_GetHomeDir(const std::string& user)
{
	PWSTR folderPath;
	if (!SUCCEEDED(SHGetKnownFolderPath(FOLDERID_Profile, 0, NULL, &folderPath)))
	{
		I_FatalError("Could not get user's personal folder.\n");
	}

	fs::path path(folderPath);

	CoTaskMemFree(folderPath);

	return path.string();
}

std::string M_GetUserDir()
{
	PWSTR folderPath;
	if (!SUCCEEDED(SHGetKnownFolderPath(FOLDERID_Documents, 0, NULL, &folderPath)))
	{
		I_FatalError("Could not get user's personal folder.\n");
	}

	fs::path path(folderPath);

	CoTaskMemFree(folderPath);

	return (path / "My Games" / "NovaDoom").string();
}

std::string M_GetWriteDir()
{
	std::string binDir = M_GetBinaryDir();

	// Check for explicit installed mode marker file
	std::string installed = binDir + PATHSEP "novadoom-installed.txt";
	if (M_FileExists(installed))
	{
		return CreateAndGetUserDir();
	}

	// Check for explicit portable mode marker file
	// If this exists, always use binary directory (for USB drives, etc.)
	std::string portable = binDir + PATHSEP "novadoom-portable.txt";
	if (M_FileExists(portable))
	{
		return M_CleanPath(binDir);
	}

	// Auto-detect: Try to write to the binary directory
	// If we can't write (e.g., Program Files), fall back to Documents folder
	// This prevents UAC virtualization issues where config ends up in VirtualStore
	if (CanWriteToDir(binDir))
	{
		return M_CleanPath(binDir);
	}

	// Can't write to binary directory, use Documents folder
	return CreateAndGetUserDir();
}

#endif
