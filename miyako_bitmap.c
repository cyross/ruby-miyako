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

/*
画像をαチャネル付き画像へ転送する
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

  return vdst;
}

/*
２つの画像のandを取り、別の画像へ転送する
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

  MIYAKO_INIT_RECT3;

	SDL_LockSurface(src1);
	SDL_LockSurface(src2);
	SDL_LockSurface(dst);
  
	int px, py, sy1, sy2;
	for(py = dly, sy1 = s1rect.y + y2, sy2 = s2rect.y + y1; py < dmy; py++, sy1++, sy2++)
	{
    Uint32 *ppsrc1 = psrc1 + sy1 * src1->w + s1rect.x + x2;
    Uint32 *ppsrc2 = psrc2 + sy2 * src2->w + s2rect.x + x1;
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

  return vdst;
}


/*
２つの画像のorを取り、別の画像へ転送する
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

  MIYAKO_INIT_RECT3;

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;
  
	SDL_LockSurface(src1);
	SDL_LockSurface(src2);
	SDL_LockSurface(dst);
  
	int px, py, sy1, sy2;
	for(py = dly, sy1 = s1rect.y + y2, sy2 = s2rect.y + y1; py < dmy; py++, sy1++, sy2++)
	{
    Uint32 *ppsrc1 = psrc1 + sy1 * src1->w + s1rect.x + x2;
    Uint32 *ppsrc2 = psrc2 + sy2 * src2->w + s2rect.x + x1;
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

  return vdst;
}


/*
２つの画像のxorを取り、別の画像へ転送する
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

  MIYAKO_INIT_RECT3;

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

	SDL_LockSurface(src1);
	SDL_LockSurface(src2);
	SDL_LockSurface(dst);
  
	int px, py, sy1, sy2;
	for(py = dly, sy1 = s1rect.y + y2, sy2 = s2rect.y + y1; py < dmy; py++, sy1++, sy2++)
	{
    Uint32 *ppsrc1 = psrc1 + sy1 * src1->w + s1rect.x + x2;
    Uint32 *ppsrc2 = psrc2 + sy2 * src2->w + s2rect.x + x1;
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

  return vdst;
}

/*
画像をαチャネル付き画像へ転送する
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

  return vdst;
}

/*
画像のαチャネルを255に拡張する
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

  return vdst;
}

/*
画像をαチャネル付き画像へ変換する
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

  return vdst;
}

/*
画面(αチャネル無し32bit画像)をαチャネル付き画像へ転送する
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

  return vdst;
}

/*
画像のαチャネルの値を一定の割合で変化させて転送する
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

	return vdst;
}

/*
画像の色を一定の割合で黒に近づける(ブラックアウト)
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

	return vdst;
}

/*
画像の色を一定の割合で白に近づける(ホワイトアウト)
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

	return vdst;
}

/*
画像のRGB値を反転させる
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

	return vdst;
}

/*
2枚の画像の加算合成を行う
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
  rb_define_singleton_method(cBitmap, "inverse!", bitmap_miyako_inverse, 2);
  rb_define_singleton_method(cBitmap, "additive!", bitmap_miyako_additive_synthesis, 2);
  rb_define_singleton_method(cBitmap, "subtraction!", bitmap_miyako_subtraction_synthesis, 2);
  rb_define_singleton_method(cBitmap, "subtraction!", bitmap_miyako_subtraction_synthesis, 2);
}
