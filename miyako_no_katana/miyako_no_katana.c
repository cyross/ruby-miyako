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

/*
=拡張ライブラリmiyako_no_katana
Authors:: サイロス誠
Version:: 2.0
Copyright:: 2007-2008 Cyross Makoto
License:: LGPL2.1
 */
#include <SDL.h>
#include <stdlib.h>
#include <math.h>
#include "ruby.h"

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
static VALUE sPoint = Qnil;
static VALUE sSize = Qnil;
static VALUE sRect = Qnil;
static VALUE sSquare = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static VALUE use_opengl = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;
static volatile double div255[256];

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

#define DEFINE_GET_STRUCT(struct_name, fun, klass, klassstr) \
static GLOBAL_DEFINE_GET_STRUCT(struct_name, fun, klass, klassstr)

// from rubysdl-video.c
DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");

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
	int dmy = dly + (srect.h < drect.h ? srect.h : drect.h); \
	int rx = dst->clip_rect.x + dst->clip_rect.w; \
	int ry = dst->clip_rect.y + dst->clip_rect.h; \
	if(dmx > drect.w) dmx = drect.w; \
	if(dmy > drect.h) dmy = drect.h; \
	if(dlx < dst->clip_rect.x) \
	{ \
		srect.x += (dst->clip_rect.x - dlx); \
		dlx = dst->clip_rect.x; \
	} \
	if(dly < dst->clip_rect.y) \
	{ \
		srect.y += (dst->clip_rect.y - dly); \
		dly = dst->clip_rect.y; \
	} \
	if(dmx > rx){ dmx = rx; } \
	if(dmy > ry){ dmy = ry; }
  
#define MIYAKO_INIT_RECT2 \
	int dlx = drect.x; \
	int dly = drect.y; \
	int dmx = dlx + drect.w; \
	int dmy = dly + drect.h; \
	int rx = dst->clip_rect.x + dst->clip_rect.w; \
	int ry = dst->clip_rect.y + dst->clip_rect.h; \
	if(dlx < dst->clip_rect.x) \
	{ \
		srect.x += (dst->clip_rect.x - dlx); \
		dlx = dst->clip_rect.x; \
	} \
	if(dly < dst->clip_rect.y) \
	{ \
		srect.y += (dst->clip_rect.y - dly); \
		dly = dst->clip_rect.y; \
	} \
	if(dmx > rx){ dmx = rx; } \
	if(dmy > ry){ dmy = ry; }

#define MIYAKO_INIT_RECT3 \
	int dlx = drect.x + x1; \
	int dly = drect.y + y1; \
	int dmx = dlx + (s1rect.w < s2rect.w ? s1rect.w : s2rect.w); \
	int dmy = dly + (s1rect.h < s2rect.h ? s2rect.h : s2rect.h); \
  if(x2 + s2rect.w > s1rect.x + s1rect.w) \
  { \
    dmx -= x2 + s2rect.w - (s1rect.x + s1rect.w); \
  } \
  if(y2 + s2rect.h > s1rect.y + s1rect.h) \
  { \
    dmy -= y2 + s2rect.h - (s1rect.y + s1rect.h); \
  } \
	int rx = dst->clip_rect.x + dst->clip_rect.w; \
	int ry = dst->clip_rect.y + dst->clip_rect.h; \
	if(dlx < dst->clip_rect.x) \
	{ \
		s1rect.x += (dst->clip_rect.x - dlx); \
		s2rect.x += (dst->clip_rect.x - dlx); \
		dlx = dst->clip_rect.x; \
	} \
	if(dly < dst->clip_rect.y) \
	{ \
		s1rect.y += (dst->clip_rect.y - dly); \
		s2rect.y += (dst->clip_rect.y - dly); \
		dly = dst->clip_rect.y; \
	} \
	if(dmx > rx){ dmx = rx; } \
	if(dmy > ry){ dmy = ry; }
  
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
  
/*
===画像をαチャネル付き画像へ転送する
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。
src==dstの場合、何も行わない
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_x_:: 転送先の転送開始位置(x方向・単位：ピクセル)
_y_:: 転送先の転送開始位置(y方向・単位：ピクセル)
返却値:: なし
*/
static VALUE bitmap_miyako_blit_aa(VALUE self, VALUE vsrc, VALUE vdst, VALUE vx, VALUE vy)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	if(psrc == pdst){ return Qnil; }
	
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

	//SpriteUnit:
	//[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
	//[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
	//[9] -> :angle, [10] -> :xscale, [11] -> :yscale
	//[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

	int x =  NUM2INT(vx);
	int y =  NUM2INT(vy);
  MIYAKO_INIT_RECT1;

	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int px, py, sy;
	for(py = dly, sy = srect.y; py < dmy; py++, sy++)
	{
    Uint32 *ppsrc = psrc + sy * src->w + srect.x;
    Uint32 *ppdst = pdst + py * dst->w + dlx;
		for(px = dlx; px < dmx; px++)
		{
      pixel = *ppdst | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *ppsrc | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ ppsrc++; ppdst++; continue; }
      if(dcolor.a == 0 || scolor.a == 255){
        *ppdst = pixel;
        ppsrc++;
        ppdst++;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *ppdst = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
               (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
               (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
               (255 >> fmt->Aloss) << fmt->Ashift;
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===２つの画像のandを取り、別の画像へ転送する
範囲は、src1側SpriteUnitとsrc2側との(ow,oh)の小さい方の範囲で転送する。
src1とsrc2の合成は、src2側SpriteUnitの(x,y)をsrc1側の起点として、src2側SpriteUnitの(ow,oh)の範囲で転送する。
dst側は、src1側SpriteUnitの(x,y)を起点に転送する。
src1==src2の場合、何も行わない
ブロックを渡すと、src1,src2,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る。
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src1側SpriteUnit,src2側SpriteUnit,dst側SpriteUnit|となる。
_src1_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_src2_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_x_:: 転送先の転送開始位置(x方向・単位：ピクセル)
_y_:: 転送先の転送開始位置(y方向・単位：ピクセル)
返却値:: なし
*/
static VALUE bitmap_miyako_blit_and(VALUE self, VALUE vsrc1, VALUE vsrc2, VALUE vdst)
{
  MIYAKO_GET_UNIT_3(vsrc1, vsrc2, vdst, s1unit, s2unit, dunit, src1, src2, dst);
	Uint32 *psrc1 = (Uint32 *)(src1->pixels);
	Uint32 *psrc2 = (Uint32 *)(src2->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src1->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect s1rect, s2rect, drect;
	Uint32 src1_a = 0;
	Uint32 src2_a = 0;
	Uint32 dst_a = 0;

	if(psrc1 == psrc2){ return Qnil; }
	
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src1 == scr){ src1_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(src2 == scr){ src2_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

	//SpriteUnit:
	//[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
	//[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
	//[9] -> :angle, [10] -> :xscale, [11] -> :yscale
	//[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	MIYAKO_SET_RECT(s1rect, s1unit);
	MIYAKO_SET_RECT(s2rect, s2unit);
	MIYAKO_SET_RECT(drect, dunit);

  int x1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 5));
  int y1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 6));
  int x2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 5));
  int y2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 6));
  MIYAKO_INIT_RECT3;

	SDL_LockSurface(src1);
	SDL_LockSurface(src2);
	SDL_LockSurface(dst);
  
	int px, py, sy1, sy2;
	for(py = dly, sy1 = s1rect.y + y2, sy2 = s2rect.y; py < dmy; py++, sy1++, sy2++)
	{
    Uint32 *ppsrc1 = psrc1 + sy1 * src1->w + s1rect.x + x2;
    Uint32 *ppsrc2 = psrc2 + sy2 * src2->w + s2rect.x;
    Uint32 *ppdst = pdst + py * dst->w + dlx;
		for(px = dlx; px < dmx; px++)
		{
      pixel = *ppdst | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = (*ppsrc2 | src2_a) & (*ppsrc1 | src1_a);
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ ppsrc1++; ppsrc2++; ppdst++; continue; }
      if(dcolor.a == 0 || scolor.a == 255){
        *ppdst = pixel;
        ppsrc1++;
        ppsrc2++;
        ppdst++;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *ppdst = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
               (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
               (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
               (255 >> fmt->Aloss) << fmt->Ashift;
      ppsrc1++;
      ppsrc2++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src1);
	SDL_UnlockSurface(src2);
	SDL_UnlockSurface(dst);

  return Qnil;
}


/*
===２つの画像のorを取り、別の画像へ転送する
範囲は、src1側SpriteUnitとsrc2側との(ow,oh)の小さい方の範囲で転送する。
src1とsrc2の合成は、src2側SpriteUnitの(x,y)をsrc1側の起点として、src2側SpriteUnitの(ow,oh)の範囲で転送する。
dst側は、src1側SpriteUnitの(x,y)を起点に転送する。
src1==src2の場合、何も行わない
ブロックを渡すと、src1,src2,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src1側SpriteUnit,src2側SpriteUnit,dst側SpriteUnit|となる。
_src1_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_src2_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_x_:: 転送先の転送開始位置(x方向・単位：ピクセル)
_y_:: 転送先の転送開始位置(y方向・単位：ピクセル)
返却値:: なし
*/
static VALUE bitmap_miyako_blit_or(VALUE self, VALUE vsrc1, VALUE vsrc2, VALUE vdst)
{
  MIYAKO_GET_UNIT_3(vsrc1, vsrc2, vdst, s1unit, s2unit, dunit, src1, src2, dst);
	Uint32 *psrc1 = (Uint32 *)(src1->pixels);
	Uint32 *psrc2 = (Uint32 *)(src2->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src1->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect s1rect, s2rect, drect;
	Uint32 src1_a = 0;
	Uint32 src2_a = 0;
	Uint32 dst_a = 0;

	if(psrc1 == psrc2){ return Qnil; }
	
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src1 == scr){ src1_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(src2 == scr){ src2_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

	//SpriteUnit:
	//[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
	//[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
	//[9] -> :angle, [10] -> :xscale, [11] -> :yscale
	//[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	MIYAKO_SET_RECT(s1rect, s1unit);
	MIYAKO_SET_RECT(s2rect, s2unit);
	MIYAKO_SET_RECT(drect, dunit);

  int x1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 5));
  int y1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 6));
  int x2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 5));
  int y2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 6));
  MIYAKO_INIT_RECT3;

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;
  
	SDL_LockSurface(src1);
	SDL_LockSurface(src2);
	SDL_LockSurface(dst);
  
	int px, py, sy1, sy2;
	for(py = dly, sy1 = s1rect.y + y2, sy2 = s2rect.y; py < dmy; py++, sy1++, sy2++)
	{
    Uint32 *ppsrc1 = psrc1 + sy1 * src1->w + s1rect.x + x2;
    Uint32 *ppsrc2 = psrc2 + sy2 * src2->w + s2rect.x;
    Uint32 *ppdst = pdst + py * dst->w + dlx;
		for(px = dlx; px < dmx; px++)
		{
      pixel = *ppdst | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = (*ppsrc2 | src2_a) | (*ppsrc1 | src1_a);
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ ppsrc1++; ppsrc2++; ppdst++; continue; }
      if(dcolor.a == 0 || scolor.a == 255){
        *ppdst = pixel;
        ppsrc1++;
        ppsrc2++;
        ppdst++;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *ppdst = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
               (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
               (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
               put_a;
      ppsrc1++;
      ppsrc2++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src1);
	SDL_UnlockSurface(src2);
	SDL_UnlockSurface(dst);

  return Qnil;
}


/*
===２つの画像のxorを取り、別の画像へ転送する
範囲は、src1側SpriteUnitとsrc2側との(ow,oh)の小さい方の範囲で転送する。
src1とsrc2の合成は、src2側SpriteUnitの(x,y)をsrc1側の起点として、src2側SpriteUnitの(ow,oh)の範囲で転送する。
dst側は、src1側SpriteUnitの(x,y)を起点に転送する。
src1==src2の場合、何も行わない
ブロックを渡すと、src1,src2,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src1側SpriteUnit,src2側SpriteUnit,dst側SpriteUnit|となる。
_src1_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_src2_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_x_:: 転送先の転送開始位置(x方向・単位：ピクセル)
_y_:: 転送先の転送開始位置(y方向・単位：ピクセル)
返却値:: なし
*/
static VALUE bitmap_miyako_blit_xor(VALUE self, VALUE vsrc1, VALUE vsrc2, VALUE vdst)
{
  MIYAKO_GET_UNIT_3(vsrc1, vsrc2, vdst, s1unit, s2unit, dunit, src1, src2, dst);
	Uint32 *psrc1 = (Uint32 *)(src1->pixels);
	Uint32 *psrc2 = (Uint32 *)(src2->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src1->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect s1rect, s2rect, drect;
	Uint32 src1_a = 0;
	Uint32 src2_a = 0;
	Uint32 dst_a = 0;

	if(psrc1 == psrc2){ return Qnil; }
	
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src1 == scr){ src1_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(src2 == scr){ src2_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

	//SpriteUnit:
	//[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
	//[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
	//[9] -> :angle, [10] -> :xscale, [11] -> :yscale
	//[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	MIYAKO_SET_RECT(s1rect, s1unit);
	MIYAKO_SET_RECT(s2rect, s2unit);
	MIYAKO_SET_RECT(drect, dunit);

  int x1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 5));
  int y1 = NUM2INT(*(RSTRUCT_PTR(s1unit) + 6));
  int x2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 5));
  int y2 = NUM2INT(*(RSTRUCT_PTR(s2unit) + 6));
  MIYAKO_INIT_RECT3;

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

	SDL_LockSurface(src1);
	SDL_LockSurface(src2);
	SDL_LockSurface(dst);
  
	int px, py, sy1, sy2;
	for(py = dly, sy1 = s1rect.y + y2, sy2 = s2rect.y; py < dmy; py++, sy1++, sy2++)
	{
    Uint32 *ppsrc1 = psrc1 + sy1 * src1->w + s1rect.x + x2;
    Uint32 *ppsrc2 = psrc2 + sy2 * src2->w + s2rect.x;
    Uint32 *ppdst = pdst + py * dst->w + dlx;
		for(px = dlx; px < dmx; px++)
		{
      pixel = *ppdst | dst_a;
      MIYAKO_GETCOLOR(dcolor);
      if(scolor.a == 0){ ppsrc1++; ppsrc2++; ppdst++; continue; }
      if(dcolor.a == 0 || scolor.a == 255){
        *ppdst = (*ppsrc2 | src2_a) ^ (*ppsrc1 | src1_a) ;
        ppsrc1++;
        ppsrc2++;
        ppdst++;
        continue;
      }
			pixel = (*ppsrc2 | src2_a) ^ (*ppsrc1 | src1_a);
			MIYAKO_GETCOLOR(scolor);
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *ppdst = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
               (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
               (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
               put_a;
      ppsrc1++;
      ppsrc2++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src1);
	SDL_UnlockSurface(src2);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画像をαチャネル付き画像へ転送する
引数で渡ってきた特定の色に対して、α値をゼロにする画像を生成する
src==dstの場合、何も行わずすぐに呼びだし元に戻る
範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_color_key_:: 透明にしたい色(各要素がr,g,bに対応している整数の配列(0～255))
返却値:: なし
*/
static VALUE bitmap_miyako_colorkey_to_alphachannel(VALUE self, VALUE vsrc, VALUE vdst, VALUE vcolor_key)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = dst->format;
	MiyakoColor color_key, color;
	Uint32 pixel;

	if(psrc == pdst){ return Qnil; }
	
	color_key.r = NUM2INT(*(RARRAY_PTR(vcolor_key) + 0));
	color_key.g = NUM2INT(*(RARRAY_PTR(vcolor_key) + 1));
	color_key.b = NUM2INT(*(RARRAY_PTR(vcolor_key) + 2));
  
  //SpriteUnit:
  //[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
  //[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
  //[9] -> :angle, [10] -> :xscale, [11] -> :yscale
  //[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	int w = src->w;
	int h = src->h;
  
	if(w > dst->w) w = dst->w;
	if(h > dst->h) h = dst->h;

	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int sx, sy;
  for(sy = 0; sy < h; sy++)
  {
    Uint32 *ppsrc = psrc + sy * w;
    Uint32 *ppdst = pdst + sy * dst->w;
    for(sx = 0; sx < w; sx++)
    {
      pixel = *ppsrc++;
      MIYAKO_GETCOLOR(color);
      if(color.r == color_key.r && color.g == color_key.g &&  color.b == color_key.b) pixel = 0;
      else pixel |= (0xff >> fmt->Aloss) << fmt->Ashift;
      *ppdst++ = pixel;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画像のαチャネルを255に拡張する
αチャネルの値を255に拡張する(α値をリセットする)
範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: なし
*/
static VALUE bitmap_miyako_reset_alphachannel(VALUE self, VALUE vsrc, VALUE vdst)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = dst->format;
	Uint32 pixel;

  //SpriteUnit:
  //[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
  //[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
  //[9] -> :angle, [10] -> :xscale, [11] -> :yscale
  //[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	int w = src->w;
	int h = src->h;
  
	if(w > dst->w) w = dst->w;
	if(h > dst->h) h = dst->h;

	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int sx, sy;
  for(sy = 0; sy < h; sy++)
  {
    Uint32 *ppsrc = psrc + sy * w;
    Uint32 *ppdst = pdst + sy * dst->w;
    for(sx = 0; sx < w; sx++)
    {
      pixel = *ppsrc++;
      pixel |= (0xff >> fmt->Aloss) << fmt->Ashift;
      *ppdst++ = pixel;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画像をαチャネル付き画像へ変換する
２４ビット画像(αチャネルがゼロの画像)に対して、すべてのα値を255にする画像を生成する
範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: なし
*/
static VALUE bitmap_miyako_normal_to_alphachannel(VALUE self, VALUE vsrc, VALUE vdst)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = dst->format;
	Uint32 pixel;

  //SpriteUnit:
  //[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
  //[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
  //[9] -> :angle, [10] -> :xscale, [11] -> :yscale
  //[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	int w = src->w;
	int h = src->h;
  
	if(w > dst->w) w = dst->w;
	if(h > dst->h) h = dst->h;

	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int sx, sy;
  for(sy = 0; sy < h; sy++)
  {
    Uint32 *ppsrc = psrc + sy * w;
    Uint32 *ppdst = pdst + sy * dst->w;
    for(sx = 0; sx < w; sx++)
    {
      pixel = *ppsrc++;
      pixel |= (0xff >> fmt->Aloss) << fmt->Ashift;
      *ppdst++ = pixel;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画面(αチャネル無し32bit画像)をαチャネル付き画像へ転送する
α値がゼロの画像から、α値を255にする画像を生成する
src==dstの場合、何も行わずすぐに呼びだし元に戻る
範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_color_key_:: 透明にしたい色(各要素がr,g,bに対応している整数の配列(0～255))
返却値:: なし
*/
static VALUE bitmap_miyako_screen_to_alphachannel(VALUE self, VALUE vsrc, VALUE vdst)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = dst->format;
	Uint32 pixel;

	if(psrc == pdst){ return Qnil; }
	
  //SpriteUnit:
  //[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
  //[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
  //[9] -> :angle, [10] -> :xscale, [11] -> :yscale
  //[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	int w = src->w;
	int h = src->h;
  
	if(w > dst->w) w = dst->w;
	if(h > dst->h) h = dst->h;

	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int sx, sy;
  for(sy = 0; sy < h; sy++)
  {
    Uint32 *ppsrc = psrc + sy * w;
    Uint32 *ppdst = pdst + sy * dst->w;
    for(sx = 0; sx < w; sx++)
    {
      pixel = *ppsrc++;
      pixel |= (0xff >> fmt->Aloss) << fmt->Ashift;
      *ppdst++ = pixel;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画像のαチャネルの値を一定の割合で変化させて転送する
degreeの値が1.0に近づけば近づくほど透明に近づき、
degreeの値が-1.0に近づけば近づくほど不透明に近づく(値が-1.0のときは完全不透明、値が0.0のときは変化なし、1.0のときは完全に透明になる)
但し、元々αの値がゼロの時は変化しない
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_degree_:: 減少率。-1.0<=degree<=1.0までの実数
*/
static VALUE bitmap_miyako_dec_alpha(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 da = (Uint32)(255.0 * deg);

	MiyakoColor scolor, dcolor;
	Uint32 pixel;

  if(src != dst){
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
		if(src == scr){ src_a = 255; }
		if(dst == scr){ dst_a = 255; }

		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
				scolor.a |= src_a;
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
				dcolor.a |= dst_a;
        scolor.a -= da;
        if(scolor.a > 0x80000000){ scolor.a = 0; }
        if(scolor.a > 255){ scolor.a = 255; }
        MIYAKO_PSET(px, py);
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        Uint32 da = (Uint32)(255.0 * deg);
        scolor.a -= da;
        if(scolor.a > 0x80000000){ scolor.a = 0; }
        if(scolor.a > 255){ scolor.a = 255; }
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

	return Qnil;
}

/*
===画像の色を一定の割合で黒に近づける(ブラックアウト)
赤・青・緑・αの各要素を一定の割合で下げ、黒色に近づける。
degreeの値が1.0に近づけば近づくほど黒色に近づく(値が0.0のときは変化なし、1.0のときは真っ黒になる)
αの値が0のときは変わらないことに注意！
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_degree_:: 変化率。0.0<=degree<=1.0までの実数
*/
static VALUE bitmap_miyako_black_out(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	double deg = NUM2DBL(degree);
  if(deg < 0.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;

	MiyakoColor scolor, dcolor;
	Uint32 pixel;

  Uint32 d = (Uint32)(255.0 * deg);
  if(src != dst){
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
		if(src == scr){ src_a = 255; }
		if(dst == scr){ dst_a = 255; }

		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
				scolor.a |= src_a;
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
				dcolor.a |= dst_a;
        scolor.r -= d;
        if(scolor.r > 0x80000000){ scolor.r = 0; }
        scolor.g -= d;
        if(scolor.g > 0x80000000){ scolor.g = 0; }
        scolor.b -= d;
        if(scolor.b > 0x80000000){ scolor.b = 0; }
        if(scolor.a != 0)
        {
          scolor.a -= d;
          if(scolor.a > 0x80000000){ scolor.a = 0; }
        }
        MIYAKO_PSET(px, py);
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        scolor.r -= d;
        if(scolor.r > 0x80000000){ scolor.r = 0; }
        scolor.g -= d;
        if(scolor.g > 0x80000000){ scolor.g = 0; }
        scolor.b -= d;
        if(scolor.b > 0x80000000){ scolor.b = 0; }
        if(scolor.a != 0)
        {
          scolor.a -= d;
          if(scolor.a > 0x80000000){ scolor.a = 0; }
        }
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

	return Qnil;
}

/*
===画像の色を一定の割合で白に近づける(ホワイトアウト)
赤・青・緑・αの各要素を一定の割合で上げ、白色に近づける。
degreeの値が1.0に近づけば近づくほど白色に近づく(値が0.0のときは変化なし、1.0のときは真っ白になる)
αの値が0のときは変わらないことに注意！
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_degree_:: 変化率。0.0<=degree<=1.0までの実数
*/
static VALUE bitmap_miyako_white_out(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	double deg = NUM2DBL(degree);
  if(deg < 0.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }

	MiyakoColor scolor, dcolor;
	Uint32 pixel;

  Uint32 d = (Uint32)(255.0 * deg);
  if(src != dst){
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
		if(src == scr){ src_a = 255; }
		if(dst == scr){ dst_a = 255; }

		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
				scolor.a |= src_a;
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
				dcolor.a |= dst_a;
        scolor.r += d;
        if(scolor.r > 255){ scolor.r = 255; }
        scolor.g += d;
        if(scolor.g > 255){ scolor.g = 255; }
        scolor.b += d;
        if(scolor.b > 255){ scolor.b = 255; }
        if(scolor.a != 0)
        {
          scolor.a += d;
          if(scolor.a > 255){ scolor.a = 255; }
        }
        MIYAKO_PSET(px, py);
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        scolor.r += d;
        if(scolor.r > 255){ scolor.r = 255; }
        scolor.g += d;
        if(scolor.g > 255){ scolor.g = 255; }
        scolor.b += d;
        if(scolor.b > 255){ scolor.b = 255; }
        if(scolor.a != 0)
        {
          scolor.a += d;
          if(scolor.a > 255){ scolor.a = 255; }
        }
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

	return Qnil;
}

/*
===画像のRGB値を反転させる
αチャネルの値は変更しない
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
*/
static VALUE bitmap_miyako_inverse(VALUE self, VALUE vsrc, VALUE vdst)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;

  if(src != dst){
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
		if(src == scr){ src_a = 255; }
		if(dst == scr){ dst_a = 255; }

		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
				scolor.a |= src_a;
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
				dcolor.a |= dst_a;
        scolor.r ^= 0xff;
        scolor.g ^= 0xff;
        scolor.b ^= 0xff;
        MIYAKO_PSET(px, py);
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        scolor.r ^= 0xff;
        scolor.g ^= 0xff;
        scolor.b ^= 0xff;
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

	return Qnil;
}

/*
===2枚の画像の加算合成を行う
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
*/
static VALUE bitmap_miyako_additive_synthesis(VALUE self, VALUE vsrc, VALUE vdst)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	if(psrc == pdst){ return Qnil; }
	
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = 255; }
	if(dst == scr){ dst_a = 255; }

	MIYAKO_SET_RECT(srect, vsrc);
	MIYAKO_SET_RECT(drect, vdst);
  int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
  int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
  MIYAKO_INIT_RECT1;
  
  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int px, py, sx, sy;
  for(sy = srect.y, py = dly; py < dmy; sy++, py++)
  {
    for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
    {
      pixel = *(psrc + sy * src->w + sx);
      MIYAKO_GETCOLOR(scolor);
			scolor.a |= src_a;
      if(scolor.a == 0){ continue; }
      pixel = *(pdst + py * dst->w + px);
      MIYAKO_GETCOLOR(dcolor);
      dcolor.a |= dst_a;
      dcolor.r += scolor.r;
			if(dcolor.r > 255){ dcolor.r = 255; }
			dcolor.g += scolor.g;
			if(dcolor.g > 255){ dcolor.g = 255; }
			dcolor.b += scolor.b;
			if(dcolor.b > 255){ dcolor.b = 255; }
			dcolor.a = (dcolor.a > scolor.a ? dcolor.a : scolor.a);
      MIYAKO_SETCOLOR(*(pdst + py * dst->w + px), dcolor);
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);
	
	return Qnil;
}

/*
===2枚の画像の減算合成を行う
範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
*/
static VALUE bitmap_miyako_subtraction_synthesis(VALUE self, VALUE src, VALUE dst)
{
  bitmap_miyako_inverse(self, dst, dst);
  bitmap_miyako_additive_synthesis(self, src, dst);
  bitmap_miyako_inverse(self, dst, dst);
  return Qnil;
}

/*
===画像を回転させて貼り付ける
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、(ow,oh)の範囲で転送する。回転の中心は(ox,oy)を起点に、(cx,cy)が中心になるように設定する。
転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、dst側SpriteUnitの(cx,cy)が中心になるように設定にする。
回転角度が正だと右回り、負だと左回りに回転する
src==dstの場合、何も行わない
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
*/
static VALUE bitmap_miyako_rotate(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = 255; }
	if(dst == scr){ dst_a = 255; }

	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	
	if(psrc == pdst){ return Qnil; }
	
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

  if(drect.w >= 32768 || drect.h >= 32768){ return Qnil; }

  MIYAKO_INIT_RECT2;
  
  double rad = NUM2DBL(radian) * -1.0;
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

	int px = srect.x + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int py = srect.y + NUM2INT(*(RSTRUCT_PTR(sunit)+8));
	int qx = NUM2INT(*(RSTRUCT_PTR(sunit)+5)) + NUM2INT(*(RSTRUCT_PTR(dunit)+7));
	int qy = NUM2INT(*(RSTRUCT_PTR(sunit)+6)) + NUM2INT(*(RSTRUCT_PTR(dunit)+8));

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int x, y;
  for(y = dly; y < dmy; y++)
  {
    int ty = y - qy;
    Uint32 *tp = pdst + y * dst->w;
    for(x = dlx; x < dmx; x++)
    {
      int nx = (((x-qx)*icos-ty*isin) >> 12) + px;
      if(nx < srect.x || nx >= (srect.x+srect.w)){ continue; }
      int ny = (((x-qx)*isin+ty*icos) >> 12) + py;
      if(ny < srect.y || ny >= (srect.y+srect.h)){ continue; }
      pixel = *(tp + x) | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *(psrc + ny * src->w + nx) | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ continue; }
      if(dcolor.a == 0 || scolor.a == 255)
      {
        *(tp + x) = pixel;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *(tp + x) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                  (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                  (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                    put_a;
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);
	
  return Qnil;
}

/*
===画像を拡大・縮小・鏡像(ミラー反転)させて貼り付ける
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、(ow,oh)の範囲で転送する。回転の中心は(ox,oy)を起点に、(cx,cy)が中心になるように設定する。
転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、dst側SpriteUnitの(cx,cy)が中心になるように設定にする。
度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
但し、拡大率が4096分の1以下だと、拡大/縮小しない可能性がある
src==dstの場合、何も行わない
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_xscale_:: 拡大率(x方向)
_yscale_:: 拡大率(y方向)
*/
static VALUE bitmap_miyako_scale(VALUE self, VALUE vsrc, VALUE vdst, VALUE xscale, VALUE yscale)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = 255; }
	if(dst == scr){ dst_a = 255; }

	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	
	if(psrc == pdst){ return Qnil; }
	
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

  if(drect.w >= 32768 || drect.h >= 32768){ return Qnil; }

  MIYAKO_INIT_RECT2;

  double tscx = NUM2DBL(xscale);
  double tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0){ return Qnil; }

  int scx = (int)(4096.0 / tscx);
  int scy = (int)(4096.0 / tscy);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

	int px = srect.x + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int py = srect.y + NUM2INT(*(RSTRUCT_PTR(sunit)+8));
	int qx = NUM2INT(*(RSTRUCT_PTR(sunit)+5)) + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int qy = NUM2INT(*(RSTRUCT_PTR(sunit)+6)) + NUM2INT(*(RSTRUCT_PTR(sunit)+8));

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int x, y;
  for(y = dly; y < dmy; y++)
  {
    int ty = y - qy;
    Uint32 *tp = pdst + y * dst->w;
    for(x = dlx; x < dmx; x++)
    {
      int nx = (((x-qx) * scx) >> 12) + px - off_x;
      if(nx < srect.x || nx >= (srect.x+srect.w)){ continue; }
      int ny = ((ty * scy) >> 12) + py - off_y;
      if(ny < srect.y || ny >= (srect.y+srect.h)){ continue; }
      pixel = *(tp + x) | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *(psrc + ny * src->w + nx) | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ continue; }
      if(dcolor.a == 0 || scolor.a == 255)
      {
        *(tp + x) = pixel;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *(tp + x) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                  (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                  (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                  put_a;
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===回転・拡大・縮小・鏡像用インナーメソッド
*/
static void transform_inner(VALUE sunit, VALUE dunit, VALUE radian, VALUE xscale, VALUE yscale)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(sunit)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(dunit)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	SDL_PixelFormat *fmt = src->format;
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	
	if(psrc == pdst){ return; }
	
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

  if(drect.w >= 32768 || drect.h >= 32768){ return; }

  MIYAKO_INIT_RECT2;
  
  double rad = NUM2DBL(radian) * -1.0;
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

  double tscx = NUM2DBL(xscale);
  double tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0){ return; }

  int scx = (int)(4096.0 / tscx);
  int scy = (int)(4096.0 / tscy);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

	int px = srect.x + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int py = srect.y + NUM2INT(*(RSTRUCT_PTR(sunit)+8));
	int qx = NUM2INT(*(RSTRUCT_PTR(sunit)+5)) + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int qy = NUM2INT(*(RSTRUCT_PTR(sunit)+6)) + NUM2INT(*(RSTRUCT_PTR(sunit)+8));

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int x, y;
  for(y = dly; y < dmy; y++)
  {
    int ty = y - qy;
    Uint32 *tp = pdst + y * dst->w;
    for(x = dlx; x < dmx; x++)
    {
      int nx = (((((x-qx)*icos-ty*isin) >> 12) * scx) >> 12) + px - off_x;
      if(nx < srect.x || nx >= (srect.x+srect.w)){ continue; }
      int ny = (((((x-qx)*isin+ty*icos) >> 12) * scy) >> 12) + py - off_y;
      if(ny < srect.y || ny >= (srect.y+srect.h)){ continue; }
      pixel = *(tp + x) | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *(psrc + ny * src->w + nx) | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ continue; }
      if(dcolor.a == 0 || scolor.a == 255)
      {
        *(tp + x) = pixel;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *(tp + x) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                  (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                  (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                  put_a;
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);
}

/*
===画像を変形(回転・拡大・縮小・鏡像)させて貼り付ける
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。回転の中心はsrc側(ox,oy)を起点に、src側(cx,cy)が中心になるように設定する。
転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、dst側SpriteUnitの(cx,cy)が中心になるように設定にする。
回転角度は、src側SpriteUnitのangleを使用する
回転角度が正だと右回り、負だと左回りに回転する
変形の度合いは、src側SpriteUnitのxscale, yscaleを使用する(ともに実数で指定する)。それぞれ、x方向、y方向の度合いとなる
度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
但し、拡大率が4096分の1以下だと、拡大/縮小しない可能性がある
src==dstの場合、何も行わない
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
_xscale_:: 拡大率(x方向)
_yscale_:: 拡大率(y方向)
*/
static VALUE bitmap_miyako_transform(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(vsrc, vdst, sunit, dunit);
  transform_inner(sunit, dunit, radian, xscale, yscale);
  return Qnil;
}

#define MIYAKO_RGB2HSV(RGBSTRUCT, HSVH, HSVS, HSVV) \
  Uint32 imax = RGBSTRUCT.r; \
  Uint32 imin = imax; \
  imax = imax < RGBSTRUCT.g ? RGBSTRUCT.g : imax; \
  imax = imax < RGBSTRUCT.b ? RGBSTRUCT.b : imax; \
  imin = imin > RGBSTRUCT.g ? RGBSTRUCT.g : imin; \
  imin = imin > RGBSTRUCT.b ? RGBSTRUCT.b : imin; \
  if(imax == 0){ HSVV == 0.0; HSVH = 0.0; HSVS = 0.0; } \
  else \
  { \
    HSVV = div255[imax]; \
    double delta = HSVV - div255[imin]; \
    HSVS = delta / HSVV; \
    if(HSVS == 0.0){ HSVH = 0.0; } \
    else \
    { \
      delta *= 255.0; \
      if(imax == RGBSTRUCT.r){ HSVH =       ((double)(RGBSTRUCT.g) - (double)(RGBSTRUCT.b))/delta; } \
      if(imax == RGBSTRUCT.g){ HSVH = 2.0 + ((double)(RGBSTRUCT.b) - (double)(RGBSTRUCT.r))/delta; } \
      if(imax == RGBSTRUCT.b){ HSVH = 4.0 + ((double)(RGBSTRUCT.r) - (double)(RGBSTRUCT.g))/delta; } \
      HSVH *= 60.0; \
      if(HSVH < 0){ HSVH += 360.0; } \
    } \
  }

#define MIYAKO_HSV2RGB(HSVH, HSVS, HSVV, RGBSTRUCT) \
  if(HSVS == 0.0){ RGBSTRUCT.r = RGBSTRUCT.g = RGBSTRUCT.b = (Uint32)(HSVV * 255.0); } \
  else \
  { \
    double tmp_i = HSVH / 60.0; \
    if(     tmp_i < 1.0){ i = 0.0; } \
    else if(tmp_i < 2.0){ i = 1.0; } \
    else if(tmp_i < 3.0){ i = 2.0; } \
    else if(tmp_i < 4.0){ i = 3.0; } \
    else if(tmp_i < 5.0){ i = 4.0; } \
    else if(tmp_i < 6.0){ i = 5.0; } \
    f = tmp_i - i; \
    m = HSVV * (1 - HSVS); \
    n = HSVV * (1 - HSVS * f); \
    k = HSVV * (1 - HSVS * (1 - f)); \
    if(     i == 0.0){ r = HSVV; g = k, b = m; } \
    else if(i == 1.0){ r = n; g = HSVV, b = m; } \
    else if(i == 2.0){ r = m; g = HSVV, b = k; } \
    else if(i == 3.0){ r = m; g = n, b = HSVV; } \
    else if(i == 4.0){ r = k; g = m, b = HSVV; } \
    else if(i == 5.0){ r = HSVV; g = m, b = n; } \
    RGBSTRUCT.r = (Uint32)(r * 255.0); \
    RGBSTRUCT.g = (Uint32)(g * 255.0); \
    RGBSTRUCT.b = (Uint32)(b * 255.0); \
  }

/*
===画像の色相を変更する
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_hue(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double deg = NUM2DBL(degree);
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
  double d_pi = 360.0;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }
  
  if(src != dst){
		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
    if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
    if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

    Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx) | src_a;
        MIYAKO_GETCOLOR(scolor);
        if(scolor.a == 0){ continue; }
        pixel = *(pdst + py * dst->w + px) | dst_a;
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ph += deg;
        if(ph < 0.0){ ph += d_pi; }
        if(ph >= d_pi){ ph -= d_pi; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0 || scolor.a == 255){
          MIYAKO_SETCOLOR(*(pdst + py * dst->w + px), scolor);
          continue;
        }
        int a1 = scolor.a + 1;
        int a2 = 256 - scolor.a;
        *(pdst + py * dst->w + px) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                                     (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                                     (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                                     put_a;
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ph += deg;
        if(ph < 0.0){ ph += d_pi; }
        if(ph >= d_pi){ ph -= d_pi; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

  return Qnil;
}

/*
===画像の彩度を変更する
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
*/
static VALUE bitmap_miyako_saturation(VALUE self, VALUE vsrc, VALUE vdst, VALUE saturation)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double sat = NUM2DBL(saturation);
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(src != dst){
		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
    if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
    if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

    Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx) | src_a;
        MIYAKO_GETCOLOR(scolor);
        if(scolor.a == 0){ continue; }
        pixel = *(pdst + py * dst->w + px) | dst_a;
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ps += sat;
        if(ps < 0.0){ ps = 0.0; }
        if(ps > 1.0){ ps = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0 || scolor.a == 255){
          MIYAKO_SETCOLOR(*(pdst + py * dst->w + px), scolor);
          continue;
        }
        int a1 = scolor.a + 1;
        int a2 = 256 - scolor.a;
        *(pdst + py * dst->w + px) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                                     (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                                     (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                                     put_a;
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ps += sat;
        if(ps < 0.0){ ps = 0.0; }
        if(ps > 1.0){ ps = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor)
      }
    }

    SDL_UnlockSurface(src);
  }

  return Qnil;
}

/*
===画像の明度を変更する
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_value(VALUE self, VALUE vsrc, VALUE vdst, VALUE value)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double val = NUM2DBL(value);
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(src != dst){
		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
    int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
    if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
    if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

    Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx) | src_a;
        MIYAKO_GETCOLOR(scolor);
        if(scolor.a == 0){ continue; }
        pixel = *(pdst + py * dst->w + px) | dst_a;
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        pv += val;
        if(pv < 0.0){ pv = 0.0; }
        if(pv > 1.0){ pv = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0 || scolor.a == 255){
          MIYAKO_SETCOLOR(*(pdst + py * dst->w + px), scolor);
          continue;
        }
        int a1 = scolor.a + 1;
        int a2 = 256 - scolor.a;
        *(pdst + py * dst->w + px) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                                     (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                                     (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                                     put_a;
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        pv += val;
        if(pv < 0.0){ pv = 0.0; }
        if(pv > 1.0){ pv = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

  return Qnil;
}

/*
===画像の色相・彩度・明度を変更する
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_hsv(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree, VALUE saturation, VALUE value)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double deg = NUM2DBL(degree);
  double sat = NUM2DBL(saturation);
  double val = NUM2DBL(value);
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
  double d_pi = 360.0;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }
  
  if(src != dst){
		SDL_Rect srect, drect;
		MIYAKO_SET_RECT(srect, sunit);
		MIYAKO_SET_RECT(drect, dunit);
		int x   = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
    MIYAKO_INIT_RECT1;
  
		Uint32 src_a = 0;
		Uint32 dst_a = 0;

		SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
    if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
    if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

    Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;
		
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = srect.y, py = dly; py < dmy; sy++, py++)
    {
      for(sx = srect.x, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx) | src_a;
        MIYAKO_GETCOLOR(scolor);
        if(scolor.a == 0){ continue; }
        pixel = *(pdst + py * dst->w + px) | dst_a;
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ph += deg;
        if(ph < 0.0){ ph += d_pi; }
        if(ph >= d_pi){ ph -= d_pi; }
        ps += sat;
        if(ps < 0.0){ ps = 0.0; }
        if(ps > 1.0){ ps = 1.0; }
        pv += val;
        if(pv < 0.0){ pv = 0.0; }
        if(pv > 1.0){ pv = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0 || scolor.a == 255){
          MIYAKO_SETCOLOR(*(pdst + py * dst->w + px), scolor);
          continue;
        }
        int a1 = scolor.a + 1;
        int a2 = 256 - scolor.a;
        *(pdst + py * dst->w + px) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                                     (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                                     (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                                     put_a;
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(sunit) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(sunit) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(sunit) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(sunit) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ph += deg;
        if(ph < 0.0){ ph += d_pi; }
        if(ph >= d_pi){ ph -= d_pi; }
        ps += sat;
        if(ps < 0.0){ ps = 0.0; }
        if(ps > 1.0){ ps = 1.0; }
        pv += val;
        if(pv < 0.0){ pv = 0.0; }
        if(pv > 1.0){ pv = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        MIYAKO_SETCOLOR(*(pdst + y * dst->w + x), scolor);
      }
    }

    SDL_UnlockSurface(src);
  }

  return Qnil;
}

/*
===内部用レンダメソッド
*/
static void render_to_inner(VALUE sunit, VALUE dunit)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(sunit)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(dunit)))->surface;

	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	if(psrc == pdst){ return; }
	
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

	//SpriteUnit:
	//[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
	//[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
	//[9] -> :angle, [10] -> :xscale, [11] -> :yscale
	//[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
  MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

	int x = NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
	int y = NUM2INT(*(RSTRUCT_PTR(sunit) + 6));
  MIYAKO_INIT_RECT1;

	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int px, py, sy;
	for(py = dly, sy = srect.y; py < dmy; py++, sy++)
	{
    Uint32 *ppsrc = psrc + sy * src->w + srect.x;
    Uint32 *ppdst = pdst + py * dst->w + dlx;
		for(px = dlx; px < dmx; px++)
		{
			pixel = *ppsrc | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ ppsrc++; ppdst++; continue; }
      pixel = *ppdst | dst_a;
      MIYAKO_GETCOLOR(dcolor);
      if(dcolor.a == 0 || scolor.a == 255){
        *ppdst = *ppsrc | src_a;
        ppsrc++;
        ppdst++;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      scolor.r = (scolor.r * a1 + dcolor.r * a2) >> 8;
      scolor.g = (scolor.g * a1 + dcolor.g * a2) >> 8;
      scolor.b = (scolor.b * a1 + dcolor.b * a2) >> 8;
      scolor.a = 255;
      MIYAKO_SETCOLOR(*ppdst, scolor);
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);
}

/*
===内部用レンダメソッド
*/
static void render_inner(VALUE sunit, VALUE dunit)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(sunit)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(dunit)))->surface;
  SDL_Rect srect;
  SDL_Rect drect;

  MIYAKO_SET_RECT(srect, sunit);
	drect.x = NUM2INT(*(RSTRUCT_PTR(dunit) + 1))
            + NUM2INT(*(RSTRUCT_PTR(sunit) + 5));
	drect.y = NUM2INT(*(RSTRUCT_PTR(dunit) + 2))
	          + NUM2INT(*(RSTRUCT_PTR(sunit) + 6));

  SDL_BlitSurface(src, &srect, dst, &drect);
}

/*
===インスタンスの内容を別のインスタンスに描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
ブロックの引数は、|転送元のSpriteUnit,転送先のSpriteUnit|となる。
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE sprite_c_render_to_sprite(VALUE self, VALUE vsrc, VALUE vdst)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(vsrc, vdst, sunit, dunit);
  render_to_inner(sunit, dunit);
  return self;
}

/*
===インスタンスの内容を画面に描画する
現在の画像を、現在の状態で描画するよう指示する
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit, 画面のSpriteUnit|となる。
返却値:: 自分自身を返す
*/
static VALUE sprite_render(VALUE self)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(self, mScreen, sunit, dunit);
  render_inner(sunit, dunit);
  return self;
}

/*
===インスタンスの内容を別のインスタンスに描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit,転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE sprite_render_to_sprite(VALUE self, VALUE vdst)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(self, vdst, sunit, dunit);
  render_to_inner(sunit, dunit);
  return self;
}

/*
===インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。回転の中心はsrc側(ox,oy)を起点に、src側(cx,cy)が中心になるように設定する。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、画面側SpriteUnitの(cx,cy)が中心になるように設定にする。
回転角度が正だと右回り、負だと左回りに回転する
変形の度合いは、src側SpriteUnitのxscale, yscaleを使用する(ともに実数で指定する)。それぞれ、x方向、y方向の度合いとなる
度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
また、変形元の幅・高さのいずれかが32768以上の時は回転・転送を行わない
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit,画面のSpriteUnit|となる。
返却値:: 自分自身を返す
_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
_xscale_:: 拡大率(x方向)
_yscale_:: 拡大率(y方向)
*/
static VALUE sprite_render_transform(VALUE self, VALUE radian, VALUE xscale, VALUE yscale)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(self, mScreen, sunit, dunit);
  transform_inner(sunit, dunit, radian, xscale, yscale);
  return self;
}

/*
===インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。回転の中心はsrc側(ox,oy)を起点に、src側(cx,cy)が中心になるように設定する。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、画面側SpriteUnitの(cx,cy)が中心になるように設定にする。
回転角度が正だと右回り、負だと左回りに回転する
変形の度合いは、src側SpriteUnitのxscale, yscaleを使用する(ともに実数で指定する)。それぞれ、x方向、y方向の度合いとなる
度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
また、変形元の幅・高さのいずれかが32768以上の時は回転・転送を行わない
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit,転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
_xscale_:: 拡大率(x方向)
_yscale_:: 拡大率(y方向)
返却値:: 自分自身を返す
*/
static VALUE sprite_render_to_sprite_transform(VALUE self, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(self, vdst, sunit, dunit);
  transform_inner(sunit, dunit, radian, xscale, yscale);
  return self;
}

/*
:nodoc:
*/
static VALUE screen_update_tick(VALUE self)
{
  int t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int tt = NUM2INT(rb_iv_get(mScreen, "@@t"));
  int interval = t - tt;
  int fps_cnt = NUM2INT(rb_iv_get(mScreen, "@@fpscnt"));

  while(interval < fps_cnt){
    t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
    interval = t - tt;
  }

  rb_iv_set(mScreen, "@@t", INT2NUM(t));
  rb_iv_set(mScreen, "@@interval", INT2NUM(interval));

  return Qnil;
}

/*
===画面を更新する
画面に画像を貼り付けた時は、実際の描画領域は隠れているため、このメソッドを呼び出して、実際の画面表示に反映させる。
*/
static VALUE screen_render(VALUE self)
{
  VALUE dst = rb_iv_get(mScreen, "@@unit");
	SDL_Surface *pdst = GetSurface(*(RSTRUCT_PTR(dst)))->surface;
  VALUE fps_view = rb_iv_get(mScreen, "@@fpsView");

  if(fps_view == Qtrue){
    char str[256];
    int interval = NUM2INT(rb_iv_get(mScreen, "@@interval"));
    int fps_max = NUM2INT(rb_const_get(mScreen, rb_intern("FpsMax")));
    VALUE sans_serif = rb_funcall(cFont, rb_intern("sans_serif"), 0);
    VALUE fps_sprite = Qnil;

    if(interval == 0){ interval = 1; }

    sprintf(str, "%d fps", fps_max / interval);
    VALUE fps_str = rb_str_new2((const char *)str);
		
    fps_sprite = rb_funcall(fps_str, rb_intern("to_sprite"), 1, sans_serif);
    sprite_render(fps_sprite);
  }

  screen_update_tick(self);

  if(use_opengl == Qfalse)
  {
    SDL_Flip(pdst);
    return Qnil;
  }
  rb_funcall(cGL, rb_intern("swap_buffers"), 0);
  
  return Qnil;
}

/*
===インスタンスの内容を画面に描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit,画面のSpriteUnit|となる。
_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE screen_render_screen(VALUE self, VALUE vsrc)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(vsrc, mScreen, sunit, dunit);
  render_inner(sunit, dunit);
  return self;
}

/*
:nodoc:
*/
static VALUE counter_start(VALUE self)
{
  rb_iv_set(self, "@st", rb_funcall(mSDL, rb_intern("getTicks"), 0));
  rb_iv_set(self, "@counting", Qtrue);
  return self;
}

/*
:nodoc:
*/
static VALUE counter_stop(VALUE self)
{
  rb_iv_set(self, "@st", INT2NUM(0));
  rb_iv_set(self, "@counting", Qfalse);
  return self;
}

/*
:nodoc:
*/
static VALUE counter_wait_inner(VALUE self, VALUE f)
{
  VALUE counting = rb_iv_set(self, "@counting", Qtrue);
  if(counting == Qfalse){ return f == Qtrue ? Qfalse : Qtrue; }

  int t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int st = NUM2INT(rb_iv_get(self, "@st"));
  int wait = NUM2INT(rb_iv_get(self, "@wait"));
  if((t - st) < wait){ return f; }

  rb_iv_set(cWaitCounter, "@counting", Qfalse);

  return f == Qtrue ? Qfalse : Qtrue;
}

/*
:nodoc:
*/
static VALUE counter_waiting(VALUE self)
{
  return counter_wait_inner(self, Qtrue);
}

/*
:nodoc:
*/
static VALUE counter_finish(VALUE self)
{
  return counter_wait_inner(self, Qfalse);
}

/*
:nodoc:
*/
static VALUE counter_wait(VALUE self)
{
  int t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int st = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int wait = NUM2INT(rb_iv_get(self, "@wait"));
  while((t - st) < wait){
    t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  }
  return self;
}


/*
===マップレイヤー転送インナーメソッド
*/
static void maplayer_render_inner(VALUE self, VALUE dunit)
{
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE pos = rb_iv_get(self, "@pos");
  VALUE margin = rb_iv_get(self, "@margin");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0)) + NUM2INT(*(RSTRUCT_PTR(margin) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1)) + NUM2INT(*(RSTRUCT_PTR(margin) + 1));

  VALUE size = rb_iv_get(self, "@size");
  int size_w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int size_h = NUM2INT(*(RSTRUCT_PTR(size) + 1));

  VALUE real_size = rb_iv_get(self, "@real_size");
  int real_size_w = NUM2INT(*(RSTRUCT_PTR(real_size) + 0));
  int real_size_h = NUM2INT(*(RSTRUCT_PTR(real_size) + 1));

  VALUE param = rb_iv_get(self, "@mapchip");
  VALUE mc_chip_size = *(RSTRUCT_PTR(param) + 3);
  int mc_chip_size_w = NUM2INT(*(RSTRUCT_PTR(mc_chip_size) + 0));
  int mc_chip_size_h = NUM2INT(*(RSTRUCT_PTR(mc_chip_size) + 1));

  VALUE munits = rb_iv_get(self, "@mapchip_units");
  VALUE mapdat = rb_iv_get(self, "@mapdat");
  
  if(pos_x < 0){ pos_x = real_size_w + (pos_x % real_size_w); }
  if(pos_y < 0){ pos_y = real_size_h + (pos_y % real_size_h); }
  if(pos_x >= real_size_w){ pos_x %= real_size_w; }
  if(pos_y >= real_size_h){ pos_y %= real_size_h; }

  int dx = pos_x / mc_chip_size_w;
  int mx = pos_x % mc_chip_size_w;
  int dy = pos_y / mc_chip_size_h;
  int my = pos_y % mc_chip_size_h;

  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      VALUE unit = *(RARRAY_PTR(munits) + code);
      unit = rb_funcall(unit, rb_intern("to_unit"), 0);
      VALUE *runit = RSTRUCT_PTR(unit);
      VALUE ox = *(runit + 5);
      VALUE oy = *(runit + 6);
      *(runit + 5) = INT2NUM(x * ow - mx);
      *(runit + 6) = INT2NUM(y * oh - my);
      render_inner(unit, dunit);
      *(runit + 5) = ox;
      *(runit + 6) = oy;
    }
  }
}

/*
===固定マップレイヤー転送インナーメソッド
*/
static void fixedmaplayer_render_inner(VALUE self, VALUE dunit)
{
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE pos = rb_iv_get(self, "@pos");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

  VALUE size = rb_iv_get(self, "@size");
  int size_w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int size_h = NUM2INT(*(RSTRUCT_PTR(size) + 1));

  VALUE munits = rb_iv_get(self, "@mapchip_units");
  VALUE mapdat = rb_iv_get(self, "@mapdat");

  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = y % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      VALUE unit = *(RARRAY_PTR(munits) + code);
      unit = rb_funcall(unit, rb_intern("to_unit"), 0);
      VALUE *runit = RSTRUCT_PTR(unit);
      VALUE ox = *(runit + 5);
      VALUE oy = *(runit + 6);
      *(runit + 5) = INT2NUM(pos_x + x * ow);
      *(runit + 6) = INT2NUM(pos_y + y * oh);
      render_inner(unit, dunit);
      *(runit + 5) = ox;
      *(runit + 6) = oy;
    }
  }
}

/*
===マップレイヤー転送インナーメソッド
*/
static void maplayer_render_to_inner(VALUE self, VALUE dunit)
{
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE pos = rb_iv_get(self, "@pos");
  VALUE margin = rb_iv_get(self, "@margin");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0)) + NUM2INT(*(RSTRUCT_PTR(margin) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1)) + NUM2INT(*(RSTRUCT_PTR(margin) + 1));

  VALUE size = rb_iv_get(self, "@size");
  int size_w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int size_h = NUM2INT(*(RSTRUCT_PTR(size) + 1));

  VALUE real_size = rb_iv_get(self, "@real_size");
  int real_size_w = NUM2INT(*(RSTRUCT_PTR(real_size) + 0));
  int real_size_h = NUM2INT(*(RSTRUCT_PTR(real_size) + 1));

  VALUE param = rb_iv_get(self, "@mapchip");
  VALUE mc_chip_size = *(RSTRUCT_PTR(param) + 3);
  int mc_chip_size_w = NUM2INT(*(RSTRUCT_PTR(mc_chip_size) + 0));
  int mc_chip_size_h = NUM2INT(*(RSTRUCT_PTR(mc_chip_size) + 1));

  VALUE munits = rb_iv_get(self, "@mapchip_units");
  VALUE mapdat = rb_iv_get(self, "@mapdat");
  
  if(pos_x < 0){ pos_x = real_size_w + (pos_x % real_size_w); }
  if(pos_y < 0){ pos_y = real_size_h + (pos_y % real_size_h); }
  if(pos_x >= real_size_w){ pos_x %= real_size_w; }
  if(pos_y >= real_size_h){ pos_y %= real_size_h; }

  int dx = pos_x / mc_chip_size_w;
  int mx = pos_x % mc_chip_size_w;
  int dy = pos_y / mc_chip_size_h;
  int my = pos_y % mc_chip_size_h;

  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      VALUE unit = *(RARRAY_PTR(munits) + code);
      unit = rb_funcall(unit, rb_intern("to_unit"), 0);
      VALUE *runit = RSTRUCT_PTR(unit);
      VALUE ox = *(runit + 5);
      VALUE oy = *(runit + 6);
      *(runit + 5) = INT2NUM(x * ow - mx);
      *(runit + 6) = INT2NUM(y * oh - my);
      render_to_inner(unit, dunit);
      *(runit + 5) = ox;
      *(runit + 6) = oy;
    }
  }
}

/*
===固定マップレイヤー転送インナーメソッド
*/
static void fixedmaplayer_render_to_inner(VALUE self, VALUE dunit)
{
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE pos = rb_iv_get(self, "@pos");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

  VALUE size = rb_iv_get(self, "@size");
  int size_w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int size_h = NUM2INT(*(RSTRUCT_PTR(size) + 1));

  VALUE munits = rb_iv_get(self, "@mapchip_units");
  VALUE mapdat = rb_iv_get(self, "@mapdat");

  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = y % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      VALUE unit = *(RARRAY_PTR(munits) + code);
      unit = rb_funcall(unit, rb_intern("to_unit"), 0);
      VALUE *runit = RSTRUCT_PTR(unit);
      VALUE ox = *(runit + 5);
      VALUE oy = *(runit + 6);
      *(runit + 5) = INT2NUM(pos_x + x * ow);
      *(runit + 6) = INT2NUM(pos_y + y * oh);
      render_to_inner(unit, dunit);
      *(runit + 5) = ox;
      *(runit + 6) = oy;
    }
  }
}

/*
===マップレイヤーを画面に描画する
転送する画像は、マップ上のから(-margin.x, -margin.y)(単位：ピクセル)の位置に対応するチップを左上にして描画する
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|画面のSpriteUnit|となる。
返却値:: 自分自身を返す
*/
static VALUE maplayer_render(VALUE self)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(mScreen, dunit);
  maplayer_render_inner(self, dunit);
  return Qnil;
}

/*
===マップレイヤーを画面に描画する
すべてのマップチップを画面に描画する
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|画面のSpriteUnit|となる。
返却値:: 自分自身を返す
*/
static VALUE fixedmaplayer_render(VALUE self)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(mScreen, dunit);
  fixedmaplayer_render_inner(self, dunit);
  return Qnil;
}

/*
===マップレイヤーを画像に転送する
転送する画像は、マップ上のから(-margin.x, -margin.y)(単位：ピクセル)の位置に対応するチップを左上にして描画する
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE maplayer_render_to_sprite(VALUE self, VALUE vdst)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(vdst, dunit);
  maplayer_render_to_inner(self, dunit);
  return Qnil;
}

/*
===マップレイヤーを画像に転送する
すべてのマップチップを画像に描画する
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE fixedmaplayer_render_to_sprite(VALUE self, VALUE vdst)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(vdst, dunit);
  fixedmaplayer_render_to_inner(self, dunit);
  return Qnil;
}

/*
===マップを画面に描画する
転送する画像は、マップ上のから(-margin.x, -margin.y)(単位：ピクセル)の位置に対応するチップを左上にして描画する
各レイヤ－を、レイヤーインデックス番号の若い順に描画する
但し、マップイベントは描画しない
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|画面のSpriteUnit|となる。
返却値:: 自分自身を返す
*/
static VALUE map_render(VALUE self)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(mScreen, dunit);
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render_inner(*(RARRAY_PTR(map_layers) + i), dunit);
  }
  
  return Qnil;
}

/*
===マップを画面に描画する
すべてのマップチップを画面に描画する
各レイヤ－を、レイヤーインデックス番号の若い順に描画する
但し、マップイベントは描画しない
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|画面のSpriteUnit|となる。
返却値:: 自分自身を返す
*/
static VALUE fixedmap_render(VALUE self)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(mScreen, dunit);
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render_inner(*(RARRAY_PTR(map_layers) + i), dunit);
  }

  return Qnil;
}

/*
===マップを画像に描画する
転送する画像は、マップ上のから(-margin.x, -margin.y)(単位：ピクセル)の位置に対応するチップを左上にして描画する
各レイヤ－を、レイヤーインデックス番号の若い順に描画する
但し、マップイベントは描画しない
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE map_render_to_sprite(VALUE self, VALUE vdst)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(vdst, dunit);

  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render_to_sprite(*(RARRAY_PTR(map_layers) + i), dunit);
  }

  return Qnil;
}

/*
===マップを画像に描画する
すべてのマップチップを画像に描画する
各レイヤ－を、レイヤーインデックス番号の若い順に描画する
但し、マップイベントは描画しない
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
返却値:: 自分自身を返す
*/
static VALUE fixedmap_render_to_sprite(VALUE self, VALUE vdst)
{
  MIYAKO_GET_UNIT_NO_SURFACE_1(vdst, dunit);

  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render_to_sprite(*(RARRAY_PTR(map_layers) + i), dunit);
  }

  return Qnil;
}

/*
:nodoc:
*/
static VALUE sa_set_pat(VALUE self)
{
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE units = rb_iv_get(self, "@units");
  rb_iv_set(self, "@now", *(RARRAY_PTR(units) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num)))));
  return self;
}

/*
:nodoc:
*/
static VALUE sa_update_frame(VALUE self)
{
  int cnt = NUM2INT(rb_iv_get(self, "@cnt"));

  if(cnt > 0){
    cnt--;
    rb_iv_set(self, "@cnt", INT2NUM(cnt));
    return Qfalse;
  }

  VALUE num = rb_iv_get(self, "@pnum");
  VALUE loop = rb_iv_get(self, "@loop");

  int pnum = NUM2INT(num);
  int pats = NUM2INT(rb_iv_get(self, "@pats"));
  pnum = (pnum + 1) % pats;

  rb_iv_set(self, "@pnum", INT2NUM(pnum));

  if(loop == Qfalse && pnum == 0){
    rb_funcall(self, rb_intern("stop"), 0);
    return Qfalse;
  }

  sa_set_pat(self);
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE waits = rb_iv_get(self, "@waits");
  rb_iv_set(self, "@cnt", *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum))));

  return Qtrue;
}

/*
:nodoc:
*/
static VALUE sa_update_wait_counter(VALUE self)
{
  VALUE cnt = rb_iv_get(self, "@cnt");
  VALUE waiting = rb_funcall(cnt, rb_intern("waiting?"), 0);

  if(waiting == Qtrue) return Qfalse;
  
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE loop = rb_iv_get(self, "@loop");

  int pnum = NUM2INT(num);
  int pats = NUM2INT(rb_iv_get(self, "@pats"));
  pnum = (pnum + 1) % pats;
    
  rb_iv_set(self, "@pnum", INT2NUM(pnum));
    
  if(loop == Qfalse && pnum == 0){
    rb_funcall(self, rb_intern("stop"), 0);
    return Qfalse;
  }

  sa_set_pat(self);
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE waits = rb_iv_get(self, "@waits");
  cnt = *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum)));
  rb_iv_set(self, "@cnt", cnt);
  rb_funcall(cnt, rb_intern("start"), 0);
  return Qtrue;
}

/*
:nodoc:
*/
static VALUE sa_update(VALUE self)
{
  VALUE is_change = Qfalse;
  VALUE exec = rb_iv_get(self, "@exec");
  if(exec == Qfalse){ return is_change; }

  if(rb_obj_is_kind_of(rb_iv_get(self, "@cnt"), rb_cInteger) == Qtrue)
    is_change = sa_update_frame(self);
  else
    is_change = sa_update_wait_counter(self);
  
  return is_change;
}

/*
===アニメーションの現在の画像を画面に描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit|となる。
*/
static VALUE sa_render(VALUE self)
{
  VALUE vsrc = rb_iv_get(self, "@now");
  VALUE *runit = RSTRUCT_PTR(vsrc);
  VALUE polist = rb_iv_get(self, "@pos_offset");
  VALUE dir = rb_iv_get(self, "@dir");
  
  int num = NUM2INT(rb_iv_get(self, "@pnum"));

  VALUE molist = rb_iv_get(self, "@move_offset");
  VALUE move_off = *(RARRAY_PTR(molist) + num);

  int pos_off = NUM2INT(*(RARRAY_PTR(polist) + num));

  int didx = (rb_to_id(dir) == rb_intern("h") ? 3 : 2);
  
  VALUE tmp_oxy = *(runit +  didx);
  VALUE tmp_x = *(runit + 5);
  VALUE tmp_y = *(runit + 6);

  *(runit + didx) = INT2NUM(NUM2INT(tmp_oxy) - pos_off);
  *(runit + 5) = INT2NUM(NUM2INT(tmp_x) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nZero)));
  *(runit + 6) = INT2NUM(NUM2INT(tmp_y) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nOne )));

  MIYAKO_GET_UNIT_NO_SURFACE_2(vsrc, mScreen, sunit, dunit);
  render_inner(sunit, dunit);

  *(runit + 5) = tmp_x;
  *(runit + 6) = tmp_y;
  *(runit + didx) = tmp_oxy;

  return Qnil;
}

/*
===アニメーションの現在の画像を画像に描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|インスタンスのSpriteUnit,転送先のSpriteUnit|となる。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
*/
static VALUE sa_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE vsrc = rb_iv_get(self, "@now");
  VALUE *runit = RSTRUCT_PTR(vsrc);
  VALUE polist = rb_iv_get(self, "@pos_offset");
  VALUE dir = rb_iv_get(self, "@dir");
  
  int num = NUM2INT(rb_iv_get(self, "@pnum"));

  int pos_off = NUM2INT(*(RARRAY_PTR(polist) + num));

  VALUE molist = rb_iv_get(self, "@move_offset");
  VALUE move_off = *(RARRAY_PTR(molist) + num);

  int didx = (rb_to_id(dir) == rb_intern("h") ? 3 : 2);
  
  VALUE tmp_oxy = *(runit +  didx);
  VALUE tmp_x = *(runit + 5);
  VALUE tmp_y = *(runit + 6);

  *(runit + didx) = INT2NUM(NUM2INT(tmp_oxy) - pos_off);
  *(runit + 5) = INT2NUM(NUM2INT(tmp_x) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nZero)));
  *(runit + 6) = INT2NUM(NUM2INT(tmp_y) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nOne )));

  MIYAKO_GET_UNIT_NO_SURFACE_2(vsrc, vdst, sunit, dunit);
  render_to_inner(sunit, dunit);

  *(runit + 5) = tmp_x;
  *(runit + 6) = tmp_y;
  *(runit + didx) = tmp_oxy;

  return Qnil;
}

/*
===プレーンを画面に描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点にする。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、タイリングを行いながら貼り付ける。
*/
static VALUE plane_render(VALUE self)
{
  VALUE sprite = rb_iv_get(self, "@sprite");
  MIYAKO_GET_UNIT_NO_SURFACE_2(sprite, mScreen, sunit, dunit);

  VALUE ssize = rb_iv_get(mScreen, "@@size");
  int ssw = NUM2INT(*(RSTRUCT_PTR(ssize) + 0));
  int ssh = NUM2INT(*(RSTRUCT_PTR(ssize) + 1));
  VALUE pos = rb_iv_get(self, "@pos");
  VALUE size = rb_iv_get(self, "@size");
  int w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

  VALUE *psunit = RSTRUCT_PTR(sunit);
  int sw = NUM2INT(*(psunit + 3));
  int sh = NUM2INT(*(psunit + 4));

  int x, y;
  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      int x2 = (x-1) * sw + pos_x;
      int y2 = (y-1) * sh + pos_y;
      if(x2 > 0 || y2 > 0
      || (x2+sw) <= ssw || (y2+sh) <= ssh){
        *(psunit + 5) = INT2NUM(x2);
        *(psunit + 6) = INT2NUM(y2);
        render_inner(sunit, dunit);
      }
    }
  }
  
  return Qnil;
}

/*
===プレーンを画像に描画する
転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点にする。
転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、タイリングを行いながら貼り付ける。
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
*/
static VALUE plane_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE sprite = rb_iv_get(self, "@sprite");
  MIYAKO_GET_UNIT_NO_SURFACE_2(sprite, vdst, sunit, dunit);

  VALUE ssize = rb_iv_get(mScreen, "@@size");
  int ssw = NUM2INT(*(RSTRUCT_PTR(ssize) + 0));
  int ssh = NUM2INT(*(RSTRUCT_PTR(ssize) + 1));
  VALUE pos = rb_iv_get(self, "@pos");
  VALUE size = rb_iv_get(self, "@size");
  int w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

  VALUE *psunit = RSTRUCT_PTR(sunit);
  int sw = NUM2INT(*psunit + 3);
  int sh = NUM2INT(*psunit + 4);

  int x, y;
  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      int x2 = (x-1) * sw + pos_x;
      int y2 = (y-1) * sh + pos_y;
      if(x2 > 0 || y2 > 0
      || (x2+sw) <= ssw || (y2+sh) <= ssh){
        *(psunit + 5) = INT2NUM(x2);
        *(psunit + 6) = INT2NUM(y2);
        render_to_inner(sunit, dunit);
      }
    }
  }
  
  return Qnil;
}

/*
===パーツを画面に描画する
各パーツの描画範囲は、それぞれのSpriteUnitの(ox,oy)を起点にする。
画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、各パーツを貼り付ける。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|パーツのSpriteUnit|となる。
デフォルトでは、描画順は登録順となる。順番を変更したいときは、renderメソッドをオーバーライドする必要がある
*/
static VALUE parts_render(VALUE self)
{
  VALUE parts_list = rb_iv_get(self, "@parts_list");
  VALUE parts_hash = rb_iv_get(self, "@parts");

  int i;
  for(i=0; i<RARRAY_LEN(parts_list); i++)
  {
    VALUE parts = rb_hash_aref(parts_hash, *(RARRAY_PTR(parts_list) + i));
    rb_funcall(parts, rb_intern("render"), 0);
  }
  
  return Qnil;
}

/*
===パーツを画面に描画する
各パーツの描画範囲は、それぞれのSpriteUnitの(ox,oy)を起点にする。
転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、タイリングを行いながら貼り付ける。
ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
ブロックの引数は、|パーツのSpriteUnit|となる。
デフォルトでは、描画順は登録順となる。順番を変更したいときは、render_toメソッドをオーバーライドする必要がある
_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
*/
static VALUE parts_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE parts_list = rb_iv_get(self, "@parts_list");
  VALUE parts_hash = rb_iv_get(self, "@parts");

  int i;
  for(i=0; i<RARRAY_LEN(parts_list); i++)
  {
    VALUE parts = rb_hash_aref(parts_hash, *(RARRAY_PTR(parts_list) + i));
    rb_funcall(parts, rb_intern("render_to"), 1, vdst);
  }
  
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collision_c_collision(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1));
  int r1 = l1 + NUM2INT(*(prect1+2)) - 1;
  int b1 = t1 + NUM2INT(*(prect1+3)) - 1;
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1));
  int r2 = l2 + NUM2INT(*(prect2+2)) - 1;
  int b2 = t2 + NUM2INT(*(prect2+3)) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_collision_with_move(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  VALUE *pdir1 = RSTRUCT_PTR(rb_iv_get(c1, "@direction"));
  VALUE *pdir2 = RSTRUCT_PTR(rb_iv_get(c2, "@direction"));
  VALUE *pamt1 = RSTRUCT_PTR(rb_iv_get(c1, "@amount"));
  VALUE *pamt2 = RSTRUCT_PTR(rb_iv_get(c2, "@amount"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1) + NUM2INT(*pdir1) * NUM2INT(*pamt1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1)) + NUM2INT(*(pdir1+1)) * NUM2INT(*(pamt1+1));
  int r1 = l1 + NUM2INT(*(prect1+2)) - 1;
  int b1 = t1 + NUM2INT(*(prect1+3)) - 1;
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2) + NUM2INT(*pdir2) * NUM2INT(*pamt2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1)) + NUM2INT(*(pdir2+1)) * NUM2INT(*(pamt2+1));
  int r2 = l2 + NUM2INT(*(prect2+2)) - 1;
  int b2 = t2 + NUM2INT(*(prect2+3)) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_meet(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1));
  int r1 = l1 + NUM2INT(*(prect1+2));
  int b1 = t1 + NUM2INT(*(prect1+3));
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1));
  int r2 = l2 + NUM2INT(*(prect2+2));
  int b2 = t2 + NUM2INT(*(prect2+3));

  int v = 0;
  if(r1 == l2) v |= 1;
  if(b1 == t2) v |= 1;
  if(l1 == r2) v |= 1;
  if(t1 == b2) v |= 1;

  if(v == 1) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_into(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qfalse && f2 == Qtrue) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_out(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qtrue && f2 == Qfalse) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_cover(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1));
  int r1 = l1 + NUM2INT(*(prect1+2)) - 1;
  int b1 = t1 + NUM2INT(*(prect1+3)) - 1;
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1));
  int r2 = l2 + NUM2INT(*(prect2+2)) - 1;
  int b2 = t2 + NUM2INT(*(prect2+3)) - 1;

  int v = 0;
  if(l1 <= l2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && b2 <= b1) v |= 2;
  if(l2 <= l1 && r1 <= r2) v |= 4;
  if(t2 <= t1 && b1 <= b2) v |= 8;

  if(v == 3 || v == 12) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_collision(VALUE self, VALUE c2)
{
  return collision_c_collision(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_meet(VALUE self, VALUE c2)
{
  return collision_c_meet(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_into(VALUE self, VALUE c2)
{
  return collision_c_into(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_out(VALUE self, VALUE c2)
{
  return collision_c_out(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_cover(VALUE self, VALUE c2)
{
  return collision_c_cover(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collisions_collision(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_collision(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_meet(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_meet(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_into(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_into(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_out(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_out(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_cover(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_cover(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_collision_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_collision(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_meet_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_meet(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_into_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_into(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_out_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_out(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_cover_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_cover(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE processor_mainloop(VALUE self)
{
  VALUE diagram = rb_iv_get(self, "@diagram");
  VALUE states = rb_iv_get(self, "@states");
  VALUE mutex = rb_iv_get(self, "@mutex");
  VALUE str_execute = rb_str_new2("execute");
  VALUE sym_execute = rb_funcall(str_execute, rb_intern("to_sym"), 0);
  VALUE str_pause = rb_str_new2("pause");
  VALUE sym_pause = rb_funcall(str_pause, rb_intern("to_sym"), 0);
  rb_funcall(diagram, rb_intern("start"), 0);
  VALUE executing = rb_funcall(states, id_kakko, 1, sym_execute);
  while(executing == Qtrue){
    VALUE pausing = rb_funcall(states, id_kakko, 1, sym_pause);
    if(pausing == Qfalse){
        rb_funcall(mutex, rb_intern("lock"), 0);
        rb_funcall(diagram, id_update, 0);
        rb_funcall(mutex, rb_intern("unlock"), 0);
        rb_funcall(cThread, rb_intern("pass"), 0);
        VALUE is_finish = rb_funcall(diagram, rb_intern("finish?"), 0);
        if(is_finish == Qtrue){ rb_funcall(states, rb_intern("[]="), 2, sym_execute, Qfalse); }
    }
    executing = rb_funcall(states, id_kakko, 1, sym_execute);
  }
  rb_funcall(diagram, rb_intern("stop"), 0);
  return self;
}

static VALUE layout_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *off = RSTRUCT_PTR(*(RSTRUCT_PTR(rb_iv_get(self, "@layout")) + 3));
  VALUE *pox = off+0;
  VALUE *poy = off+1;
  VALUE tx = *pox;
  VALUE ty = *poy;
  *pox = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *poy = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  rb_funcall(self, rb_intern("calc_layout"), 0);
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pox = tx;
    *poy = ty;
    rb_funcall(self, rb_intern("calc_layout"), 0);
  }
  return Qnil;
}

static VALUE layout_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *layout = RSTRUCT_PTR(rb_iv_get(self, "@layout"));
  VALUE *off = RSTRUCT_PTR(*(layout + 3));
  VALUE *pos = RSTRUCT_PTR(*(layout + 0));
  VALUE tx = *(off+0);
  VALUE ty = *(off+1);
  *(off+0) = INT2NUM(NUM2INT(tx)+NUM2INT(x)-NUM2INT(*(pos+0)));
  *(off+1) = INT2NUM(NUM2INT(ty)+NUM2INT(y)-NUM2INT(*(pos+1)));
  rb_funcall(self, rb_intern("calc_layout"), 0);
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *(off+0) = tx;
    *(off+1) = ty;
    rb_funcall(self, rb_intern("calc_layout"), 0);
  }
  return Qnil;
}

static VALUE su_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+5;
  VALUE *py = st+6;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *py = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE su_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+5;
  VALUE *py = st+6;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = x;
  *py = y;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE point_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+0;
  VALUE *py = st+1;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *py = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE point_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+0;
  VALUE *py = st+1;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = x;
  *py = y;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE size_resize(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+0;
  VALUE *ph = st+1;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = w;
  *ph = h;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pw = tw;
    *ph = th;
  }
  return Qnil;
}

static VALUE rect_resize(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+2;
  VALUE *ph = st+3;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = w;
  *ph = h;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pw = tw;
    *ph = th;
  }
  return Qnil;
}

static VALUE rect_in_range(VALUE self, VALUE vx, VALUE vy)
{
  VALUE *st = RSTRUCT_PTR(self);
  int l = NUM2INT(*(st+0));
  int t = NUM2INT(*(st+1));
  int w = NUM2INT(*(st+2));
  int h = NUM2INT(*(st+3));
  int x = NUM2INT(vx);
  int y = NUM2INT(vy);
  
  if(x >= l && y >= t && x < (l+w) && y < (t+h)){ return Qtrue; }
  return Qfalse;
}

static VALUE square_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pl = st+0;
  VALUE *pt = st+1;
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tl = *pl;
  VALUE tt = *pt;
  VALUE tr = *pr;
  VALUE tb = *pb;
  *pl = INT2NUM(NUM2INT(tl)+NUM2INT(dx));
  *pt = INT2NUM(NUM2INT(tt)+NUM2INT(dy));
  *pr = INT2NUM(NUM2INT(tr)+NUM2INT(dx));
  *pb = INT2NUM(NUM2INT(tb)+NUM2INT(dy));
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pl = tl;
    *pt = tt;
    *pr = tr;
    *pb = tb;
  }
  return Qnil;
}

static VALUE square_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pl = st+0;
  VALUE *pt = st+1;
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tl = *pl;
  VALUE tt = *pt;
  VALUE tr = *pr;
  VALUE tb = *pb;
  int w = NUM2INT(tr)-NUM2INT(tl);
  int h = NUM2INT(tb)-NUM2INT(tt);
  *pl = x;
  *pt = y;
  *pr = INT2NUM(NUM2INT(x)+w);
  *pb = INT2NUM(NUM2INT(y)+h);
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pl = tl;
    *pt = tt;
    *pr = tr;
    *pb = tb;
  }
  return Qnil;
}

static VALUE square_resize(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pl = st+0;
  VALUE *pt = st+1;
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tr = *pr;
  VALUE tb = *pb;
  *pr = INT2NUM(NUM2INT(*pl) + NUM2INT(w) - 1);
  *pb = INT2NUM(NUM2INT(*pt) + NUM2INT(h) - 1);
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pr = tr;
    *pb = tb;
  }
  return Qnil;
}

static VALUE square_in_range(VALUE self, VALUE vx, VALUE vy)
{
  VALUE *st = RSTRUCT_PTR(self);
  int l = NUM2INT(*(st+0));
  int t = NUM2INT(*(st+1));
  int r = NUM2INT(*(st+2));
  int b = NUM2INT(*(st+3));
  int x = NUM2INT(vx);
  int y = NUM2INT(vy);
  
  if(x >= l && y >= t && x <= r && y <= b){ return Qtrue; }
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE yuki_update_plot_thread(VALUE self)
{
  VALUE yuki = rb_iv_get(self, "@yuki");
  VALUE str_exec = rb_str_new2("exec_plot");
  VALUE sym_exec = rb_funcall(str_exec, rb_intern("to_sym"), 0);
  VALUE str_pausing = rb_str_new2("pausing");
  VALUE sym_pausing = rb_funcall(str_pausing, rb_intern("to_sym"), 0);
  VALUE str_selecting = rb_str_new2("exec_selecting");
  VALUE sym_selecting = rb_funcall(str_selecting, rb_intern("to_sym"), 0);
  VALUE str_waiting = rb_str_new2("waiting");
  VALUE sym_waiting = rb_funcall(str_waiting, rb_intern("to_sym"), 0);
  VALUE exec = rb_funcall(yuki, id_kakko, 1, sym_exec);
  while(exec == Qtrue){
    VALUE pausing   = rb_funcall(yuki, id_kakko, 1, sym_pausing);
    if(pausing == Qtrue){ rb_funcall(self, rb_intern("pausing"), 0); }
    VALUE selecting = rb_funcall(yuki, id_kakko, 1, sym_selecting);
    if(selecting == Qtrue){ rb_funcall(self, rb_intern("selecting"), 0); }
    VALUE waiting   = rb_funcall(yuki, id_kakko, 1, sym_waiting);
    if(waiting == Qtrue){ rb_funcall(self, rb_intern("waiting"), 0); }
    rb_funcall(cThread, rb_intern("pass"), 0);
    exec = rb_funcall(yuki, id_kakko, 1, sym_exec);
  }
  return self;
}

void Init_miyako_no_katana()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  mInput = rb_define_module_under(mMiyako, "Input");
  mMapEvent = rb_define_module_under(mMiyako, "MapEvent");
  mLayout = rb_define_module_under(mMiyako, "Layout");
  mDiagram = rb_define_module_under(mMiyako, "Diagram");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cGL  = rb_define_module_under(mSDL, "GL");
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cEvent2  = rb_define_class_under(mSDL, "Event2", rb_cObject);
  cJoystick  = rb_define_class_under(mSDL, "Joystick", rb_cObject);
  cWaitCounter  = rb_define_class_under(mMiyako, "WaitCounter", rb_cObject);
  cFont  = rb_define_class_under(mMiyako, "Font", rb_cObject);
  cColor  = rb_define_class_under(mMiyako, "Color", rb_cObject);
  cBitmap = rb_define_class_under(mMiyako, "Bitmap", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);
  cSpriteAnimation = rb_define_class_under(mMiyako, "SpriteAnimation", rb_cObject);
  sSpriteUnit = rb_define_class_under(mMiyako, "SpriteUnitBase", rb_cStruct);
  cPlane = rb_define_class_under(mMiyako, "Plane", rb_cObject);
  cParts = rb_define_class_under(mMiyako, "Parts", rb_cObject);
  cTextBox = rb_define_class_under(mMiyako, "TextBox", rb_cObject);
  cMap = rb_define_class_under(mMiyako, "Map", rb_cObject);
  cMapLayer = rb_define_class_under(cMap, "MapLayer", rb_cObject);
  cFixedMap = rb_define_class_under(mMiyako, "FixedMap", rb_cObject);
  cFixedMapLayer = rb_define_class_under(cFixedMap, "FixedMapLayer", rb_cObject);
  cCollision = rb_define_class_under(mMiyako, "Collision", rb_cObject);
  cCollisions = rb_define_class_under(mMiyako, "Collisions", rb_cObject);
  cMovie = rb_define_class_under(mMiyako, "Movie", rb_cObject);
  cProcessor = rb_define_class_under(mDiagram, "Processor", rb_cObject);
  cYuki = rb_define_class_under(mMiyako, "Yuki", rb_cObject);
  cThread = rb_define_class("Thread", rb_cObject);
  sPoint = rb_define_class_under(mMiyako, "PointStruct", rb_cStruct);
  sSize = rb_define_class_under(mMiyako, "SizeStruct", rb_cStruct);
  sRect = rb_define_class_under(mMiyako, "RectStruct", rb_cStruct);
  sSquare = rb_define_class_under(mMiyako, "SquareStruct", rb_cStruct);

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_singleton_method(cBitmap, "blit_aa!", bitmap_miyako_blit_aa, 4);
  rb_define_singleton_method(cBitmap, "blit_and!", bitmap_miyako_blit_and, 3);
  rb_define_singleton_method(cBitmap, "blit_or!", bitmap_miyako_blit_or, 3);
  rb_define_singleton_method(cBitmap, "blit_xor!", bitmap_miyako_blit_xor, 3);
  rb_define_singleton_method(cBitmap, "ck_to_ac!", bitmap_miyako_colorkey_to_alphachannel, 3);
  rb_define_singleton_method(cBitmap, "reset_ac!", bitmap_miyako_reset_alphachannel, 2);
  rb_define_singleton_method(cBitmap, "normal_to_ac!", bitmap_miyako_normal_to_alphachannel, 2);
  rb_define_singleton_method(cBitmap, "screen_to_ac!", bitmap_miyako_screen_to_alphachannel, 2);
  rb_define_singleton_method(cBitmap, "dec_alpha!", bitmap_miyako_dec_alpha, 3);
  rb_define_singleton_method(cBitmap, "black_out!", bitmap_miyako_black_out, 3);
  rb_define_singleton_method(cBitmap, "white_out!", bitmap_miyako_white_out, 3);
  rb_define_singleton_method(cBitmap, "inverse!", bitmap_miyako_inverse, 3);
  rb_define_singleton_method(cBitmap, "additive!", bitmap_miyako_additive_synthesis, 2);
  rb_define_singleton_method(cBitmap, "subtraction!", bitmap_miyako_subtraction_synthesis, 2);
  rb_define_singleton_method(cBitmap, "subtraction!", bitmap_miyako_subtraction_synthesis, 2);

	rb_define_singleton_method(cBitmap, "rotate", bitmap_miyako_rotate, 3);
	rb_define_singleton_method(cBitmap, "scale", bitmap_miyako_scale, 4);
	rb_define_singleton_method(cBitmap, "transform", bitmap_miyako_transform, 5);

  rb_define_singleton_method(cBitmap, "hue!", bitmap_miyako_hue, 3);
  rb_define_singleton_method(cBitmap, "saturation!", bitmap_miyako_saturation, 3);
  rb_define_singleton_method(cBitmap, "value!", bitmap_miyako_value, 3);
  rb_define_singleton_method(cBitmap, "hsv!", bitmap_miyako_hsv, 5);

  rb_define_module_function(mScreen, "update_tick", screen_update_tick, 0);
  rb_define_module_function(mScreen, "render", screen_render, 0);
  rb_define_module_function(mScreen, "render_screen", screen_render_screen, 1);

	rb_define_method(mLayout, "move", layout_move, 2);
	rb_define_method(mLayout, "move_to", layout_move_to, 2);
  
  rb_define_method(cWaitCounter, "start", counter_start, 0);
  rb_define_method(cWaitCounter, "stop",  counter_stop,  0);
  rb_define_method(cWaitCounter, "wait_inner", counter_wait_inner, 1);
  rb_define_method(cWaitCounter, "waiting?", counter_waiting, 0);
  rb_define_method(cWaitCounter, "finish?", counter_finish, 0);
  rb_define_method(cWaitCounter, "wait", counter_wait, 0);

  rb_define_method(cSpriteAnimation, "update_animation", sa_update, 0);
  rb_define_method(cSpriteAnimation, "update_frame", sa_update_frame, 0);
  rb_define_method(cSpriteAnimation, "update_wait_counter", sa_update_wait_counter, 0);
  rb_define_method(cSpriteAnimation, "set_pat", sa_set_pat, 0);
  rb_define_method(cSpriteAnimation, "render", sa_render, 0);
  rb_define_method(cSpriteAnimation, "render_to", sa_render_to_sprite, 1);

  rb_define_singleton_method(cSprite, "render_to", sprite_c_render_to_sprite, 2);
  rb_define_method(cSprite, "render", sprite_render, 0);
  rb_define_method(cSprite, "render_to", sprite_render_to_sprite, 1);
  rb_define_method(cSprite, "render_transform", sprite_render_transform, 3);
  rb_define_method(cSprite, "render_to_transform", sprite_render_to_sprite_transform, 4);

  rb_define_method(sSpriteUnit, "move", su_move, 2);
  rb_define_method(sSpriteUnit, "move_to", su_move_to, 2);

  rb_define_method(cPlane, "render", plane_render, 0);
  rb_define_method(cPlane, "render_to", plane_render_to_sprite, 1);

  rb_define_method(cParts, "render", parts_render, 0);
  rb_define_method(cParts, "render_to", parts_render_to_sprite, 1);

  rb_define_singleton_method(cCollision, "collision?", collision_c_collision, 2);
  rb_define_singleton_method(cCollision, "meet?", collision_c_meet, 2);
  rb_define_singleton_method(cCollision, "into?", collision_c_into, 2);
  rb_define_singleton_method(cCollision, "out?", collision_c_out, 2);
  rb_define_singleton_method(cCollision, "cover?", collision_c_cover, 2);
  rb_define_method(cCollision, "collision?", collision_collision, 1);
  rb_define_method(cCollision, "meet?", collision_meet, 1);
  rb_define_method(cCollision, "into?", collision_into, 1);
  rb_define_method(cCollision, "out?", collision_out, 1);
  rb_define_method(cCollision, "cover?", collision_cover, 1);

  rb_define_method(cCollisions, "collision?", collisions_collision, 1);
  rb_define_method(cCollisions, "meet?", collisions_meet, 1);
  rb_define_method(cCollisions, "into?", collisions_into, 1);
  rb_define_method(cCollisions, "out?", collisions_out, 1);
  rb_define_method(cCollisions, "cover?", collisions_cover, 1);
  rb_define_method(cCollisions, "collision_all?", collisions_collision_all, 1);
  rb_define_method(cCollisions, "meet_all?", collisions_meet_all, 1);
  rb_define_method(cCollisions, "into_all?", collisions_into_all, 1);
  rb_define_method(cCollisions, "out_all?", collisions_out_all, 1);
  rb_define_method(cCollisions, "cover_all?", collisions_cover_all, 1);

  rb_define_method(cProcessor, "main_loop", processor_mainloop, 0);
  rb_define_method(cYuki, "update_plot_thread", yuki_update_plot_thread, 0);
  
  rb_define_method(cMapLayer, "render", maplayer_render, 0);
  rb_define_method(cFixedMapLayer, "render", fixedmaplayer_render, 0);
  rb_define_method(cMap, "render", map_render, 0);
  rb_define_method(cFixedMap, "render", fixedmap_render, 0);
  rb_define_method(cMap, "render_to", map_render_to_sprite, 1);
  rb_define_method(cFixedMap, "render_to", fixedmap_render_to_sprite, 1);
  rb_define_method(cMapLayer, "render_to", maplayer_render_to_sprite, 1);
  rb_define_method(cFixedMapLayer, "render_to", fixedmaplayer_render_to_sprite, 1);

  rb_define_method(sPoint, "move", point_move, 2);
  rb_define_method(sPoint, "move_to", point_move_to, 2);
  rb_define_method(sSize, "resize", size_resize, 2);
  rb_define_method(sRect, "move", point_move, 2);
  rb_define_method(sRect, "move_to", point_move_to, 2);
  rb_define_method(sRect, "resize", rect_resize, 2);
  rb_define_method(sRect, "in_range?", rect_in_range, 2);
  rb_define_method(sSquare, "move", square_move, 2);
  rb_define_method(sSquare, "move_to", square_move_to, 2);
  rb_define_method(sSquare, "resize", square_resize, 2);
  rb_define_method(sSquare, "in_range?", square_in_range, 2);
  
  int i;
  for(i=0; i<256; i++){ div255[i] = (double)i / 255.0; }

  use_opengl = rb_gv_get("$miyako_use_opengl");
}
