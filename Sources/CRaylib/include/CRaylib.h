// The headers Swift imports as CRaylib. The raylib sources don't include this file.
#ifndef CRAYLIB_H
#define CRAYLIB_H

#include "../raylib/raylib.h"

// Without an implementation define, raymath declares plain C99 inline functions;
// static inline gives Swift its own copy of each and keeps the symbols out of the link.
#define RAYMATH_STATIC_INLINE
#include "../raylib/raymath.h"

#include "../raylib/rlgl.h"

#endif
