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

  return vdst;
}

/*
画像の彩度を変更する
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

  return vdst;
}

/*
画像の明度を変更する
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

  return vdst;
}

/*
画像の色相・彩度・明度を変更する
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

  return vdst;
}

void Init_miyako_hsv()
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
  cTTFFont = rb_define_class_under(mSDL, "TTF", rb_cObject);
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
  cEncoding = rb_define_class("Encoding", rb_cObject);
  sPoint = rb_define_class_under(mMiyako, "PointStruct", rb_cStruct);
  sSize = rb_define_class_under(mMiyako, "SizeStruct", rb_cStruct);
  sRect = rb_define_class_under(mMiyako, "RectStruct", rb_cStruct);
  sSquare = rb_define_class_under(mMiyako, "SquareStruct", rb_cStruct);
  cIconv = rb_define_class("Iconv", rb_cObject);

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_singleton_method(cBitmap, "hue!", bitmap_miyako_hue, 3);
  rb_define_singleton_method(cBitmap, "saturation!", bitmap_miyako_saturation, 3);
  rb_define_singleton_method(cBitmap, "value!", bitmap_miyako_value, 3);
  rb_define_singleton_method(cBitmap, "hsv!", bitmap_miyako_hsv, 5);
  
  int i;
  for(i=0; i<256; i++){ div255[i] = (double)i / 255.0; }
}
