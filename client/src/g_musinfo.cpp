// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// $Id$
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
//	MUSINFO lump parsing.
//
//-----------------------------------------------------------------------------

#include "odamex.h"

#include "g_level.h"
#include "g_musinfo.h"
#include "oscanner.h"
#include "w_wad.h"

void G_ParseMusInfo()
{
	int lump = -1;
	while ((lump = W_FindLump("MUSINFO", lump)) != -1)
	{
		LevelInfos& levels = getLevelInfos();
		const char* buffer = static_cast<char*>(W_CacheLumpNum(lump, PU_STATIC));

		const OScannerConfig config = {
		    "MUSINFO", // lumpName
		    false,     // semiComments
		    false,     // cComments
		};
		OScanner os = OScanner::openBuffer(config, buffer, buffer + W_LumpLength(lump));

		while (os.scan())
		{
			const std::string map_name = os.getToken();
			level_pwad_info_t& map = levels.findByName(map_name);

			if (!map.exists())
			{
				// Don't abort for invalid maps
				os.warning("Unknown map '{}'", map_name);
			}

			while (os.scan())
			{
				if (!IsNum(os.getToken().c_str()))
				{
					os.unScan();
					break;
				}

				const int index = os.getTokenInt();
				os.mustScan();

				if (index > 0)
				{
					const std::string music = os.getToken();
					if (map.exists())
					{
						map.musinfo_map[index] = music;
					}
				}
			}
		}
	}
}
