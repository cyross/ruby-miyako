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
#include <stdlib.h>
#include <math.h>
#include "ruby.h"
#include "ruby/encoding.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mInput = Qnil;
static VALUE mMapEvent = Qnil;
static VALUE mLayout = Qnil;
static VALUE mDiagram = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cGL = Qnil;
static VALUE cSurface = Qnil;
static VALUE cTTFFont = Qnil;
static VALUE cEvent2 = Qnil;
static VALUE cJoystick = Qnil;
static VALUE cWaitCounter = Qnil;
static VALUE cColor = Qnil;
static VALUE cFont = Qnil;
static VALUE cBitmap = Qnil;
static VALUE cSprite = Qnil;
static VALUE cSpriteAnimation = Qnil;
static VALUE sSpriteUnit = Qnil;
static VALUE cPlane = Qnil;
static VALUE cParts = Qnil;
static VALUE cTextBox = Qnil;
static VALUE cMap = Qnil;
static VALUE cMapLayer = Qnil;
static VALUE cFixedMap = Qnil;
static VALUE cFixedMapLayer = Qnil;
static VALUE cCollision = Qnil;
static VALUE cCollisions = Qnil;
static VALUE cMovie = Qnil;
static VALUE cProcessor = Qnil;
static VALUE cYuki = Qnil;
static VALUE cThread = Qnil;
static VALUE cEncoding = Qnil;
static VALUE cIconv = Qnil;
static VALUE sPoint = Qnil;
static VALUE sSize = Qnil;
static VALUE sRect = Qnil;
static VALUE sSquare = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

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

#define MIYAKO_GET_UNIT_1(SRC, SRCUNIT, SRCSURFACE) \
	VALUE SRCUNIT = SRC; \
  if(rb_obj_is_kind_of(SRCUNIT, sSpriteUnit)==Qfalse){ \
    SRCUNIT = rb_funcall(SRCUNIT, rb_intern("to_unit"), 0); \
    if(SRCUNIT == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); } \
  } \
  if(rb_block_given_p() == Qtrue){ SRCUNIT = rb_obj_dup(SRCUNIT); rb_yield(SRCUNIT); } \
	SDL_Surface *SRCSURFACE = GetSurface(*(RSTRUCT_PTR(SRCUNIT)))->surface;

#define MIYAKO_GET_UNIT_2(SRC, DST, SRCUNIT, DSTUNIT, SRCSURFACE, DSTSURFACE) \
	VALUE SRCUNIT = SRC; \
  if(rb_obj_is_kind_of(SRCUNIT, sSpriteUnit)==Qfalse){ \
    SRCUNIT = rb_funcall(SRCUNIT, rb_intern("to_unit"), 0); \
    if(SRCUNIT == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); } \
  } \
	VALUE DSTUNIT = DST; \
  if(rb_obj_is_kind_of(DSTUNIT, sSpriteUnit)==Qfalse){ \
    DSTUNIT = rb_funcall(DSTUNIT, rb_intern("to_unit"), 0); \
    if(DSTUNIT == Qnil){ rb_raise(eMiyakoError, "Destination instance has not SpriteUnit!"); }\
  } \
  if(rb_block_given_p() == Qtrue) \
  { \
    SRCUNIT = rb_obj_dup(SRCUNIT); \
    DSTUNIT = rb_obj_dup(DSTUNIT); \
    rb_yield_values(2, SRCUNIT, DSTUNIT); \
  } \
	SDL_Surface *SRCSURFACE = GetSurface(*(RSTRUCT_PTR(SRCUNIT)))->surface; \
	SDL_Surface *DSTSURFACE = GetSurface(*(RSTRUCT_PTR(DSTUNIT)))->surface;

#define MIYAKO_GET_UNIT_3(SRC1, SRC2, DST, SRC1UNIT, SRC2UNIT, DSTUNIT, SRC1SURFACE, SRC2SURFACE, DSTSURFACE) \
	VALUE SRC1UNIT = SRC1; \
  if(rb_obj_is_kind_of(SRC1UNIT, sSpriteUnit)==Qfalse){ \
    SRC1UNIT = rb_funcall(SRC1UNIT, rb_intern("to_unit"), 0); \
    if(SRC1UNIT == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); } \
  } \
	VALUE SRC2UNIT = SRC2; \
  if(rb_obj_is_kind_of(SRC2UNIT, sSpriteUnit)==Qfalse){ \
    SRC2UNIT = rb_funcall(SRC2UNIT, rb_intern("to_unit"), 0); \
    if(SRC2UNIT == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); } \
  } \
	VALUE DSTUNIT = DST; \
  if(rb_obj_is_kind_of(DSTUNIT, sSpriteUnit)==Qfalse){ \
    DSTUNIT = rb_funcall(DSTUNIT, rb_intern("to_unit"), 0); \
    if(DSTUNIT == Qnil){ rb_raise(eMiyakoError, "Destination instance has not SpriteUnit!"); }\
  } \
  if(rb_block_given_p() == Qtrue) \
  { \
    SRC1UNIT = rb_obj_dup(SRC1UNIT); \
    SRC2UNIT = rb_obj_dup(SRC2UNIT); \
    DSTUNIT = rb_obj_dup(DSTUNIT); \
    rb_yield_values(3, SRC1UNIT, SRC2UNIT, DSTUNIT); \
  } \
	SDL_Surface *SRC1SURFACE = GetSurface(*(RSTRUCT_PTR(SRC1UNIT)))->surface; \
	SDL_Surface *SRC2SURFACE = GetSurface(*(RSTRUCT_PTR(SRC2UNIT)))->surface; \
	SDL_Surface *DSTSURFACE = GetSurface(*(RSTRUCT_PTR(DSTUNIT)))->surface;

#define MIYAKO_GET_UNIT_NO_SURFACE_1(SRC, SRCUNIT) \
	VALUE SRCUNIT = SRC; \
  if(rb_obj_is_kind_of(SRCUNIT, sSpriteUnit)==Qfalse){ \
    SRCUNIT = rb_funcall(SRCUNIT, rb_intern("to_unit"), 0); \
    if(SRCUNIT == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); } \
  } \
  if(rb_block_given_p() == Qtrue){ SRCUNIT = rb_obj_dup(SRCUNIT); rb_yield(SRCUNIT); }

#define MIYAKO_GET_UNIT_NO_SURFACE_2(SRC, DST, SRCUNIT, DSTUNIT) \
	VALUE SRCUNIT = SRC; \
  if(rb_obj_is_kind_of(SRCUNIT, sSpriteUnit)==Qfalse){ \
    SRCUNIT = rb_funcall(SRCUNIT, rb_intern("to_unit"), 0); \
    if(SRCUNIT == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); } \
  } \
	VALUE DSTUNIT = DST; \
  if(rb_obj_is_kind_of(DSTUNIT, sSpriteUnit)==Qfalse){ \
    DSTUNIT = rb_funcall(DSTUNIT, rb_intern("to_unit"), 0); \
    if(DSTUNIT == Qnil){ rb_raise(eMiyakoError, "Destination instance has not SpriteUnit!"); }\
  } \
  if(rb_block_given_p() == Qtrue) \
  { \
    SRCUNIT = rb_obj_dup(SRCUNIT); \
    DSTUNIT = rb_obj_dup(DSTUNIT); \
    rb_yield_values(2, SRCUNIT, DSTUNIT); \
  }

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
