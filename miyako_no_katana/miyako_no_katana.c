/*
--
Miyako v1.5 Extend Library "Miyako no Katana"
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
#include "rubysdl.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mInput = Qnil;
static VALUE mMapEvent = Qnil;
static VALUE mLayout = Qnil;
static VALUE mDiagram = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cSurface = Qnil;
static VALUE cEvent2 = Qnil;
static VALUE cJoystick = Qnil;
static VALUE cWaitCounter = Qnil;
static VALUE cColor = Qnil;
static VALUE cFont = Qnil;
static VALUE cPixelFormat = Qnil;
static VALUE cBitmap = Qnil;
static VALUE cSprite = Qnil;
static VALUE cSpriteAnimation = Qnil;
static VALUE cPlane = Qnil;
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
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update;
static volatile ID id_update = Qnil;
static volatile ID id_kakko = Qnil;
static volatile int zero;
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

DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");
DEFINE_GET_STRUCT(SDL_PixelFormat, Get_PixelFormat, cPixelFormat, "SDL::PixelFormat");

#define MIYAKO_GETCOLOR(COLOR) \
	tmp = pixel & fmt->Rmask; \
	tmp >>= fmt->Rshift; \
	COLOR.r = (Uint32)(tmp << fmt->Rloss); \
	tmp = pixel & fmt->Gmask; \
	tmp >>= fmt->Gshift; \
	COLOR.g = (Uint32)(tmp << fmt->Gloss); \
	tmp = pixel & fmt->Bmask; \
	tmp >>= fmt->Bshift; \
	COLOR.b = (Uint32)(tmp << fmt->Bloss); \
  tmp = pixel & fmt->Amask; \
	tmp >>= fmt->Ashift; \
	COLOR.a = (Uint32)(tmp << fmt->Aloss);

#define MIYAKO_SETCOLOR(COLOR) \
  pixel = 0; \
	tmp = COLOR.r >> fmt->Rloss; \
	tmp <<= fmt->Rshift; \
	pixel |= tmp; \
	tmp = COLOR.g >> fmt->Gloss; \
	tmp <<= fmt->Gshift; \
	pixel |= tmp; \
	tmp = COLOR.b >> fmt->Bloss; \
	tmp <<= fmt->Bshift; \
	pixel |= tmp; \
  tmp = COLOR.a >> fmt->Aloss; \
	tmp <<= fmt->Ashift; \
	pixel |= tmp; \

/*
===画像をαチャネル付き画像へ転送する
本メソッドは、転送先ビットマップを破壊的に変更することに注意！
範囲は、srcの(ow,oh)の範囲で転送する。
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_x_:: 転送先の転送開始位置(x方向・単位：ピクセル)
_y_:: 転送先の転送開始位置(y方向・単位：ピクセル)
返却値:: なし
*/
static VALUE bitmap_miyako_blit_aa(VALUE self, VALUE vsrc, VALUE vdst, VALUE vx, VALUE vy)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;

  //SpriteUnit:
  //[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
  //[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
  //[9] -> :angle, [10] -> :xscale, [11] -> :yscale
  //[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
	int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
	int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
	int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
	int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
	int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
	int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
	int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
	int x =  NUM2INT(vx);
	int y =  NUM2INT(vy);
	int dlx = dox + x;
	int dly = doy + y;
	int dmx = dlx + sow;
	int dmy = dly + soh;
  int rx = dst->clip_rect.x + dst->clip_rect.w;
  int ry = dst->clip_rect.y + dst->clip_rect.h;
  
	if(dmx > dow) dmx = dow;
	if(dmy > doh) dmy = doh;

  if(dlx < dst->clip_rect.x)
  {
    sox += (dst->clip_rect.x - dlx);
    dlx = dst->clip_rect.x;
  }
  if(dly < dst->clip_rect.y)
  {
    soy += (dst->clip_rect.y - dly);
    dly = dst->clip_rect.y;
  }
  if(dmx > rx){ dmx = rx; }
  if(dly > ry){ dmy = ry; }
  
	SDL_LockSurface(src);
	SDL_LockSurface(dst);
  
	int px, py, sx, sy;
  for(sy = soy, py = dly; py < dmy; sy++, py++)
  {
    for(sx = sox, px = dlx; px < dmx; sx++, px++)
    {
      pixel = *(psrc + sy * src->w + sx);
      MIYAKO_GETCOLOR(scolor);
      pixel = *(pdst + py * dst->w + px);
      MIYAKO_GETCOLOR(dcolor);
      if(dcolor.a == 0){
        MIYAKO_SETCOLOR(scolor);
        *(pdst + py * dst->w + px) = pixel;
        continue;
      }
      if(scolor.a > 0)
      {
        dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
        if(dcolor.r > 255){ dcolor.r = 255; }
        dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
        if(dcolor.g > 255){ dcolor.g = 255; }
        dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
        if(dcolor.b > 255){ dcolor.b = 255; }
        dcolor.a = scolor.a;
        MIYAKO_SETCOLOR(dcolor);
        *(pdst + py * dst->w + px) = pixel;
      }
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画像をαチャネル付き画像へ転送する
引数で渡ってきた特定の色に対して、α値をゼロにする画像を生成する
本メソッドは、転送先ビットマップを破壊的に変更することに注意！
範囲は、srcの(w,h)の範囲で転送する。
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_color_key_:: 透明にしたい色(各要素がr,g,bに対応している整数の配列(0～255))
返却値:: なし
*/
static VALUE bitmap_miyako_colorkey_to_alphachannel(VALUE self, VALUE vsrc, VALUE vdst, VALUE vcolor_key)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = dst->format;
	MiyakoColor color_key, color;
	Uint32 tmp;
	Uint32 pixel;

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
    for(sx = 0; sx < w; sx++)
    {
      pixel = *(psrc + sy * w + sx);
      MIYAKO_GETCOLOR(color);
      if(color.r == color_key.r && color.g == color_key.g &&  color.b == color_key.b) pixel = 0;
      else pixel |= (0xff >> fmt->Aloss) << fmt->Ashift;
      *(pdst + sy * dst->w + sx) = pixel;
    }
  }

	SDL_UnlockSurface(src);
	SDL_UnlockSurface(dst);

  return Qnil;
}

/*
===画像のαチャネルの値を一定の割合で減少させて転送する
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_degree_:: 減少率。0.0<degree<1.0までの実数
*/
static VALUE bitmap_miyako_dec_alpha(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	double deg = NUM2DBL(degree);
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;

  if(src == dst){
    int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
    int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
    int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
    int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
    int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
    int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
    int dlx = dox + x;
    int dly = doy + y;
    int dmx = dlx + sow;
    int dmy = dly + soh;
    int rx = dst->clip_rect.x + dst->clip_rect.w;
    int ry = dst->clip_rect.y + dst->clip_rect.h;
  
    if(dmx > dow) dmx = dow;
    if(dmy > doh) dmy = doh;

    if(dlx < dst->clip_rect.x)
    {
      sox += (dst->clip_rect.x - dlx);
      dlx = dst->clip_rect.x;
    }
    if(dly < dst->clip_rect.y)
    {
      soy += (dst->clip_rect.y - dly);
      dly = dst->clip_rect.y;
    }
    if(dmx > rx){ dmx = rx; }
    if(dly > ry){ dmy = ry; }
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = soy, py = dly; py < dmy; sy++, py++)
    {
      for(sx = sox, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
        scolor.a = (Uint32)((double)scolor.a * deg);
        if(scolor.a < 0){ scolor.a = 0; }
        if(scolor.a > 255){ scolor.a = 255; }
        if(dcolor.a == 0){
          MIYAKO_SETCOLOR(scolor);
          *(pdst + py * dst->w + px) = pixel;
          continue;
        }
        if(scolor.a > 0)
        {
          dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
          if(dcolor.r > 255){ dcolor.r = 255; }
          dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
          if(dcolor.g > 255){ dcolor.g = 255; }
          dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
          if(dcolor.b > 255){ dcolor.b = 255; }
          dcolor.a = scolor.a;
          MIYAKO_SETCOLOR(dcolor);
          *(pdst + py * dst->w + px) = pixel;
        }
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));

    SDL_LockSurface(src);

    int x, y;
    for(y = oy; y < ob; y++)
    {
      for(x = ox; x < or; x++)
      {
        pixel = *(psrc + y * src->w + x);
        MIYAKO_GETCOLOR(scolor);
        scolor.a = (Uint32)((double)scolor.a * deg);
        if(scolor.a < 0){ scolor.a = 0; }
        if(scolor.a > 255){ scolor.a = 255; }
        MIYAKO_SETCOLOR(scolor);
        *(pdst + y * dst->w + x) = pixel;
      }
    }

    SDL_UnlockSurface(src);
  }

	return Qnil;
}

/*
===画像のRGB値を反転させる
αチャネルの値は変更しない
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
*/
static VALUE bitmap_miyako_inverse(VALUE self, VALUE vsrc, VALUE vdst)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;

  if(src == dst){
    int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
    int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
    int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
    int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
    int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
    int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
    int dlx = dox + x;
    int dly = doy + y;
    int dmx = dlx + sow;
    int dmy = dly + soh;
    int rx = dst->clip_rect.x + dst->clip_rect.w;
    int ry = dst->clip_rect.y + dst->clip_rect.h;
  
    if(dmx > dow) dmx = dow;
    if(dmy > doh) dmy = doh;

    if(dlx < dst->clip_rect.x)
    {
      sox += (dst->clip_rect.x - dlx);
      dlx = dst->clip_rect.x;
    }
    if(dly < dst->clip_rect.y)
    {
      soy += (dst->clip_rect.y - dly);
      dly = dst->clip_rect.y;
    }
    if(dmx > rx){ dmx = rx; }
    if(dly > ry){ dmy = ry; }
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = soy, py = dly; py < dmy; sy++, py++)
    {
      for(sx = sox, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
        scolor.r ^= 0xff;
        scolor.g ^= 0xff;
        scolor.b ^= 0xff;
        if(dcolor.a == 0){
          MIYAKO_SETCOLOR(scolor);
          *(pdst + py * dst->w + px) = pixel;
          continue;
        }
        if(scolor.a > 0)
        {
          dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
          if(dcolor.r > 255){ dcolor.r = 255; }
          dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
          if(dcolor.g > 255){ dcolor.g = 255; }
          dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
          if(dcolor.b > 255){ dcolor.b = 255; }
          dcolor.a = scolor.a;
          MIYAKO_SETCOLOR(dcolor);
          *(pdst + py * dst->w + px) = pixel;
        }
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));

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
        MIYAKO_SETCOLOR(scolor);
        *(pdst + y * dst->w + x) = pixel;
      }
    }

    SDL_UnlockSurface(src);
  }

	return Qnil;
}

/*
===2枚の画像の加算合成を行う
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
*/
static VALUE bitmap_miyako_additive_synthesis(VALUE self, VALUE vsrc, VALUE vdst)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;

  int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
  int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
  int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
  int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
  int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
  int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
  int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
  int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
  int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
  int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
  int dlx = dox + x;
  int dly = doy + y;
  int dmx = dlx + sow;
  int dmy = dly + soh;
  int rx = dst->clip_rect.x + dst->clip_rect.w;
  int ry = dst->clip_rect.y + dst->clip_rect.h;
  
  if(dmx > dow) dmx = dow;
  if(dmy > doh) dmy = doh;

  if(dlx < dst->clip_rect.x)
  {
    sox += (dst->clip_rect.x - dlx);
    dlx = dst->clip_rect.x;
  }
  if(dly < dst->clip_rect.y)
  {
    soy += (dst->clip_rect.y - dly);
    dly = dst->clip_rect.y;
  }
  if(dmx > rx){ dmx = rx; }
  if(dly > ry){ dmy = ry; }
  
  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int px, py, sx, sy;
  for(sy = soy, py = dly; py < dmy; sy++, py++)
  {
    for(sx = sox, px = dlx; px < dmx; sx++, px++)
    {
      pixel = *(psrc + sy * src->w + sx);
      MIYAKO_GETCOLOR(scolor);
			if(scolor.a > 0){
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
				dcolor.r += scolor.r;
				if(dcolor.r > 255){ dcolor.r = 255; }
				dcolor.g += scolor.g;
				if(dcolor.g > 255){ dcolor.g = 255; }
				dcolor.b += scolor.b;
				if(dcolor.b > 255){ dcolor.b = 255; }
				dcolor.a = (dcolor.a > scolor.a ? dcolor.a : scolor.a);
        MIYAKO_SETCOLOR(dcolor);
        *(pdst + py * dst->w + px) = pixel;
			}
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);
	
	return Qnil;
}

/*
===2枚の画像の減算合成を行う
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
*/
static VALUE bitmap_miyako_subtraction_synthesis(VALUE self, VALUE src, VALUE dst)
{
  bitmap_miyako_inverse(self, dst, dst);
  bitmap_miyako_additive_synthesis(self, src, dst);
  bitmap_miyako_inverse(self, dst, dst);
  return Qnil;
}

#define MIYAKO_RGB2HSV(RGBSTRUCT, HSVH, HSVS, HSVV) \
  r = (double)(RGBSTRUCT.r) / 255.0; \
  g = (double)(RGBSTRUCT.g) / 255.0; \
  b = (double)(RGBSTRUCT.b) / 255.0; \
  max = r; \
  min = max; \
  max = max < g ? g : max; \
  max = max < b ? b : max; \
  min = min > g ? g : min; \
  min = min > b ? b : min; \
  HSVV = max; \
  if(HSVV == 0.0){ HSVH = 0.0; HSVS = 0.0; return; } \
  HSVS = (max - min) / max; \
  if(HSVS == 0.0){ HSVH = 0.0; return; } \
  cr = (max - r)/(max - min); \
  cg = (max - g)/(max - min); \
  cb = (max - b)/(max - min); \
  if(max == r){ HSVH = cb - cg; } \
  if(max == g){ HSVH = 2.0 + cr - cb; } \
  if(max == b){ HSVH = 4.0 + cg - cr; } \
  HSVH *= 60.0; \
  if(HSVH < 0){ HSVH += 360.0; }

#define MIYAKO_HSV2RGB(HSVH, HSVS, HSVV, RGBSTRUCT) \
  if(HSVS == 0.0){ RGBSTRUCT.r = RGBSTRUCT.g = RGBSTRUCT.b = (Uint32)(HSVV * 255.0); return; } \
  i = HSVH / 60.0; \
  if(     i < 1.0){ i = 0.0; } \
  else if(i < 2.0){ i = 1.0; } \
  else if(i < 3.0){ i = 2.0; } \
  else if(i < 4.0){ i = 3.0; } \
  else if(i < 5.0){ i = 4.0; } \
  else if(i < 6.0){ i = 5.0; } \
  f = HSVH / 60.0 - i; \
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

/*
===画像の色相を変更する
範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
src == dst : 元の画像を変換した画像に置き換える
src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_hue(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double deg = NUM2DBL(degree);
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;
  double ph, ps, pv;
  double d_pi = 360.0;
  double r, g, b, max, min, cr, cg, cb;
  double i, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }
  
  if(src != dst){
    int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
    int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
    int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
    int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
    int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
    int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
    int dlx = dox + x;
    int dly = doy + y;
    int dmx = dlx + sow;
    int dmy = dly + soh;
    int rx = dst->clip_rect.x + dst->clip_rect.w;
    int ry = dst->clip_rect.y + dst->clip_rect.h;
    rx = rx < dow ? rx : dow;
    ry = ry < doh ? ry : doh;

    if(dlx < dst->clip_rect.x)
    {
      sox += (dst->clip_rect.x - dlx);
      dlx = dst->clip_rect.x;
    }
    if(dly < dst->clip_rect.y)
    {
      soy += (dst->clip_rect.y - dly);
      dly = dst->clip_rect.y;
    }
    if(dmx > rx){ dmx = rx; }
    if(dly > ry){ dmy = ry; }
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = soy, py = dly; py < dmy; sy++, py++)
    {
      for(sx = sox, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ph += deg;
        if(ph < 0.0){ ph += d_pi; }
        if(ph >= d_pi){ ph -= d_pi; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0){
          MIYAKO_SETCOLOR(scolor);
          *(pdst + py * dst->w + px) = pixel;
          continue;
        }
        if(scolor.a > 0)
        {
          dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
          if(dcolor.r > 255){ dcolor.r = 255; }
          dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
          if(dcolor.g > 255){ dcolor.g = 255; }
          dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
          if(dcolor.b > 255){ dcolor.b = 255; }
          dcolor.a = scolor.a;
          MIYAKO_SETCOLOR(dcolor);
          *(pdst + py * dst->w + px) = pixel;
        }
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));

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
        MIYAKO_HSV2RGB(ph, ps, pv, dcolor);
        MIYAKO_SETCOLOR(dcolor);
        *(pdst + y * dst->w + x) = pixel;
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
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
*/
static VALUE bitmap_miyako_saturation(VALUE self, VALUE vsrc, VALUE vdst, VALUE saturation)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double sat = NUM2DBL(saturation);
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;
  double ph, ps, pv;
  double r, g, b, max, min, cr, cg, cb;
  double i, f, m, n, k;

  if(src != dst){
    int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
    int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
    int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
    int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
    int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
    int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
    int dlx = dox + x;
    int dly = doy + y;
    int dmx = dlx + sow;
    int dmy = dly + soh;
    int rx = dst->clip_rect.x + dst->clip_rect.w;
    int ry = dst->clip_rect.y + dst->clip_rect.h;
  
    if(dmx > dow) dmx = dow;
    if(dmy > doh) dmy = doh;

    if(dlx < dst->clip_rect.x)
    {
      sox += (dst->clip_rect.x - dlx);
      dlx = dst->clip_rect.x;
    }
    if(dly < dst->clip_rect.y)
    {
      soy += (dst->clip_rect.y - dly);
      dly = dst->clip_rect.y;
    }
    if(dmx > rx){ dmx = rx; }
    if(dly > ry){ dmy = ry; }
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = soy, py = dly; py < dmy; sy++, py++)
    {
      for(sx = sox, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        ps += sat;
        if(ps < 0.0){ ps = 0.0; }
        if(ps > 1.0){ ps = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0){
          MIYAKO_SETCOLOR(scolor);
          *(pdst + py * dst->w + px) = pixel;
          continue;
        }
        if(scolor.a > 0)
        {
          dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
          if(dcolor.r > 255){ dcolor.r = 255; }
          dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
          if(dcolor.g > 255){ dcolor.g = 255; }
          dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
          if(dcolor.b > 255){ dcolor.b = 255; }
          dcolor.a = scolor.a;
          MIYAKO_SETCOLOR(dcolor);
          *(pdst + py * dst->w + px) = pixel;
        }
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));

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
        MIYAKO_HSV2RGB(ph, ps, pv, dcolor);
        MIYAKO_SETCOLOR(dcolor)
        *(pdst + y * dst->w + x) = pixel;
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
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_value(VALUE self, VALUE vsrc, VALUE vdst, VALUE value)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double val = NUM2DBL(value);
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;
  double ph, ps, pv;
  double r, g, b, max, min, cr, cg, cb;
  double i, f, m, n, k;

  if(src != dst){
    int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
    int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
    int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
    int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
    int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
    int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
    int dlx = dox + x;
    int dly = doy + y;
    int dmx = dlx + sow;
    int dmy = dly + soh;
    int rx = dst->clip_rect.x + dst->clip_rect.w;
    int ry = dst->clip_rect.y + dst->clip_rect.h;
  
    if(dmx > dow) dmx = dow;
    if(dmy > doh) dmy = doh;

    if(dlx < dst->clip_rect.x)
    {
      sox += (dst->clip_rect.x - dlx);
      dlx = dst->clip_rect.x;
    }
    if(dly < dst->clip_rect.y)
    {
      soy += (dst->clip_rect.y - dly);
      dly = dst->clip_rect.y;
    }
    if(dmx > rx){ dmx = rx; }
    if(dly > ry){ dmy = ry; }
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = soy, py = dly; py < dmy; sy++, py++)
    {
      for(sx = sox, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
        pixel = *(pdst + py * dst->w + px);
        MIYAKO_GETCOLOR(dcolor);
        MIYAKO_RGB2HSV(scolor, ph, ps, pv);
        pv += val;
        if(pv < 0.0){ pv = 0.0; }
        if(pv > 1.0){ pv = 1.0; }
        MIYAKO_HSV2RGB(ph, ps, pv, scolor);
        if(dcolor.a == 0){
          MIYAKO_SETCOLOR(scolor);
          *(pdst + py * dst->w + px) = pixel;
          continue;
        }
        if(scolor.a > 0)
        {
          dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
          if(dcolor.r > 255){ dcolor.r = 255; }
          dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
          if(dcolor.g > 255){ dcolor.g = 255; }
          dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
          if(dcolor.b > 255){ dcolor.b = 255; }
          dcolor.a = scolor.a;
          MIYAKO_SETCOLOR(dcolor);
          *(pdst + py * dst->w + px) = pixel;
        }
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));

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
        MIYAKO_HSV2RGB(ph, ps, pv, dcolor);
        MIYAKO_SETCOLOR(dcolor);
        *(pdst + y * dst->w + x) = pixel;
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
_src_:: 転送元ビットマップ(SpriteUnit構造体)
_dst_:: 転送先ビットマップ(SpriteUnit構造体)
_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_hsv(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree, VALUE saturation, VALUE value)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(vsrc)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(vdst)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	SDL_PixelFormat *fmt = src->format;
  double deg = NUM2DBL(degree);
  double sat = NUM2DBL(saturation);
  double val = NUM2DBL(value);
	MiyakoColor scolor, dcolor;
	Uint32 tmp;
	Uint32 pixel;
  double ph, ps, pv;
  double d_pi = 360.0;
  double r, g, b, max, min, cr, cg, cb;
  double i, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }
  
  if(src != dst){
    int sox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int soy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int sow = NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int soh = NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));
    int x   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 5));
    int y   = NUM2INT(*(RSTRUCT_PTR(vsrc) + 6));
    int dox = NUM2INT(*(RSTRUCT_PTR(vdst) + 1));
    int doy = NUM2INT(*(RSTRUCT_PTR(vdst) + 2));
    int dow = NUM2INT(*(RSTRUCT_PTR(vdst) + 3));
    int doh = NUM2INT(*(RSTRUCT_PTR(vdst) + 4));
    int dlx = dox + x;
    int dly = doy + y;
    int dmx = dlx + sow;
    int dmy = dly + soh;
    int rx = dst->clip_rect.x + dst->clip_rect.w;
    int ry = dst->clip_rect.y + dst->clip_rect.h;
  
    if(dmx > dow) dmx = dow;
    if(dmy > doh) dmy = doh;

    if(dlx < dst->clip_rect.x)
    {
      sox += (dst->clip_rect.x - dlx);
      dlx = dst->clip_rect.x;
    }
    if(dly < dst->clip_rect.y)
    {
      soy += (dst->clip_rect.y - dly);
      dly = dst->clip_rect.y;
    }
    if(dmx > rx){ dmx = rx; }
    if(dly > ry){ dmy = ry; }
  
    SDL_LockSurface(src);
    SDL_LockSurface(dst);
  
    int px, py, sx, sy;
    for(sy = soy, py = dly; py < dmy; sy++, py++)
    {
      for(sx = sox, px = dlx; px < dmx; sx++, px++)
      {
        pixel = *(psrc + sy * src->w + sx);
        MIYAKO_GETCOLOR(scolor);
        pixel = *(pdst + py * dst->w + px);
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
        if(dcolor.a == 0){
          MIYAKO_SETCOLOR(scolor);
          *(pdst + py * dst->w + px) = pixel;
          continue;
        }
        if(scolor.a > 0)
        {
          dcolor.r = ((scolor.r * (scolor.a + 1)) >> 8) + ((dcolor.r * (256 - scolor.a)) >> 8);
          if(dcolor.r > 255){ dcolor.r = 255; }
          dcolor.g = ((scolor.g * (scolor.a + 1)) >> 8) + ((dcolor.g * (256 - scolor.a)) >> 8);
          if(dcolor.g > 255){ dcolor.g = 255; }
          dcolor.b = ((scolor.b * (scolor.a + 1)) >> 8) + ((dcolor.b * (256 - scolor.a)) >> 8);
          if(dcolor.b > 255){ dcolor.b = 255; }
          dcolor.a = scolor.a;
          MIYAKO_SETCOLOR(dcolor);
          *(pdst + py * dst->w + px) = pixel;
        }
      }
    }

    SDL_UnlockSurface(src);
    SDL_UnlockSurface(dst);
  }
  else
  {
    int ox = NUM2INT(*(RSTRUCT_PTR(vsrc) + 1));
    int oy = NUM2INT(*(RSTRUCT_PTR(vsrc) + 2));
    int or = ox + NUM2INT(*(RSTRUCT_PTR(vsrc) + 3));
    int ob = oy + NUM2INT(*(RSTRUCT_PTR(vsrc) + 4));

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
        MIYAKO_HSV2RGB(ph, ps, pv, dcolor);
        MIYAKO_SETCOLOR(dcolor);
        *(pdst + y * dst->w + x) = pixel;
      }
    }

    SDL_UnlockSurface(src);
  }

  return Qnil;
}

static VALUE sprite_update(VALUE self)
{
  VALUE update = rb_iv_get(self, "@update");
  
  if(update != Qnil){ rb_funcall(update, rb_intern("call"), 1, self); }
  if(rb_block_given_p() == Qtrue){ rb_yield(self); }

  return self;
}

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
    rb_funcall(fps_sprite, rb_intern("render"), 0);
  }

  screen_update_tick(self);

  SDL_Flip(pdst);
  
  return Qnil;
}

static VALUE screen_render_screen(VALUE self, VALUE src)
{
  VALUE dst = rb_iv_get(mScreen, "@@unit");
	SDL_Surface *psrc = GetSurface(*(RSTRUCT_PTR(src)))->surface;
	SDL_Surface *pdst = GetSurface(*(RSTRUCT_PTR(dst)))->surface;
  SDL_Rect srect;
  SDL_Rect drect;

  //SpriteUnit:
  //[0] -> :bitmap, [1] -> :ox, [2] -> :oy, [3] -> :ow, [4] -> :oh
  //[5] -> :x, [6] -> :y, [7] -> :dx, [8] -> :dy
  //[9] -> :angle, [10] -> :xscale, [11] -> :yscale
  //[12] -> :px, [13] -> :py, [14] -> :qx, [15] -> :qy
	srect.x = NUM2INT(*(RSTRUCT_PTR(src) + 1));
	srect.y = NUM2INT(*(RSTRUCT_PTR(src) + 2));
	srect.w = NUM2INT(*(RSTRUCT_PTR(src) + 3));
	srect.h = NUM2INT(*(RSTRUCT_PTR(src) + 4));
	drect.x = NUM2INT(*(RSTRUCT_PTR(dst) + 1))
            + NUM2INT(*(RSTRUCT_PTR(src) + 5))
            + NUM2INT(*(RSTRUCT_PTR(src) + 7));
	drect.y = NUM2INT(*(RSTRUCT_PTR(dst) + 2))
	          + NUM2INT(*(RSTRUCT_PTR(src) + 6))
            + NUM2INT(*(RSTRUCT_PTR(src) + 8));

  SDL_BlitSurface(psrc, &srect, pdst, &drect);
  
  return Qtrue;
}

static VALUE counter_start(VALUE self)
{
  rb_iv_set(self, "@st", rb_funcall(mSDL, rb_intern("getTicks"), 0));
  rb_iv_set(self, "@counting", Qtrue);
  return self;
}

static VALUE counter_stop(VALUE self)
{
  rb_iv_set(self, "@st", INT2NUM(0));
  rb_iv_set(self, "@counting", Qfalse);
  return self;
}

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

static VALUE counter_waiting(VALUE self)
{
  return counter_wait_inner(self, Qtrue);
}

static VALUE counter_finish(VALUE self)
{
  return counter_wait_inner(self, Qfalse);
}

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

static VALUE maplayer_render(VALUE self)
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
      VALUE unit = rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0);
      *(RSTRUCT_PTR(unit) + 5) = INT2NUM(x * ow - mx);
      *(RSTRUCT_PTR(unit) + 6) = INT2NUM(y * oh - my);
      screen_render_screen(Qnil, unit);
    }
  }
  return Qnil;
}

static VALUE fixedmaplayer_render(VALUE self)
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
      VALUE unit = rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0);
      *(RSTRUCT_PTR(unit) + 5) = INT2NUM(pos_x + x * ow);
      *(RSTRUCT_PTR(unit) + 6) = INT2NUM(pos_y + y * oh);
      screen_render_screen(Qnil, unit);
    }
  }

  return Qnil;
}

static VALUE map_render(VALUE self)
{
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render(*(RARRAY_PTR(map_layers) + i));
  }
  
  return Qnil;
}

static VALUE fixedmap_render(VALUE self)
{
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render(*(RARRAY_PTR(map_layers) + i));
  }

  return Qnil;
}

static VALUE sa_update(VALUE self)
{
  VALUE exec = rb_iv_get(self, "@exec");
  if(exec == Qfalse){ return Qnil; }

  VALUE polist = rb_iv_get(self, "@pos_offset");
  VALUE dir = rb_iv_get(self, "@dir");
  
  VALUE now = rb_iv_get(self, "@now");
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE pos_off = *(RARRAY_PTR(polist) + NUM2INT(num));
  
  if(rb_to_id(dir) == rb_intern("h")){
    *(RSTRUCT_PTR(now) +  3) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  3)) - NUM2INT(pos_off));
  }
  else{
    *(RSTRUCT_PTR(now) +  2) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  2)) - NUM2INT(pos_off));
  }

  VALUE kind = rb_funcall(rb_iv_get(self, "@cnt"), rb_intern("kind_of?"), 1, rb_cInteger);
  if(kind == Qtrue){
    rb_funcall(self, rb_intern("update_frame"), 0);
  }
  else{
    rb_funcall(self, rb_intern("update_wait_counter"), 0);
  }
  
  now = rb_iv_get(self, "@now");
  num = rb_iv_get(self, "@pnum");

  VALUE slist = rb_iv_get(self, "@slist");
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE molist = rb_iv_get(self, "@move_offset");

  VALUE s = *(RARRAY_PTR(slist) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num))));
  VALUE move_off = *(RARRAY_PTR(molist) + NUM2INT(num));

  *(RSTRUCT_PTR(now) + 5) = INT2NUM(NUM2INT(rb_funcall(s, rb_intern("x"), 0)) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nZero)));
  *(RSTRUCT_PTR(now) + 6) = INT2NUM(NUM2INT(rb_funcall(s, rb_intern("y"), 0)) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nOne)));

  pos_off = *(RARRAY_PTR(polist) + NUM2INT(num));
  
  if(rb_to_id(dir) == rb_intern("h")){
    *(RSTRUCT_PTR(now) +  2) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  2)) + NUM2INT(pos_off));
  }
  else{
    *(RSTRUCT_PTR(now) +  1) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  1)) + NUM2INT(pos_off));
  }

  return Qnil;
}

static VALUE sa_update_frame(VALUE self)
{
  int cnt = NUM2INT(rb_iv_get(self, "@cnt"));
  if(cnt == 0){
    VALUE num = rb_iv_get(self, "@pnum");
    VALUE loop = rb_iv_get(self, "@loop");

    int pnum = NUM2INT(num);
    int pats = NUM2INT(rb_iv_get(self, "@pats"));
    pnum = (pnum + 1) % pats;

    rb_iv_set(self, "@pnum", INT2NUM(pnum));

    if(loop == Qfalse && pnum == 0){
      rb_funcall(self, rb_intern("stop"), 0);
      return Qnil;
    }

    rb_funcall(self, rb_intern("set_pat"), 0);
    VALUE plist = rb_iv_get(self, "@plist");
    VALUE waits = rb_iv_get(self, "@waits");
    rb_iv_set(self, "@cnt", *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum))));
  }
  else{
    cnt--;
    rb_iv_set(self, "@cnt", INT2NUM(cnt));
  }
  return Qnil;
}

static VALUE sa_update_wait_counter(VALUE self)
{
  VALUE cnt = rb_iv_get(self, "@cnt");
  VALUE waiting = rb_funcall(cnt, rb_intern("waiting?"), 0);
  if(waiting == Qfalse){
    VALUE num = rb_iv_get(self, "@pnum");
    VALUE loop = rb_iv_get(self, "@loop");

    int pnum = NUM2INT(num);
    int pats = NUM2INT(rb_iv_get(self, "@pats"));
    pnum = (pnum + 1) % pats;
    
    rb_iv_set(self, "@pnum", INT2NUM(pnum));
    
    if(loop == Qfalse && pnum == 0){
      rb_funcall(self, rb_intern("stop"), 0);
      return Qnil;
    }

    rb_funcall(self, rb_intern("set_pat"), 0);
    VALUE plist = rb_iv_get(self, "@plist");
    VALUE waits = rb_iv_get(self, "@waits");
    cnt = *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum)));
    rb_iv_set(self, "@cnt", cnt);
    rb_funcall(cnt, rb_intern("start"), 0);
  }
  return Qnil;
}

static VALUE sa_set_pat(VALUE self)
{
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE units = rb_iv_get(self, "@units");
  rb_iv_set(self, "@now", *(RARRAY_PTR(units) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num)))));
  return self;
}

static VALUE sa_render(VALUE self)
{
  screen_render_screen(Qnil, rb_iv_get(self, "@now"));
  return Qnil;
}

static VALUE sprite_render(VALUE self)
{
  screen_render_screen(Qnil, rb_iv_get(self, "@unit"));
  return Qnil;
}

static VALUE plane_render(VALUE self)
{
  VALUE ssize = rb_iv_get(mScreen, "@@size");
  int ssw = NUM2INT(*(RSTRUCT_PTR(ssize) + 0));
  int ssh = NUM2INT(*(RSTRUCT_PTR(ssize) + 1));
  VALUE pos = rb_iv_get(self, "@pos");
  VALUE size = rb_iv_get(self, "@size");
  VALUE sprite = rb_iv_get(self, "@sprite");
  int w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));
  VALUE unit = rb_funcall(sprite, rb_intern("to_unit"), 0);
  int sw = NUM2INT(*(RSTRUCT_PTR(unit) + 3));
  int sh = NUM2INT(*(RSTRUCT_PTR(unit) + 4));

  int x, y;
  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      int x2 = (x-1) * sw + pos_x;
      int y2 = (y-1) * sh + pos_y;
      if(x2 > 0 || y2 > 0
      || (x2+sw) <= ssw || (y2+sh) <= ssh){
        *(RSTRUCT_PTR(unit) + 5) = INT2NUM(x2);
        *(RSTRUCT_PTR(unit) + 6) = INT2NUM(y2);
        screen_render_screen(Qnil, unit);
      }
    }
  }
  
  return Qnil;
}

static VALUE collision_c_collision(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2))) - 1;
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3))) - 1;
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2))) - 1;
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3))) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_collision_with_move(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  VALUE dir1 = rb_funcall(c1, rb_intern("direction"), 0);
  VALUE dir2 = rb_funcall(c2, rb_intern("direction"), 0);
  VALUE amt1 = rb_funcall(c1, rb_intern("amount"), 0);
  VALUE amt2 = rb_funcall(c2, rb_intern("amount"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(dir1, id_kakko, 1, nZero))
    * NUM2INT(rb_funcall(amt1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(dir1, id_kakko, 1, nOne))
    * NUM2INT(rb_funcall(amt1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2))) - 1;
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3))) - 1;
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(dir2, id_kakko, 1, nZero))
    * NUM2INT(rb_funcall(amt2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(dir2, id_kakko, 1, nOne))
    * NUM2INT(rb_funcall(amt2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2))) - 1;
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3))) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_meet(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2)));
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3)));
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2)));
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3)));

  int v = 0;
  if(r1 == l2) v |= 1;
  if(b1 == t2) v |= 1;
  if(l1 == r2) v |= 1;
  if(t1 == b2) v |= 1;

  if(v == 1) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_into(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qfalse && f2 == Qtrue) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_out(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qtrue && f2 == Qfalse) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_cover(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2))) - 1;
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3))) - 1;
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2))) - 1;
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3))) - 1;

  int v = 0;
  if(l1 <= l2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && b2 <= b1) v |= 2;
  if(l2 <= l1 && r1 <= r2) v |= 4;
  if(t2 <= t1 && b1 <= b2) v |= 8;

  if(v == 3 || v == 12) return Qtrue;
  return Qfalse;
}

static VALUE collision_collision(VALUE self, VALUE c2)
{
  return collision_c_collision(cCollision, self, c2);
}

static VALUE collision_meet(VALUE self, VALUE c2)
{
  return collision_c_meet(cCollision, self, c2);
}

static VALUE collision_into(VALUE self, VALUE c2)
{
  return collision_c_into(cCollision, self, c2);
}

static VALUE collision_out(VALUE self, VALUE c2)
{
  return collision_c_out(cCollision, self, c2);
}

static VALUE collision_cover(VALUE self, VALUE c2)
{
  return collision_c_cover(cCollision, self, c2);
}

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
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cEvent2  = rb_define_class_under(mSDL, "Event2", rb_cObject);
  cJoystick  = rb_define_class_under(mSDL, "Joystick", rb_cObject);
  cWaitCounter  = rb_define_class_under(mMiyako, "WaitCounter", rb_cObject);
  cFont  = rb_define_class_under(mMiyako, "Font", rb_cObject);
  cColor  = rb_define_class_under(mMiyako, "Color", rb_cObject);
  cBitmap = rb_define_class_under(mMiyako, "Bitmap", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);
  cSpriteAnimation = rb_define_class_under(mMiyako, "SpriteAnimation", rb_cObject);
  cPlane = rb_define_class_under(mMiyako, "Plane", rb_cObject);
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

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_singleton_method(cBitmap, "blit_aa!", bitmap_miyako_blit_aa, 4);
  rb_define_singleton_method(cBitmap, "ck_to_ac!", bitmap_miyako_colorkey_to_alphachannel, 3);
  rb_define_singleton_method(cBitmap, "dec_alpha!", bitmap_miyako_dec_alpha, 3);
  rb_define_singleton_method(cBitmap, "inverse!", bitmap_miyako_inverse, 3);
  rb_define_singleton_method(cBitmap, "additive!", bitmap_miyako_additive_synthesis, 2);
  rb_define_singleton_method(cBitmap, "subtraction!", bitmap_miyako_subtraction_synthesis, 2);

  rb_define_singleton_method(cBitmap, "hue!", bitmap_miyako_hue, 3);
  rb_define_singleton_method(cBitmap, "saturation!", bitmap_miyako_saturation, 3);
  rb_define_singleton_method(cBitmap, "value!", bitmap_miyako_value, 3);
  rb_define_singleton_method(cBitmap, "hsv!", bitmap_miyako_hsv, 5);


  rb_define_module_function(mScreen, "update_tick", screen_update_tick, 0);
  rb_define_module_function(mScreen, "render", screen_render, 0);
  rb_define_module_function(mScreen, "render_screen", screen_render_screen, 1);

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

  rb_define_method(cSprite, "render", sprite_render, 0);

  rb_define_method(cPlane, "render", plane_render, 0);

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
}
