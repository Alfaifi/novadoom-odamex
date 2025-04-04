// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// $Id$
//
// Copyright (C) 1993-1996 by id Software, Inc.
// Copyright (C) 2006-2025 by The Odamex Team.
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
//	Stacktrace for more useful error messages
//  Adapted from https://github.com/iboB/b_stacktrace
//
//-----------------------------------------------------------------------------

#include "odamex.h"

#include "m_stacktrace.h"
#include "m_fileio.h"

#if defined(__linux__) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define B_STACKTRACE_MAX_DEPTH 1024

#if defined(_WIN32)

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <TlHelp32.h>
#include <DbgHelp.h>

#pragma comment(lib, "DbgHelp.lib")

#define B_STACKTRACE_ERROR_FLAG ((DWORD64)1 << 63)

struct traceentry_t {
    DWORD64 AddrPC_Offset;
    DWORD64 AddrReturn_Offset;
};

static int SymInitialize_called = 0;

std::string M_GetStacktrace() {
    HANDLE process = GetCurrentProcess();
    HANDLE thread = GetCurrentThread();
    CONTEXT context;
    STACKFRAME64 frame; /* in/out stackframe */
    DWORD imageType;
    std::vector<traceentry_t> entries;

    if (!SymInitialize_called) {
        SymInitialize(process, NULL, TRUE);
        SymInitialize_called = 1;
    }

    RtlCaptureContext(&context);

    memset(&frame, 0, sizeof(frame));
#ifdef _M_IX86
    imageType = IMAGE_FILE_MACHINE_I386;
    frame.AddrPC.Offset = context.Eip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = context.Ebp;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = context.Esp;
    frame.AddrStack.Mode = AddrModeFlat;
#elif _M_X64
    imageType = IMAGE_FILE_MACHINE_AMD64;
    frame.AddrPC.Offset = context.Rip;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = context.Rsp;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrStack.Offset = context.Rsp;
    frame.AddrStack.Mode = AddrModeFlat;
#elif _M_IA64
    imageType = IMAGE_FILE_MACHINE_IA64;
    frame.AddrPC.Offset = context.StIIP;
    frame.AddrPC.Mode = AddrModeFlat;
    frame.AddrFrame.Offset = context.IntSp;
    frame.AddrFrame.Mode = AddrModeFlat;
    frame.AddrBStore.Offset = context.RsBSP;
    frame.AddrBStore.Mode = AddrModeFlat;
    frame.AddrStack.Offset = context.IntSp;
    frame.AddrStack.Mode = AddrModeFlat;
#else
    #error "Platform not supported!"
#endif

    while (true) {
        traceentry_t& entry = entries.emplace_back();
        if (entries.size() == B_STACKTRACE_MAX_DEPTH) {
            entry.AddrPC_Offset = 0;
            entry.AddrReturn_Offset = 0;
            break;
        }

        if (!StackWalk64(imageType, process, thread, &frame, &context, NULL, SymFunctionTableAccess64, SymGetModuleBase64, NULL)) {
            entry.AddrPC_Offset = frame.AddrPC.Offset;
            entry.AddrReturn_Offset = B_STACKTRACE_ERROR_FLAG; /* mark error */
            entry.AddrReturn_Offset |= GetLastError();
            break;
        }

        entry.AddrPC_Offset = frame.AddrPC.Offset;
        entry.AddrReturn_Offset = frame.AddrReturn.Offset;

        if (frame.AddrReturn.Offset == 0) {
            break;
        }
    }

    std::string ret;
    IMAGEHLP_SYMBOL64* symbol = (IMAGEHLP_SYMBOL64*) M_Malloc(sizeof(IMAGEHLP_SYMBOL64) + 1024);
    symbol->SizeOfStruct = sizeof(IMAGEHLP_SYMBOL64);
    symbol->MaxNameLength = 1024;

    for (const auto& entry : nonstd::span(entries).subspan(1)) {
        IMAGEHLP_LINE64 lineData;
        DWORD lineOffset = 0;
        DWORD64 symOffset = 0;

        if (entry.AddrReturn_Offset & B_STACKTRACE_ERROR_FLAG) {
            DWORD error = entry.AddrReturn_Offset & 0xFFFFFFFF;
            ret += fmt::format("StackWalk64 error: {} @ {}\n", error, entry.AddrPC_Offset);
            break;
        }

        if (entry.AddrPC_Offset == entry.AddrReturn_Offset) {
            ret += fmt::format("Stack overflow @ {}\n", entry.AddrPC_Offset);
            break;
        }

        SymGetLineFromAddr64(process, entry.AddrPC_Offset, &lineOffset, &lineData);
        ret += fmt::format("{}({}): ", M_ExtractFileName(lineData.FileName), lineData.LineNumber);

        if (SymGetSymFromAddr64(process, entry.AddrPC_Offset, &symOffset, symbol)) {
            ret += fmt::format("{}\n", symbol->Name);
        }
        else {
            ret += fmt::format(" Unkown symbol @ {}\n", entry.AddrPC_Offset);
        }

        if (entry.AddrReturn_Offset == 0) {
            break;
        }
    }

    M_Free(symbol);
    return ret;
}

#elif defined(__APPLE__)

#include <execinfo.h>
#include <unistd.h>
#include <dlfcn.h>

typedef struct b_stacktrace {
    void* trace[B_STACKTRACE_MAX_DEPTH];
    int trace_size;
} b_stacktrace;

b_stacktrace_handle b_stacktrace_get(void) {
    b_stacktrace* ret = (b_stacktrace*)malloc(sizeof(b_stacktrace));
    ret->trace_size = backtrace(ret->trace, B_STACKTRACE_MAX_DEPTH);
    return (b_stacktrace_handle)(ret);
}

char* b_stacktrace_to_string(b_stacktrace_handle h) {
    const b_stacktrace* stacktrace = (b_stacktrace*)h;
    char** messages = backtrace_symbols(stacktrace->trace, stacktrace->trace_size);
    print_buf out = buf_init();
    *out.buf = 0;

    for (int i = 0; i < stacktrace->trace_size; ++i) {
        buf_printf(&out, "%s\n", messages[i]);
    }

    free(messages);
    return out.buf;
}

#elif defined(__linux__)

#include <execinfo.h>
#include <ucontext.h>
#include <unistd.h>
#include <dlfcn.h>
#include <string.h>

typedef struct b_stacktrace {
    void* trace[B_STACKTRACE_MAX_DEPTH];
    int trace_size;
} b_stacktrace;

b_stacktrace_handle b_stacktrace_get(void) {
    b_stacktrace* ret = (b_stacktrace*)malloc(sizeof(b_stacktrace));
    ret->trace_size = backtrace(ret->trace, B_STACKTRACE_MAX_DEPTH);
    return (b_stacktrace_handle)(ret);
}

char* b_stacktrace_to_string(b_stacktrace_handle h) {
    const b_stacktrace* stacktrace = (b_stacktrace*)h;
    char** messages = backtrace_symbols(stacktrace->trace, stacktrace->trace_size);
    print_buf out = buf_init();

    for (int i = 0; i < stacktrace->trace_size; ++i) {
        void* tracei = stacktrace->trace[i];
        char* msg = messages[i];

        /* calculate load offset */
        Dl_info info;
        dladdr(tracei, &info);
        if (info.dli_fbase == (void*)0x400000) {
            /* address from executable, so don't offset */
            info.dli_fbase = NULL;
        }

        while (*msg && *msg != '(') ++msg;
        *msg = 0;

        {
            char cmd[1024];
            char line[2048];

            FILE* fp;
            snprintf(cmd, 1024, "addr2line -e %s -f -C -p %p 2>/dev/null", messages[i], (void*)((char*)tracei - (char*)info.dli_fbase));

            fp = popen(cmd, "r");
            if (!fp) {
                buf_printf(&out, "Failed to generate trace further...\n");
                break;
            }

            while (fgets(line, sizeof(line), fp)) {
                buf_printf(&out, "%s: ", messages[i]);
                if (strstr(line, "?? ")) {
                    /* just output address if nothing can be found */
                    buf_printf(&out, "%p\n", tracei);
                }
                else {
                    buf_printf(&out, "%s", line);
                }
            }

            pclose(fp);
        }
    }

    free(messages);
    return out.buf;
}

#else

std::string M_GetStacktrace() {
    return "M_GetStacktrace: Unsupported platform.";
}

#endif
