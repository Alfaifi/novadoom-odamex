#pragma once

#include "info.h"

void D_Initialize_sprnames(const char** source, size_t count, spritenum_t start);
int D_FindOrgSpriteIndex(const char** src_sprnames, const char* key);
