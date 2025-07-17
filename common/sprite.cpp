#include "odamex.h"

#include "sprite.h"
#include "info.h"
#include "doom_obj_container.h"

#include <stdlib.h>
#include <string.h>
#include <sstream>

//----------------------------------------------------------------------------------------------

void D_Initialize_sprnames(const char** source, size_t count, spritenum_t start)
{
	sprnames.clear();
    if (source)
    {
		sprnames.insert({source, count}, start);
        #if defined _DEBUG
	        Printf(PRINT_HIGH, "D_Allocate_sprnames:: allocated %d sprites.\n", count);
        #endif
    }
}

/**
 * @brief find the index for a given key
 * @param src_sprnames the sprite names to search for the index
 * @param key the key for a sprite either as a 4 character string or index value
 *            if it is not either, return -1.
 *            if the key is not found, return -1.
 * @param offset the offset for the odamex sprnames
 */
int D_FindOrgSpriteIndex(const char** src_sprnames, const char* key)
{
	int i = 0;
    // search the array for the sprite name you are looking for
	for (; src_sprnames[i]; ++i)
    {
        if(!strncmp(src_sprnames[i], key, 4))
        {
            return i;
        }
    }
    // check if this is an actual number - we aren't validating this index here
    std::istringstream stream(key);
    int spridx;
    bool ok = !(stream >> spridx).fail();
    return ok ? spridx : -1;
}
