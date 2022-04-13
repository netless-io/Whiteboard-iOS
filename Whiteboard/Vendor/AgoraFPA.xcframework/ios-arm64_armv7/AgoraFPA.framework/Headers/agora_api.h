//
//  Agora C SDK
//
//  Created by Tommy Miao in 2020.5
//  Copyright (c) 2020 Agora.io. All rights reserved.
//
#pragma once

#if defined(_WIN32)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif  // !WIN32_LEAN_AND_MEAN

#include <Windows.h>

#ifdef AGORARTC_EXPORT
#define AGORA_API_C __declspec(dllexport)
#else
#define AGORA_API_C __declspec(dllimport)
#endif  // AGORARTC_EXPORT

#define AGORA_CALL_C __cdecl

#elif defined(__APPLE__)

#include <TargetConditionals.h>

#define AGORA_API_C __attribute__((visibility("default")))
#define AGORA_CALL_C

#elif defined(__ANDROID__) || defined(__linux__)

#define AGORA_API_C __attribute__((visibility("default")))
#define AGORA_CALL_C

#else  // !_WIN32 && !__APPLE__ && !(__ANDROID__ || __linux__)

#define AGORA_API_C
#define AGORA_CALL_C

#endif  // _WIN32

#ifndef AGORA_HANDLE
#define AGORA_HANDLE void *
#endif  // AGORA_HANDLE

#define AGORA_API_C_VOID AGORA_API_C void AGORA_CALL_C
#define AGORA_API_C_INT AGORA_API_C int AGORA_CALL_C
#define AGORA_API_C_SIZE_T AGORA_API_C uint32_t AGORA_CALL_C
#define AGORA_API_C_HDL AGORA_API_C AGORA_HANDLE AGORA_CALL_C
#define AGORA_API_C_LITERAL AGORA_API_C const char* AGORA_CALL_C
