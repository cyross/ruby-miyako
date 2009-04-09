/*
--
Miyako v2.0 Extend Library "Miyako no Katana"
Copyright (C) 2008  Cyross Makoto

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
++
*/

#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_endian.h>
#include <stdlib.h>
#include <math.h>
#include "ruby.h"
#include "ruby/encoding.h"

typedef struct
{
	SDL_Surface* surface;
} Surface;

typedef struct
{
	Uint32 r;
	Uint32 g;
	Uint32 b;
	Uint32 a;
} MiyakoColor;

typedef struct
{
  int w;
  int h;
} MiyakoSize;

typedef struct
{
  VALUE unit;
  SDL_Surface *surface;
  SDL_PixelFormat *fmt;
  SDL_Rect rect;
  MiyakoColor color;
	Uint32 a255;
  Uint32 *ptr;
  int x;
  int y;
} MiyakoBitmap;

// from rubysdl.h
#define GLOBAL_DEFINE_GET_STRUCT(struct_name, fun, klass, klassstr) \
struct_name* fun(VALUE obj) \
{ \
  struct_name* st; \
  \
  if(!rb_obj_is_kind_of(obj, klass)){ \
    rb_raise(rb_eTypeError, "wrong argument type %s (expected " klassstr ")", \
             rb_obj_classname(obj)); \
  } \
  Data_Get_Struct(obj, struct_name, st); \
  return st; \
} 

#define MIYAKO_GETCOLOR(COLOR) \
	COLOR.r = (Uint32)(((pixel & fmt->Rmask) >> fmt->Rshift) << fmt->Rloss); \
	COLOR.g = (Uint32)(((pixel & fmt->Gmask) >> fmt->Gshift) << fmt->Gloss); \
	COLOR.b = (Uint32)(((pixel & fmt->Bmask) >> fmt->Bshift) << fmt->Bloss); \
	COLOR.a = (Uint32)(((pixel & fmt->Amask) >> fmt->Ashift) << fmt->Aloss);

#define MIYAKO_SETCOLOR(RESULT, COLOR) \
  RESULT = (COLOR.r >> fmt->Rloss) << fmt->Rshift | \
           (COLOR.g >> fmt->Gloss) << fmt->Gshift | \
           (COLOR.b >> fmt->Bloss) << fmt->Bshift | \
           (COLOR.a >> fmt->Aloss) << fmt->Ashift;

#define MIYAKO_SET_RECT(RECT, BASE) \
  RECT.x = NUM2INT(*(RSTRUCT_PTR(BASE) + 1)); \
  RECT.y = NUM2INT(*(RSTRUCT_PTR(BASE) + 2)); \
  RECT.w = NUM2INT(*(RSTRUCT_PTR(BASE) + 3)); \
  RECT.h = NUM2INT(*(RSTRUCT_PTR(BASE) + 4));

#define MIYAKO_INIT_RECT1 \
	int dlx = drect.x + x; \
	int dly = drect.y + y; \
	int dmx = dlx + (srect.w < drect.w ? srect.w : drect.w); \
	int dmy = dly + (srect.h < drect.h ? srect.h : drect.h);
  
#define MIYAKO_INIT_RECT2 \
	int dlx = drect.x; \
	int dly = drect.y; \
	int dmx = dlx + drect.w; \
	int dmy = dly + drect.h;

#define MIYAKO_INIT_RECT3 \
  if(s2rect.w != drect.w){ return Qnil; } \
  if(s2rect.h != drect.h){ return Qnil; } \
  int x1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 5)); \
  int y1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 6)); \
  int x2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 5)); \
  int y2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 6)); \
  if(s1rect.x < 0 || s1rect.y < 0 || s2rect.x < 0 || s2rect.y < 0){ return Qnil; } \
  if(s1rect.w < s2rect.w && (x1+s1rect.x+s1rect.w > s2rect.w)){ return Qnil; } \
  if(s2rect.w < s1rect.w && (x2+s2rect.x+s2rect.w > s1rect.w)){ return Qnil; } \
  if(s1rect.h < s2rect.h && (y1+s1rect.y+s1rect.h > s2rect.h)){ return Qnil; } \
  if(s2rect.h < s1rect.h && (y2+s2rect.y+s2rect.h > s1rect.h)){ return Qnil; } \
	int dlx = drect.x; \
	int dly = drect.y; \
	int dmx = dlx + (s1rect.w < s2rect.w ? s1rect.w : s2rect.w); \
	int dmy = dly + (s1rect.h < s2rect.h ? s1rect.h : s2rect.h);
  
#define MIYAKO_PSET(XX,YY) \
        pixel = 0; \
        if(dcolor.a == 0) \
        { \
          *(pdst + YY * dst->w + XX) = (scolor.r >> fmt->Rloss) << fmt->Rshift | \
                                       (scolor.g >> fmt->Gloss) << fmt->Gshift | \
                                       (scolor.b >> fmt->Bloss) << fmt->Bshift | \
                                       (scolor.a >> fmt->Aloss) << fmt->Ashift; \
          continue; \
        } \
        if(scolor.a > 0) \
        { \
          int a1 = scolor.a + 1; \
          int a2 = 256 - scolor.a; \
          scolor.r = (scolor.r * a1 + dcolor.r * a2) >> 8; \
          scolor.g = (scolor.g * a1 + dcolor.g * a2) >> 8; \
          scolor.b = (scolor.b * a1 + dcolor.b * a2) >> 8; \
          *(pdst + YY * dst->w + XX) = (scolor.r >> fmt->Rloss) << fmt->Rshift | \
                                       (scolor.g >> fmt->Gloss) << fmt->Gshift | \
                                       (scolor.b >> fmt->Bloss) << fmt->Bshift | \
                                       (scolor.a >> fmt->Aloss) << fmt->Ashift; \
        }
