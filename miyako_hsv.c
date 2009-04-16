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
 
#define MIYAKO_RGB2HSV(RGBSTRUCT, HSVH, HSVS, HSVV) \
  Uint32 imax = RGBSTRUCT.r; \
  Uint32 imin = imax; \
  imax = imax < RGBSTRUCT.g ? RGBSTRUCT.g : imax; \
  imax = imax < RGBSTRUCT.b ? RGBSTRUCT.b : imax; \
  imin = imin > RGBSTRUCT.g ? RGBSTRUCT.g : imin; \
  imin = imin > RGBSTRUCT.b ? RGBSTRUCT.b : imin; \
  if(imax == 0){ HSVV = 0.0; HSVH = 0.0; HSVS = 0.0; } \
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
 
static volatile double div255[256];

/*
画像の色相を変更する
*/
static VALUE bitmap_miyako_hue(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	int x, y;

  double deg = NUM2DBL(degree);
  double d_pi = 360.0;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);
  
	for(y = 0; y < size.h; y++)
	{
		Uint32 *psrc = src.ptr + (src.rect.y         + y) * src.rect.w + src.rect.x;
		Uint32 *pdst = dst.ptr + (dst.rect.y + src.y + y) * dst.rect.w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*psrc >> 16) & 0xff;
      src.color.g = (*psrc >>  8) & 0xff;
      src.color.b = (*psrc      ) & 0xff;
      src.color.a = (*psrc >> 24) & 0xff | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = (src.color.r) << 16 |
							  (src.color.g) <<  8 |
							  (src.color.b)       |
							  (src.color.a) << 24;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
							((src.color.b * a1 + dst.color.b * a2) >> 8)       |
							0xff                                         << 24;
#else
      src.color.r = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*psrc & src.fmt->Amask) | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = src.color.r << dst.fmt->Rshift |
							  src.color.g << dst.fmt->Gshift |
							  src.color.b << dst.fmt->Bshift |
							  src.color.a;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
							((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
							0xff;
#endif
      psrc++;
			pdst++;
		}
	}

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の彩度を変更する
*/
static VALUE bitmap_miyako_saturation(VALUE self, VALUE vsrc, VALUE vdst, VALUE saturation)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

	int x, y;

  double sat = NUM2DBL(saturation);
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);

	for(y = 0; y < size.h; y++)
	{
		Uint32 *psrc = src.ptr + (src.rect.y + y) * src.rect.w + src.rect.x;
		Uint32 *pdst = dst.ptr + (dst.rect.y + src.y  + y) * dst.rect.w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*psrc >> 16) & 0xff;
      src.color.g = (*psrc >>  8) & 0xff;
      src.color.b = (*psrc      ) & 0xff;
      src.color.a = (*psrc >> 24) & 0xff | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = (src.color.r) << 16 |
							  (src.color.g) <<  8 |
							  (src.color.b)       |
							  (src.color.a) << 24;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
							((src.color.b * a1 + dst.color.b * a2) >> 8)       |
							0xff                                         << 24;
			psrc++;
			pdst++;
#else
      src.color.r = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*psrc & src.fmt->Amask) | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = src.color.r << dst.fmt->Rshift |
							  src.color.g << dst.fmt->Gshift |
							  src.color.b << dst.fmt->Bshift |
							  src.color.a;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
							((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
							0xff;
			psrc++;
			pdst++;
#endif
    }
	}

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の明度を変更する
*/
static VALUE bitmap_miyako_value(VALUE self, VALUE vsrc, VALUE vdst, VALUE value)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  double val = NUM2DBL(value);
  
	int x, y;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
  SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);

	for(y = 0; y < size.h; y++)
	{
		Uint32 *psrc = src.ptr + (src.rect.y + y) * src.rect.w + src.rect.x;
		Uint32 *pdst = dst.ptr + (dst.rect.y + src.y  + y) * dst.rect.w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*psrc >> 16) & 0xff;
      src.color.g = (*psrc >>  8) & 0xff;
      src.color.b = (*psrc      ) & 0xff;
      src.color.a = (*psrc >> 24) & 0xff | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = (src.color.r) << 16 |
							  (src.color.g) <<  8 |
							  (src.color.b)       |
							  (src.color.a) << 24;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
							((src.color.b * a1 + dst.color.b * a2) >> 8)       |
							0xff                                         << 24;
#else
      src.color.r = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*psrc & src.fmt->Amask) | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = src.color.r << dst.fmt->Rshift |
							  src.color.g << dst.fmt->Gshift |
							  src.color.b << dst.fmt->Bshift |
							  src.color.a;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
							((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
							0xff;
#endif
      psrc++;
			pdst++;
		}
	}

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
画像の色相・彩度・明度を変更する
*/
static VALUE bitmap_miyako_hsv(VALUE self, VALUE vsrc, VALUE vdst, VALUE degree, VALUE saturation, VALUE value)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  
	int x, y;

  double deg = NUM2DBL(degree);
  double sat = NUM2DBL(saturation);
  double val = NUM2DBL(value);
  double d_pi = 360.0;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);

	for(y = 0; y < size.h; y++)
	{
		Uint32 *psrc = src.ptr + (src.rect.y + y) * src.rect.w + src.rect.x;
		Uint32 *pdst = dst.ptr + (dst.rect.y + src.y  + y) * dst.rect.w + dst.rect.x + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      src.color.r = (*psrc >> 16) & 0xff;
      src.color.g = (*psrc >>  8) & 0xff;
      src.color.b = (*psrc      ) & 0xff;
      src.color.a = (*psrc >> 24) & 0xff | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = (src.color.r) << 16 |
							  (src.color.g) <<  8 |
							  (src.color.b)       |
							  (src.color.a) << 24;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
							((src.color.b * a1 + dst.color.b * a2) >> 8)       |
							0xff                                         << 24;
			psrc++;
			pdst++;
#else
      src.color.r = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      src.color.a = (*psrc & src.fmt->Amask) | src.a255;
			if(src.color.a == 0){ psrc++; pdst++; continue; }
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			MIYAKO_RGB2HSV(src.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, src.color);
			if(dst.color.a == 0 || src.color.a == 255){
				*pdst = src.color.r << dst.fmt->Rshift |
							  src.color.g << dst.fmt->Gshift |
							  src.color.b << dst.fmt->Bshift |
							  src.color.a;
				psrc++;
				pdst++;
				continue;
			}
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*pdst = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
						  ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
							((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
							0xff;
			psrc++;
			pdst++;
#endif
    }
	}

	SDL_UnlockSurface(src.surface);
	SDL_UnlockSurface(dst.surface);

	return vdst;
}

/*
画像の色相を変更する
*/
static VALUE bitmap_miyako_hue_self(VALUE self, VALUE vdst, VALUE degree)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

	int x, y;
  double deg = NUM2DBL(degree);
  double d_pi = 360.0;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }
  
	SDL_LockSurface(dst.surface);

	for(y = 0; y < dst.rect.h; y++)
	{
		Uint32 *pdst = dst.ptr + (dst.rect.y + y) * dst.rect.w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
			*pdst = (dst.color.r) << 16 |
						  (dst.color.g) <<  8 |
						  (dst.color.b)       |
						  (dst.color.a) << 24;
#else
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
			*pdst = dst.color.r << dst.fmt->Rshift |
							dst.color.g << dst.fmt->Gshift |
							dst.color.b << dst.fmt->Bshift |
							dst.color.a;
#endif
      pdst++;
		}
	}

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の彩度を変更する
*/
static VALUE bitmap_miyako_saturation_self(VALUE self, VALUE vdst, VALUE saturation)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  double sat = NUM2DBL(saturation);
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

	SDL_LockSurface(dst.surface);

	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
		Uint32 *pdst = dst.ptr + (dst.rect.y + y) * dst.rect.w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
      *pdst = (dst.color.r) << 16 |
              (dst.color.g) <<  8 |
							(dst.color.b)       |
							(dst.color.a) << 24;
#else
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
			*pdst = dst.color.r << dst.fmt->Rshift |
							dst.color.g << dst.fmt->Gshift |
							dst.color.b << dst.fmt->Bshift |
							dst.color.a;
#endif
      pdst++;
		}
	}

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の明度を変更する
*/
static VALUE bitmap_miyako_value_self(VALUE self, VALUE vdst, VALUE value)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  double val = NUM2DBL(value);
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

	SDL_LockSurface(dst.surface);

	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
		Uint32 *pdst = dst.ptr + (dst.rect.y + y) * dst.rect.w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
      *pdst = (dst.color.r) << 16 |
              (dst.color.g) <<  8 |
							(dst.color.b)       |
							(dst.color.a) << 24;
#else
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
			*pdst = dst.color.r << dst.fmt->Rshift |
							dst.color.g << dst.fmt->Gshift |
							dst.color.b << dst.fmt->Bshift |
							dst.color.a;
#endif
      pdst++;
		}
	}

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

/*
画像の色相・彩度・明度を変更する
*/
static VALUE bitmap_miyako_hsv_self(VALUE self, VALUE vdst, VALUE degree, VALUE saturation, VALUE value)
{
  MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  double deg = NUM2DBL(degree);
  double sat = NUM2DBL(saturation);
  double val = NUM2DBL(value);
  double d_pi = 360.0;
  double ph = 0.0, ps = 0.0, pv = 0.0;
  double r = 0.0, g = 0.0, b = 0.0;
  double i = 0.0, f, m, n, k;

  if(deg <= -360.0 || deg >= 360.0){ return Qnil; }

	SDL_LockSurface(dst.surface);

	int x, y;
	for(y = 0; y < dst.rect.h; y++)
	{
		Uint32 *pdst = dst.ptr + (dst.rect.y + y) * dst.rect.w + dst.rect.x;
		for(x = 0; x < dst.rect.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*pdst >> 16) & 0xff;
      dst.color.g = (*pdst >>  8) & 0xff;
      dst.color.b = (*pdst      ) & 0xff;
      dst.color.a = (*pdst >> 24) & 0xff | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
			*pdst = (dst.color.r) << 16 |
						  (dst.color.g) <<  8 |
						  (dst.color.b)       |
						  (dst.color.a) << 24;
#else
      dst.color.r = (*pdst & dst.fmt->Rmask) >> dst.fmt->Rshift);
      dst.color.g = (*pdst & dst.fmt->Gmask) >> dst.fmt->Gshift);
      dst.color.b = (*pdst & dst.fmt->Bmask) >> dst.fmt->Bshift);
      dst.color.a = (*pdst & dst.fmt->Amask) | dst.a255;
			if(dst.color.a == 0){ pdst++; continue; }
			MIYAKO_RGB2HSV(dst.color, ph, ps, pv);
			ph += deg;
			if(ph < 0.0){ ph += d_pi; }
			if(ph >= d_pi){ ph -= d_pi; }
			ps += sat;
			if(ps < 0.0){ ps = 0.0; }
			if(ps > 1.0){ ps = 1.0; }
			pv += val;
			if(pv < 0.0){ pv = 0.0; }
			if(pv > 1.0){ pv = 1.0; }
			MIYAKO_HSV2RGB(ph, ps, pv, dst.color);
			*pdst = dst.color.r << dst.fmt->Rshift |
							dst.color.g << dst.fmt->Gshift |
							dst.color.b << dst.fmt->Bshift |
							dst.color.a;
#endif
      pdst++;
		}
	}

	SDL_UnlockSurface(dst.surface);

  return vdst;
}

void Init_miyako_hsv()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
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

  rb_define_singleton_method(cBitmap, "hue", bitmap_miyako_hue, 3);
  rb_define_singleton_method(cBitmap, "saturation", bitmap_miyako_saturation, 3);
  rb_define_singleton_method(cBitmap, "value", bitmap_miyako_value, 3);
  rb_define_singleton_method(cBitmap, "hsv", bitmap_miyako_hsv, 5);
  rb_define_singleton_method(cBitmap, "hue!", bitmap_miyako_hue_self, 2);
  rb_define_singleton_method(cBitmap, "saturation!", bitmap_miyako_saturation_self, 2);
  rb_define_singleton_method(cBitmap, "value!", bitmap_miyako_value_self, 2);
  rb_define_singleton_method(cBitmap, "hsv!", bitmap_miyako_hsv_self, 4);
  
  int i;
  for(i=0; i<256; i++){ div255[i] = (double)i / 255.0; }
}
