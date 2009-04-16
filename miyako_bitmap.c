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
#include "defines.h"
#include "extern.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cSurface = Qnil;
static VALUE cBitmap = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

// from rubysdl_video.c
static GLOBAL_DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");

/*
画像をαチャネル付き画像へ転送する
*/
static VALUE bitmap_miyako_blit_aa(VALUE self, VALUE vsrc, VALUE vdst, VALUE vx, VALUE vy)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, vx, vy, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
      if(dst.color.a == 0 || src.color.a == 255){
        *ppdst = *ppsrc;
        ppsrc++;
        ppdst++;
        continue;
      }
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      *ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
               ((src.color.b * a1 + dst.color.b * a2) >> 8)       |
               0xff                                         << 24;
#else
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
      if(dst.color.a == 0 || src.color.a == 255){
        *ppdst = *ppsrc;
        ppsrc++;
        ppdst++;
        continue;
      }
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      *ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
               ((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
               0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
２つの画像のandを取る
*/
static VALUE bitmap_miyako_blit_and(VALUE self, VALUE vsrc, VALUE vdst)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
#else
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
#endif
      if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      *ppdst = (*ppdst | (dst.a255 << 24)) & (*ppsrc | (src.a255 << 24));
#else
      *ppdst = (*ppdst | dst.a255) & (*ppsrc | src.a255);
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}


/*
２つの画像のorを取り、別の画像へ転送する
*/
static VALUE bitmap_miyako_blit_or(VALUE self, VALUE vsrc, VALUE vdst)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
#else
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
#endif
      if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      *ppdst = (*ppdst | (dst.a255 << 24)) | (*ppsrc | (src.a255 << 24));
#else
      *ppdst = (*ppdst | dst.a255) \ (*ppsrc | src.a255);
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}


/*
２つの画像のxorを取り、別の画像へ転送する
*/
static VALUE bitmap_miyako_blit_xor(VALUE self, VALUE vsrc, VALUE vdst)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
#else
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
#endif
      if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      *ppdst = (*ppdst | (dst.a255 << 24)) ^ (*ppsrc | (src.a255 << 24));
#else
      *ppdst = (*ppdst | dst.a255) ^ (*ppsrc | src.a255);
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像をαチャネル付き画像へ転送する
*/
static VALUE bitmap_miyako_colorkey_to_alphachannel(VALUE self, VALUE vsrc, VALUE vdst, VALUE vcolor_key)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	MiyakoColor color_key;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  
  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;

	color_key.r = NUM2INT(*(RARRAY_PTR(vcolor_key) + 0));
	color_key.g = NUM2INT(*(RARRAY_PTR(vcolor_key) + 1));
	color_key.b = NUM2INT(*(RARRAY_PTR(vcolor_key) + 2));

	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      if(src.color.r == color_key.r && src.color.g == color_key.g && src.color.b == color_key.b) *ppdst = 0;
      else *ppdst = *ppsrc | (0xff << 24);
#else
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      if(src.color.r == color_key.r && src.color.g == color_key.g && src.color.b == color_key.b) *ppdst = 0;
      else *ppdst = *ppsrc | 0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像のαチャネルを255に拡張する
*/
static VALUE bitmap_miyako_reset_alphachannel(VALUE self, VALUE vsrc, VALUE vdst)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      *ppdst = *ppsrc | (0xff << 24);
#else
      *ppdst = *ppsrc | 0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像をαチャネル付き画像へ転送する
*/
static VALUE bitmap_miyako_colorkey_to_alphachannel_self(VALUE self, VALUE vdst, VALUE vcolor_key)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	MiyakoColor color_key;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);
  
	color_key.r = NUM2INT(*(RARRAY_PTR(vcolor_key) + 0));
	color_key.g = NUM2INT(*(RARRAY_PTR(vcolor_key) + 1));
	color_key.b = NUM2INT(*(RARRAY_PTR(vcolor_key) + 2));

	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
    Uint32 *ppdst = dst.ptr + (dst.rect.y + y) * dst.surface->w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      if(dst.color.r == color_key.r && dst.color.g == color_key.g && dst.color.b == color_key.b) *ppdst = 0;
      else *ppdst = *ppdst | (0xff << 24);
#else
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      if(dst.color.r == color_key.r && dst.color.g == color_key.g && dst.color.b == color_key.b) *ppdst = 0;
      else *ppdst = *ppdst | 0xff;
#endif
      ppdst++;
    }
  }

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像のαチャネルを255に拡張する
*/
static VALUE bitmap_miyako_reset_alphachannel_self(VALUE self, VALUE vdst)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
    Uint32 *ppdst = dst.ptr + (dst.rect.y + y) * dst.surface->w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      *ppdst = *ppdst | 0xff << 24;
#else
      *ppdst = *ppdst | 0xff;
#endif
      ppdst++;
    }
  }

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像のαチャネルの値を一定の割合で変化させて転送する
*/
static VALUE bitmap_miyako_dec_alpha(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 da = (Uint32)(255.0 * deg);

	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      src.color.a -= da;
      if(src.color.a > 0x80000000){ src.color.a = 0; }
      if(src.color.a > 255){ src.color.a = 255; }
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      if(dst.color.a == 0 || src.color.a == 255){
        *ppdst = src.color.r << 16 |
                 src.color.g <<  8 |
                 src.color.b       |
                 src.color.a << 24;
        ppsrc++;
        ppdst++;
        continue;
      }
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      *ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
               ((src.color.b * a1 + dst.color.b * a2) >> 8)       |
               (0xff)                                       << 24;
#else
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      src.color.a -= da;
      if(src.color.a > 0x80000000){ src.color.a = 0; }
      if(src.color.a > 255){ src.color.a = 255; }
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = src.color.r << dst.fmt->Rshift |
                 src.color.g << dst.fmt->Gshift |
                 src.color.b << dst.fmt->Bshift |
                 src.color.a;
				ppsrc++;
				ppdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
               ((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
               0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の色を一定の割合で黒に近づける(ブラックアウト)
*/
static VALUE bitmap_miyako_black_out(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 d = (Uint32)(255.0 * deg);

	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      src.color.r -= d;
      if(src.color.r > 0x80000000){ src.color.r = 0; }
      src.color.g -= d;
      if(src.color.g > 0x80000000){ src.color.g = 0; }
      src.color.b -= d;
      if(src.color.b > 0x80000000){ src.color.b = 0; }
      if(src.color.a != 0)
      {
        src.color.a -= d;
        if(src.color.a > 0x80000000){ src.color.a = 0; }
      }
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = src.color.r << 16 |
                 src.color.g <<  8 |
                 src.color.b       |
                 src.color.a << 24;
				ppsrc++;
				ppdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
      *ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
               ((src.color.b * a1 + dst.color.b * a2) >> 8)       |
               (0xff)                                       << 24;
#else
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      src.color.r -= d;
      if(src.color.r > 0x80000000){ src.color.r = 0; }
      src.color.g -= d;
      if(src.color.g > 0x80000000){ src.color.g = 0; }
      src.color.b -= d;
      if(src.color.b > 0x80000000){ src.color.b = 0; }
      if(src.color.a != 0)
      {
        src.color.a -= d;
        if(src.color.a > 0x80000000){ src.color.a = 0; }
      }
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = src.color.r << dst.fmt->Rshift |
                 src.color.g << dst.fmt->Gshift |
                 src.color.b << dst.fmt->Bshift |
                 src.color.a;
				ppsrc++;
				ppdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
               ((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
               0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
画像の色を一定の割合で白に近づける(ホワイトアウト)
*/
static VALUE bitmap_miyako_white_out(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
  double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 d = (Uint32)(255.0 * deg);

	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      src.color.r += d;
      if(src.color.r > 255){ src.color.r = 255; }
      src.color.g += d;
      if(src.color.g > 255){ src.color.g = 255; }
      src.color.b += d;
      if(src.color.b > 255){ src.color.b = 255; }
      if(src.color.a != 0)
      {
        src.color.a += d;
        if(src.color.a > 255){ src.color.a = 255; }
      }
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = src.color.r << 16 |
                 src.color.g << 8 |
                 src.color.b |
                 src.color.a << 24;
				ppsrc++;
				ppdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
      *ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
               ((src.color.b * a1 + dst.color.b * a2) >> 8)       |
               (0xff)                                       << 24;
#else
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      src.color.r += d;
      if(src.color.r > 255){ src.color.r = 255; }
      src.color.g += d;
      if(src.color.g > 255){ src.color.g = 255; }
      src.color.b += d;
      if(src.color.b > 255){ src.color.b = 255; }
      if(src.color.a != 0)
      {
        src.color.a += d;
        if(src.color.a > 255){ src.color.a = 255; }
      }
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = src.color.r << dst.fmt->Rshift |
                 src.color.g << dst.fmt->Gshift |
                 src.color.b << dst.fmt->Bshift |
                 src.color.a;
				ppsrc++;
				ppdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*ppdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
               ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
               ((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
               0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
画像のRGB値を反転させる
*/
static VALUE bitmap_miyako_inverse(VALUE self, VALUE vsrc, VALUE vdst)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
			if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = (src.color.r ^ 0xff) << 16 |
                 (src.color.g ^ 0xff) <<  8 |
                 (src.color.b ^ 0xff)       |
                 (src.color.a       ) << 24;
				ppsrc++;
				ppdst++;
				continue;
			}
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
      *ppdst = (((src.color.r ^ 0xff) * a1 + dst.color.r * a2) >> 8) << 16 |
               (((src.color.g ^ 0xff) * a1 + dst.color.g * a2) >> 8) <<  8 |
               (((src.color.b ^ 0xff) * a1 + dst.color.b * a2) >> 8)       |
               (0xff                                               ) << 24;
#else
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = (src.color.r ^ 0xff) << dst.fmt->Rshift |
                 (src.color.g ^ 0xff) << dst.fmt->Gshift |
                 (src.color.b ^ 0xff) << dst.fmt->Bshift |
                 src.color.a;
				ppsrc++;
				ppdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*ppdst = (((src.color.r ^ 0xff) * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
               (((src.color.g ^ 0xff) * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
               (((src.color.b ^ 0xff) * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
               0xff;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
画像のαチャネルの値を一定の割合で変化させて転送する
*/
static VALUE bitmap_miyako_dec_alpha_self(VALUE self, VALUE vdst, VALUE degree)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

	double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 da = (Uint32)(255.0 * deg);

	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
    Uint32 *ppdst = dst.ptr + (dst.rect.y + y) * dst.surface->w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      dst.color.a -= da;
      if(dst.color.a > 0x80000000){ dst.color.a = 0; }
      if(dst.color.a > 255){ dst.color.a = 255; }
      *ppdst = dst.color.r << 16 |
               dst.color.g <<  8 |
               dst.color.b       |
               dst.color.a << 24;
#else
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
      dst.color.a -= da;
      if(dst.color.a > 0x80000000){ dst.color.a = 0; }
      if(dst.color.a > 255){ dst.color.a = 255; }
      *ppdst = dst.color.r << dst.fmt->Rshift |
               dst.color.g << dst.fmt->Gshift |
               dst.color.b << dst.fmt->Bshift |
               dst.color.a;
#endif
      ppdst++;
    }
  }

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の色を一定の割合で黒に近づける(ブラックアウト)
*/
static VALUE bitmap_miyako_black_out_self(VALUE self, VALUE vdst, VALUE degree)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

	double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 d = (Uint32)(255.0 * deg);

	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
    Uint32 *ppdst = dst.ptr + (dst.rect.y + y) * dst.surface->w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      dst.color.r -= d;
      if(dst.color.r > 0x80000000){ dst.color.r = 0; }
      dst.color.g -= d;
      if(dst.color.g > 0x80000000){ dst.color.g = 0; }
      dst.color.b -= d;
      if(dst.color.b > 0x80000000){ dst.color.b = 0; }
      if(dst.color.a != 0)
      {
        dst.color.a -= d;
        if(dst.color.a > 0x80000000){ dst.color.a = 0; }
      }
      *ppdst = dst.color.r << 16 |
               dst.color.g <<  8 |
               dst.color.b       |
               dst.color.a << 24;
#else
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
      dst.color.r -= d;
      if(dst.color.r > 0x80000000){ dst.color.r = 0; }
      dst.color.g -= d;
      if(dst.color.g > 0x80000000){ dst.color.g = 0; }
      dst.color.b -= d;
      if(dst.color.b > 0x80000000){ dst.color.b = 0; }
      if(dst.color.a != 0)
      {
        dst.color.a -= d;
        if(dst.color.a > 0x80000000){ dst.color.a = 0; }
      }
      *ppdst = dst.color.r << dst.fmt->Rshift |
               dst.color.g << dst.fmt->Gshift |
               dst.color.b << dst.fmt->Bshift |
               dst.color.a;
#endif
      ppdst++;
    }
  }

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の色を一定の割合で白に近づける(ホワイトアウト)
*/
static VALUE bitmap_miyako_white_out_self(VALUE self, VALUE vdst, VALUE degree)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

	double deg = NUM2DBL(degree);
  if(deg < -1.0 || deg > 1.0){
    char buf[256];
    sprintf(buf, "Illegal degree! : %.15g", deg);
    rb_raise(eMiyakoError, buf);
  }
  deg = 1.0 - deg;
  Uint32 d = (Uint32)(255.0 * deg);

	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
    Uint32 *ppdst = dst.ptr + (dst.rect.y + y) * dst.surface->w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      dst.color.r += d;
      if(dst.color.r > 255){ dst.color.r = 255; }
      dst.color.g += d;
      if(dst.color.g > 255){ dst.color.g = 255; }
      dst.color.b += d;
      if(dst.color.b > 255){ dst.color.b = 255; }
      if(dst.color.a != 0)
      {
        dst.color.a += d;
        if(dst.color.a > 255){ dst.color.a = 255; }
      }
      *ppdst = dst.color.r << 16 |
               dst.color.g <<  8 |
               dst.color.b       |
               dst.color.a << 24;
#else
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
      dst.color.r += d;
      if(dst.color.r > 255){ dst.color.r = 255; }
      dst.color.g += d;
      if(dst.color.g > 255){ dst.color.g = 255; }
      dst.color.b += d;
      if(dst.color.b > 255){ dst.color.b = 255; }
      if(dst.color.a != 0)
      {
        dst.color.a += d;
        if(dst.color.a > 255){ dst.color.a = 255; }
      }
      *ppdst = dst.color.r << dst.fmt->Rshift |
               dst.color.g << dst.fmt->Gshift |
               dst.color.b << dst.fmt->Bshift |
               dst.color.a;
#endif
      ppdst++;
    }
  }

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像のRGB値を反転させる
*/
static VALUE bitmap_miyako_inverse_self(VALUE self, VALUE vdst)
{
  MiyakoBitmap dst;
  SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
    Uint32 *ppdst = dst.ptr + (dst.rect.y + y) * dst.surface->w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      *ppdst = (dst.color.r ^ 0xff) << 16 |
               (dst.color.g ^ 0xff) <<  8 |
               (dst.color.b ^ 0xff)       |
                dst.color.a         << 24;
#else
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
      *ppdst = (dst.color.r ^ 0xff) << dst.fmt->Rshift |
               (dst.color.g ^ 0xff) << dst.fmt->Gshift |
               (dst.color.b ^ 0xff) << dst.fmt->Bshift |
               dst.color.a;
#endif
      ppdst++;
    }
  }

	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
2枚の画像の加算合成を行う
*/
static VALUE bitmap_miyako_additive_synthesis(VALUE self, VALUE vsrc, VALUE vdst)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *ppsrc = src.ptr + (src.rect.y         + y) * src.surface->w + src.rect.x;
    Uint32 *ppdst = dst.ptr + (dst.rect.y + src.y + y) * dst.surface->w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*ppsrc >> 16) & 0xff;
      src.color.g = (*ppsrc >>  8) & 0xff;
      src.color.b = (*ppsrc      ) & 0xff;
      src.color.a = (*ppsrc >> 24) & 0xff | src.a255;
      dst.color.r = (*ppdst >> 16) & 0xff;
      dst.color.g = (*ppdst >>  8) & 0xff;
      dst.color.b = (*ppdst      ) & 0xff;
      dst.color.a = (*ppdst >> 24) & 0xff | dst.a255;
      dst.color.r += src.color.r;
			if(dst.color.r > 255){ dst.color.r = 255; }
			dst.color.g += src.color.g;
			if(dst.color.g > 255){ dst.color.g = 255; }
			dst.color.b += src.color.b;
			if(dst.color.b > 255){ dst.color.b = 255; }
			dst.color.a = (dst.color.a > src.color.a ? dst.color.a : src.color.a);
      *ppdst = dst.color.r << 16 |
               dst.color.g <<  8 |
               dst.color.b       |
               dst.color.a << 24;
#else
      src.color.r = (*ppsrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*ppsrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*ppsrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*ppsrc & src.fmt->Amask) | src.a255;
      dst.color.r = (*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*ppdst & dst.fmt->Amask) | dst.a255;
      dst.color.r += src.color.r;
			if(dst.color.r > 255){ dst.color.r = 255; }
			dst.color.g += src.color.g;
			if(dst.color.g > 255){ dst.color.g = 255; }
			dst.color.b += src.color.b;
			if(dst.color.b > 255){ dst.color.b = 255; }
			dst.color.a = (dst.color.a > src.color.a ? dst.color.a : src.color.a);
      *ppdst = dst.color.r << dst.fmt->Rshift |
               dst.color.g << dst.fmt->Gshift |
               dst.color.b << dst.fmt->Bshift |
               dst.color.a;
#endif
      ppsrc++;
      ppdst++;
    }
  }

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
2枚の画像の減算合成を行う
*/
static VALUE bitmap_miyako_subtraction_synthesis(VALUE self, VALUE src, VALUE dst)
{
  bitmap_miyako_inverse(self, dst, dst);
  bitmap_miyako_additive_synthesis(self, src, dst);
  bitmap_miyako_inverse(self, dst, dst);
  return dst;
}

void Init_miyako_bitmap()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cBitmap = rb_define_class_under(mMiyako, "Bitmap", rb_cObject);

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);
  
  rb_define_singleton_method(cBitmap, "blit_aa", bitmap_miyako_blit_aa, 4);
  rb_define_singleton_method(cBitmap, "blit_and", bitmap_miyako_blit_and, 2);
  rb_define_singleton_method(cBitmap, "blit_or", bitmap_miyako_blit_or, 2);
  rb_define_singleton_method(cBitmap, "blit_xor", bitmap_miyako_blit_xor, 2);
  rb_define_singleton_method(cBitmap, "ck_to_ac", bitmap_miyako_colorkey_to_alphachannel, 3);
  rb_define_singleton_method(cBitmap, "reset_ac", bitmap_miyako_reset_alphachannel, 2);
  rb_define_singleton_method(cBitmap, "normal_to_ac", bitmap_miyako_reset_alphachannel, 2);
  rb_define_singleton_method(cBitmap, "screen_to_ac", bitmap_miyako_reset_alphachannel, 2);
  rb_define_singleton_method(cBitmap, "ck_to_ac!", bitmap_miyako_colorkey_to_alphachannel_self, 2);
  rb_define_singleton_method(cBitmap, "reset_ac!", bitmap_miyako_reset_alphachannel_self, 1);
  rb_define_singleton_method(cBitmap, "normal_to_ac!", bitmap_miyako_reset_alphachannel_self, 1);
  rb_define_singleton_method(cBitmap, "dec_alpha", bitmap_miyako_dec_alpha, 3);
  rb_define_singleton_method(cBitmap, "black_out", bitmap_miyako_black_out, 3);
  rb_define_singleton_method(cBitmap, "white_out", bitmap_miyako_white_out, 3);
  rb_define_singleton_method(cBitmap, "inverse", bitmap_miyako_inverse, 2);
  rb_define_singleton_method(cBitmap, "dec_alpha!", bitmap_miyako_dec_alpha_self, 2);
  rb_define_singleton_method(cBitmap, "black_out!", bitmap_miyako_black_out_self, 2);
  rb_define_singleton_method(cBitmap, "white_out!", bitmap_miyako_white_out_self, 2);
  rb_define_singleton_method(cBitmap, "inverse!", bitmap_miyako_inverse_self, 1);
  rb_define_singleton_method(cBitmap, "additive", bitmap_miyako_additive_synthesis, 2);
  rb_define_singleton_method(cBitmap, "subtraction", bitmap_miyako_subtraction_synthesis, 2);
}
