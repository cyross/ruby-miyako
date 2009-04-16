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
static VALUE cSprite = Qnil;
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
画像を回転させて貼り付ける
*/
static VALUE bitmap_miyako_rotate(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

	size.w = dst.rect.w;
	size.h = dst.rect.h;
  
	if(src.surface == dst.surface){ return Qnil; }
	
  if(dst.rect.w >= 32768 || dst.rect.h >= 32768){ return Qnil; }

  double rad = NUM2DBL(radian) * -1.0;
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

	int px = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+7)));
	int py = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+8)));
	int pr = src.rect.w + px;
	int pb = src.rect.h + py;
	int qx = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+7)));
	int qy = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+8)));
	int qr = dst.rect.w + qx;
	int qb = dst.rect.h + qy;

	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);

  int x, y;
  for(y = qy; y < qb; y++)
  {
    Uint32 *tp = dst.ptr + (dst.rect.y + y - qy) * dst.surface->w + dst.rect.x;
    for(x = qx; x < qr; x++)
    {
      int nx = (x*icos-y*isin) >> 12;
      if(nx < px || nx >= pr){ tp++; continue; }
      int ny = (x*isin+y*icos) >> 12;
      if(ny < py || ny >= pb){ tp++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*tp >> 16) & 0xff;
      dst.color.g = (*tp >>  8) & 0xff;
      dst.color.b = (*tp      ) & 0xff;
      dst.color.a = (*tp >> 24) & 0xff | dst.a255;
			Uint32 *psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      src.color.a = (*psrc >> 24) & 0xff | src.a255;
      if(src.color.a == 0){ tp++; continue; }
      if(dst.color.a == 0 || src.color.a == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      src.color.r = (*psrc >> 16) & 0xff;
      src.color.g = (*psrc >>  8) & 0xff;
      src.color.b = (*psrc      ) & 0xff;
			*tp = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
            ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
						((src.color.b * a1 + dst.color.b * a2) >> 8)       |
						0xff                                         << 24;
#else
      dst.color.r = (*tp & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*tp & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*tp & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*tp & dst.fmt->Amask) | dst.a255;
			Uint32 *psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      src.color.a = (*psrc & src.fmt->Amask) | src.a255;
      if(src.color.a == 0){ tp++; continue; }
      if(dst.color.a == 0 || src.color.a == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      src.color.r = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      *tp = (((src.color.r * a1 + dst.color.r * a2) >> 8)) << dst.fmt->Rshift |
            (((src.color.g * a1 + dst.color.g * a2) >> 8)) << dst.fmt->Gshift |
            (((src.color.b * a1 + dst.color.b * a2) >> 8)) << dst.fmt->Bshift |
            0xff;
#endif
      tp++;
    }
  }

  SDL_UnlockSurface(src.surface);
  SDL_UnlockSurface(dst.surface);
	
  return vdst;
}

/*
画像を拡大・縮小・鏡像(ミラー反転)させて貼り付ける
*/
static VALUE bitmap_miyako_scale(VALUE self, VALUE vsrc, VALUE vdst, VALUE xscale, VALUE yscale)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;
  
	if(src.surface == dst.surface){ return Qnil; }
	
  if(dst.rect.w >= 32768 || dst.rect.h >= 32768){ return Qnil; }

  double tscx = NUM2DBL(xscale);
  double tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0){ return Qnil; }

  int scx = (int)(4096.0 / tscx);
  int scy = (int)(4096.0 / tscy);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

	int px = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+7)));
	int py = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+8)));
	int pr = src.rect.w + px;
	int pb = src.rect.h + py;
	int qx = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+7)));
	int qy = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+8)));
	int qr = dst.rect.w + qx;
	int qb = dst.rect.h + qy;

	SDL_LockSurface(src.surface);
	SDL_LockSurface(dst.surface);

  int x, y;
  for(y = qy; y < qb; y++)
  {
    Uint32 *tp = dst.ptr + (dst.rect.y + y - qy) * dst.surface->w + dst.rect.x;
    for(x = qx; x < qr; x++)
    {
      int nx = (x*scx) >> 12 - off_x;
      if(nx < px || nx >= pr){ tp++; continue; }
      int ny = (y*scy) >> 12 - off_y;
      if(ny < py || ny >= pb){ tp++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst.color.r = (*tp >> 16) & 0xff;
      dst.color.g = (*tp >>  8) & 0xff;
      dst.color.b = (*tp      ) & 0xff;
      dst.color.a = (*tp >> 24) & 0xff | dst.a255;
			Uint32 *psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      src.color.a = (*psrc >> 24) & 0xff | src.a255;
      if(src.color.a == 0){ tp++; continue; }
      if(dst.color.a == 0 || src.color.a == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      src.color.r = (*psrc >> 16) & 0xff;
      src.color.g = (*psrc >>  8) & 0xff;
      src.color.b = (*psrc      ) & 0xff;
			*tp = ((src.color.r * a1 + dst.color.r * a2) >> 8) << 16 |
            ((src.color.g * a1 + dst.color.g * a2) >> 8) <<  8 |
            ((src.color.b * a1 + dst.color.b * a2) >> 8)       |
            0xff                                         << 24;
#else
      dst.color.r = (*tp & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dst.color.g = (*tp & dst.fmt->Gmask) >> dst.fmt->Gshift;
      dst.color.b = (*tp & dst.fmt->Bmask) >> dst.fmt->Bshift;
      dst.color.a = (*tp & dst.fmt->Amask) | dst.a255;
			Uint32 *psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      src.color.a = (*psrc & src.fmt->Amask) | src.a255;
      if(src.color.a == 0){ tp++; continue; }
      if(dst.color.a == 0 || src.color.a == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      int a1 = src.color.a + 1;
      int a2 = 256 - src.color.a;
      src.color.r = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      src.color.g = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      src.color.b = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      *tp = ((src.color.r * a1 + dst.color.r * a2) >> 8) << dst.fmt->Rshift |
            ((src.color.g * a1 + dst.color.g * a2) >> 8) << dst.fmt->Gshift |
            ((src.color.b * a1 + dst.color.b * a2) >> 8) << dst.fmt->Bshift |
            0xff;
#endif
      tp++;
    }
  }

  SDL_UnlockSurface(src.surface);
  SDL_UnlockSurface(dst.surface);
	
  return vdst;
}

/*
===回転・拡大・縮小・鏡像用インナーメソッド
*/
static void transform_inner(MiyakoBitmap *src, MiyakoBitmap *dst, VALUE radian, VALUE xscale, VALUE yscale)
{
  if(dst->rect.w >= 32768 || dst->rect.h >= 32768) return;

  MiyakoSize   size;

  if(_miyako_init_rect(src, dst, &size) == 0) return;
  
  double rad = NUM2DBL(radian) * -1.0;
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

  double tscx = NUM2DBL(xscale);
  double tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0) return;

  int scx = (int)(4096.0 / tscx);
  int scy = (int)(4096.0 / tscy);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

	int px = -(NUM2INT(*(RSTRUCT_PTR(src->unit)+7)));
	int py = -(NUM2INT(*(RSTRUCT_PTR(src->unit)+8)));
	int pr = src->rect.w + px;
	int pb = src->rect.h + py;
	int qx = -(NUM2INT(*(RSTRUCT_PTR(dst->unit)+7)));
	int qy = -(NUM2INT(*(RSTRUCT_PTR(dst->unit)+8)));
	int qr = dst->rect.w + qx;
	int qb = dst->rect.h + qy;

	SDL_LockSurface(src->surface);
	SDL_LockSurface(dst->surface);

  int x, y;
  for(y = qy; y < qb; y++)
  {
    Uint32 *tp = dst->ptr + (dst->rect.y + y - qy) * dst->surface->w + dst->rect.x;
    for(x = qx; x < qr; x++)
    {
      int nx = (((x*icos-y*isin) >> 12) * scx) >> 12 - off_x;
      if(nx < px || nx >= pr){ tp++; continue; }
      int ny = (((x*isin+y*icos) >> 12) * scy) >> 12 - off_y;
      if(ny < py || ny >= pb){ tp++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      dst->color.r = (*tp >> 16) & 0xff;
      dst->color.g = (*tp >>  8) & 0xff;
      dst->color.b = (*tp      ) & 0xff;
      dst->color.a = (*tp >> 24) & 0xff | dst->a255;
			Uint32 *psrc = src->ptr + (src->rect.x + ny - py) * src->surface->w + src->rect.x + nx - px;
      src->color.a = (*psrc >> 24) & 0xff | src->a255;
      if(src->color.a == 0){ tp++; continue; }
      if(dst->color.a == 0 || src->color.a == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      int a1 = src->color.a + 1;
      int a2 = 256 - src->color.a;
      src->color.r = (*psrc >> 16) & 0xff;
      src->color.g = (*psrc >>  8) & 0xff;
      src->color.b = (*psrc      ) & 0xff;
			*tp = ((src->color.r * a1 + dst->color.r * a2) >> 8) << 16 |
            ((src->color.g * a1 + dst->color.g * a2) >> 8) <<  8 |
            ((src->color.b * a1 + dst->color.b * a2) >> 8)       |
						0xff                                           << 24;
#else
      dst->color.r = (*tp & dst->fmt->Rmask) >> dst->fmt->Rshift;
      dst->color.g = (*tp & dst->fmt->Gmask) >> dst->fmt->Gshift;
      dst->color.b = (*tp & dst->fmt->Bmask) >> dst->fmt->Bshift;
      dst->color.a = (*tp & dst->fmt->Amask) | dst->a255;
			Uint32 *psrc = src->ptr + (src->rect.x + ny - py) * src->surface->w + src->rect.x + nx - px;
      src->color.a = (*psrc & src->fmt->Amask) | src->a255;
      if(src->color.a == 0){ tp++; continue; }
      if(dst->color.a == 0 || src->color.a == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      int a1 = src->color.a + 1;
      int a2 = 256 - src->color.a;
      src->color.r = (*psrc & src->fmt->Rmask) >> src->fmt->Rshift;
      src->color.g = (*psrc & src->fmt->Gmask) >> src->fmt->Gshift;
      src->color.b = (*psrc & src->fmt->Bmask) >> src->fmt->Bshift;
      *tp = ((src->color.r * a1 + dst->color.r * a2) >> 8) << dst->fmt->Rshift |
            ((src->color.g * a1 + dst->color.g * a2) >> 8) << dst->fmt->Gshift |
            ((src->color.b * a1 + dst->color.b * a2) >> 8) << dst->fmt->Bshift |
            0xff;
#endif
      tp++;
    }
  }

  SDL_UnlockSurface(src->surface);
  SDL_UnlockSurface(dst->surface);
}

/*
画像を変形(回転・拡大・縮小・鏡像)させて貼り付ける
*/
static VALUE bitmap_miyako_transform(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

	if(src.surface == dst.surface){ return Qnil; }
	
  transform_inner(&src, &dst, radian, xscale, yscale);
  return vdst;
}

/*
インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
*/
static VALUE sprite_render_transform(VALUE self, VALUE radian, VALUE xscale, VALUE yscale)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(self, mScreen, scr, &src, &dst, Qnil, Qnil, 1);

	if(src.surface == dst.surface){ return Qnil; }
	
  transform_inner(&src, &dst, radian, xscale, yscale);
  return self;
}

/*
インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
*/
static VALUE sprite_render_to_sprite_transform(VALUE self, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
	
	if(src.surface == dst.surface){ return Qnil; }
	
  transform_inner(&src, &dst, radian, xscale, yscale);
  return self;
}

void Init_miyako_transform()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cBitmap = rb_define_class_under(mMiyako, "Bitmap", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);

  rb_define_method(cSprite, "render_transform", sprite_render_transform, 3);
  rb_define_method(cSprite, "render_to_transform", sprite_render_to_sprite_transform, 4);
  
  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

	rb_define_singleton_method(cBitmap, "rotate", bitmap_miyako_rotate, 3);
	rb_define_singleton_method(cBitmap, "scale", bitmap_miyako_scale, 4);
	rb_define_singleton_method(cBitmap, "transform", bitmap_miyako_transform, 5);
}
