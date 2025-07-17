#include "odamex.h"

#include "state.h"
#include "info.h"
#include "doom_obj_container.h"

void D_Initialize_States(state_t* source, int count)
{
	states.clear();
    states.reserve(count);
    if (source) {

    	state_t state_source;
    	int32_t state_statenum = -1;
        for(int i = 0; i < count; i++)
        {
        	state_source = source[i];
            state_statenum = state_source.statenum;
			states.insert(state_source, state_statenum);
        }
    }
#if defined _DEBUG
    Printf(PRINT_HIGH,"D_Initialize_states:: allocated %d states.\n", count);
#endif
}
