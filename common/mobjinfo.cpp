#include "odamex.h"

#include "mobjinfo.h"
#include "info.h"
#include "m_doomobjcontainer.h"

void D_Initialize_Mobjinfo(mobjinfo_t* source, int count)
{

	// initialize the associative array
	mobjinfo.clear();
    mobjinfo.reserve(count);
	spawn_map.clear();
	if (source)
	{

		mobjinfo_t mobjinfo_source;
		int32_t idx = 0;
		for(int i = 0; i < count; ++i)
		{
			mobjinfo_source = source[i];
			idx = mobjinfo_source.type;

			mobjinfo.insert(mobjinfo_source, idx);

			// [CMB] check for invalid index (-1 or 0xFFFF)
			if (mobjinfo_source.doomednum != 0xFFFF)
			{
				mobjinfo_t* spawn_info = &mobjinfo.find(idx)->second;
				spawn_map.insert(spawn_info, mobjinfo_source.doomednum);
			}
		}
	}
#if defined _DEBUG
    Printf(PRINT_HIGH,"D_Allocate_mobjinfo:: allocated %d actors.\n", count);
#endif
}
