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
=miyako_no_katana
Authors:: Cyross Makoto
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
*/
static VALUE bitmap_miyako_rotate(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian)
{
  MiyakoBitmap src, dst;
  MiyakoSize   size;
  SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  double rad;
  long isin, icos;
  int x, y, a1, a2, nx, ny, px, py, pr, pb, qx, qy, qr, qb;
  Uint32 sr, sg, sb, sa, dr, dg, db, da, *tp, *psrc;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  size.w = dst.rect.w;
  size.h = dst.rect.h;

  if(src.surface == dst.surface){ return Qnil; }

  if(dst.rect.w >= 32768 || dst.rect.h >= 32768){ return Qnil; }

  rad = NUM2DBL(radian) * -1.0;
  isin = (long)(sin(rad)*4096.0);
  icos = (long)(cos(rad)*4096.0);

  px = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+7)));
  py = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+8)));
  pr = src.rect.w + px;
  pb = src.rect.h + py;
  qx = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+7)));
  qy = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+8)));
  qr = dst.rect.w + qx;
  qb = dst.rect.h + qy;

  SDL_LockSurface(src.surface);
  SDL_LockSurface(dst.surface);

  for(y = qy; y < qb; y++)
  {
    tp = dst.ptr + (dst.rect.y + y - qy) * dst.surface->w + dst.rect.x;
    for(x = qx; x < qr; x++)
    {
      nx = (x*icos-y*isin) >> 12;
      if(nx < px || nx >= pr){ tp++; continue; }
      ny = (x*isin+y*icos) >> 12;
      if(ny < py || ny >= pb){ tp++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      da = (*tp >> 24) | dst.a255;
      psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      sa = (*psrc >> 24) | src.a255;
      if(sa == 0){ tp++; continue; }
      if(da == 0 || sa == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      a1 = sa + 1;
      a2 = 256 - sa;
      dr = *tp & 0xff0000;
      dg = *tp & 0xff00;
      db = *tp & 0xff;
      sr = *psrc & 0xff0000;
      sg = *psrc & 0xff00;
      sb = *psrc & 0xff;
      *tp = ((sr * a1 + dr * a2) & 0xff000000 |
             (sg * a1 + dg * a2) & 0xff0000   |
             (sb * a1 + db * a2)) >> 8        |
            0xff000000;
#else
      dr = (*tp & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dg = (*tp & dst.fmt->Gmask) >> dst.fmt->Gshift;
      db = (*tp & dst.fmt->Bmask) >> dst.fmt->Bshift;
      da = (*tp & dst.fmt->Amask) | dst.a255;
      psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      sa = (*psrc & src.fmt->Amask) | src.a255;
      if(sa == 0){ tp++; continue; }
      if(da == 0 || sa == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      a1 = sa + 1;
      a2 = 256 - sa;
      sr = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      sg = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      sb = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      *tp = (((sr * a1 + dr * a2) >> 8)) << dst.fmt->Rshift |
            (((sg * a1 + dg * a2) >> 8)) << dst.fmt->Gshift |
            (((sb * a1 + db * a2) >> 8)) << dst.fmt->Bshift |
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
*/
static VALUE bitmap_miyako_scale(VALUE self, VALUE vsrc, VALUE vdst, VALUE xscale, VALUE yscale)
{
  Uint32 sr, sg, sb, sa;
  Uint32 dr, dg, db, da;
  MiyakoBitmap src, dst;
  MiyakoSize   size;
  SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  double tscx, tscy;
  int x, y, a1, a2, scx, scy, off_x, off_y, nx, ny, px, py, pr, pb, qx, qy, qr, qb;
  Uint32 *tp, *psrc;

  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  if(_miyako_init_rect(&src, &dst, &size) == 0) return Qnil;

  if(src.surface == dst.surface){ return Qnil; }

  if(dst.rect.w >= 32768 || dst.rect.h >= 32768){ return Qnil; }

  tscx = NUM2DBL(xscale);
  tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0){ return Qnil; }

  scx = (int)(4096.0 / tscx);
  scy = (int)(4096.0 / tscy);

  off_x = scx < 0 ? 1 : 0;
  off_y = scy < 0 ? 1 : 0;

  px = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+7)));
  py = -(NUM2INT(*(RSTRUCT_PTR(src.unit)+8)));
  pr = src.rect.w + px;
  pb = src.rect.h + py;
  qx = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+7)));
  qy = -(NUM2INT(*(RSTRUCT_PTR(dst.unit)+8)));
  qr = dst.rect.w + qx;
  qb = dst.rect.h + qy;

  SDL_LockSurface(src.surface);
  SDL_LockSurface(dst.surface);

  for(y = qy; y < qb; y++)
  {
    tp = dst.ptr + (dst.rect.y + y - qy) * dst.surface->w + dst.rect.x;
    for(x = qx; x < qr; x++)
    {
      nx = (x*scx) >> 12 - off_x;
      if(nx < px || nx >= pr){ tp++; continue; }
      ny = (y*scy) >> 12 - off_y;
      if(ny < py || ny >= pb){ tp++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      da = (*tp >> 24) | dst.a255;
      psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      sa = (*psrc >> 24) | src.a255;
      if(sa == 0){ tp++; continue; }
      if(da == 0 || sa == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      a1 = sa + 1;
      a2 = 256 - sa;
      dr = *tp & 0xff0000;
      dg = *tp & 0xff00;
      db = *tp & 0xff;
      sr = *psrc & 0xff0000;
      sg = *psrc & 0xff00;
      sb = *psrc & 0xff;
      *tp = ((sr * a1 + dr * a2) & 0xff000000 |
             (sg * a1 + dg * a2) & 0xff0000   |
             (sb * a1 + db * a2)) >> 8        |
            0xff000000;
#else
      dr = (*tp & dst.fmt->Rmask) >> dst.fmt->Rshift;
      dg = (*tp & dst.fmt->Gmask) >> dst.fmt->Gshift;
      db = (*tp & dst.fmt->Bmask) >> dst.fmt->Bshift;
      da = (*tp & dst.fmt->Amask) | dst.a255;
      psrc = src.ptr + (src.rect.x + ny - py) * src.surface->w + src.rect.x + nx - px;
      sa = (*psrc & src.fmt->Amask) | src.a255;
      if(sa == 0){ tp++; continue; }
      if(da == 0 || sa == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      a1 = sa + 1;
      a2 = 256 - sa;
      sr = (*psrc & src.fmt->Rmask) >> src.fmt->Rshift;
      sg = (*psrc & src.fmt->Gmask) >> src.fmt->Gshift;
      sb = (*psrc & src.fmt->Bmask) >> src.fmt->Bshift;
      *tp = ((sr * a1 + dr * a2) >> 8) << dst.fmt->Rshift |
            ((sg * a1 + dg * a2) >> 8) << dst.fmt->Gshift |
            ((sb * a1 + db * a2) >> 8) << dst.fmt->Bshift |
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
*/
static void transform_inner(MiyakoBitmap *src, MiyakoBitmap *dst, VALUE radian, VALUE xscale, VALUE yscale)
{
  MiyakoSize   size;
  double rad, tscx, tscy;
  long isin, icos;
  int x, y, a1, a2, scx, scy, off_x, off_y, nx, ny, px, py, pr, pb, qx, qy, qr, qb;
  Uint32 sr, sg, sb, sa, dr, dg, db, da, *tp, *psrc;

  if(dst->rect.w >= 32768 || dst->rect.h >= 32768) return;

  if(_miyako_init_rect(src, dst, &size) == 0) return;

  rad = NUM2DBL(radian) * -1.0;
  isin = (long)(sin(rad)*4096.0);
  icos = (long)(cos(rad)*4096.0);

  tscx = NUM2DBL(xscale);
  tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0) return;

  scx = (int)(4096.0 / tscx);
  scy = (int)(4096.0 / tscy);

  off_x = scx < 0 ? 1 : 0;
  off_y = scy < 0 ? 1 : 0;

  px = -(NUM2INT(*(RSTRUCT_PTR(src->unit)+7)));
  py = -(NUM2INT(*(RSTRUCT_PTR(src->unit)+8)));
  pr = src->rect.w + px;
  pb = src->rect.h + py;
  qx = -(NUM2INT(*(RSTRUCT_PTR(dst->unit)+7)));
  qy = -(NUM2INT(*(RSTRUCT_PTR(dst->unit)+8)));
  qr = dst->rect.w + qx;
  qb = dst->rect.h + qy;

  SDL_LockSurface(src->surface);
  SDL_LockSurface(dst->surface);

  for(y = qy; y < qb; y++)
  {
    tp = dst->ptr + (dst->rect.y + y - qy) * dst->surface->w + dst->rect.x;
    for(x = qx; x < qr; x++)
    {
      nx = (((x*icos-y*isin) >> 12) * scx) >> 12 - off_x;
      if(nx < px || nx >= pr){ tp++; continue; }
      ny = (((x*isin+y*icos) >> 12) * scy) >> 12 - off_y;
      if(ny < py || ny >= pb){ tp++; continue; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      da = (*tp >> 24) | dst->a255;
      psrc = src->ptr + (src->rect.x + ny - py) * src->surface->w + src->rect.x + nx - px;
      sa = (*psrc >> 24) | src->a255;
      if(sa == 0){ tp++; continue; }
      if(da == 0 || sa == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      a1 = sa + 1;
      a2 = 256 - sa;
      dr = *tp & 0xff0000;
      dg = *tp & 0xff00;
      db = *tp & 0xff;
      sr = *psrc & 0xff0000;
      sg = *psrc & 0xff00;
      sb = *psrc & 0xff;
      *tp = ((sr * a1 + dr * a2) & 0xff000000 |
             (sg * a1 + dg * a2) & 0xff0000   |
             (sb * a1 + db * a2)) >> 8        |
            0xff000000;
#else
      dr = (*tp & dst->fmt->Rmask) >> dst->fmt->Rshift;
      dg = (*tp & dst->fmt->Gmask) >> dst->fmt->Gshift;
      db = (*tp & dst->fmt->Bmask) >> dst->fmt->Bshift;
      da = (*tp & dst->fmt->Amask) | dst->a255;
      psrc = src->ptr + (src->rect.x + ny - py) * src->surface->w + src->rect.x + nx - px;
      sa = (*psrc & src->fmt->Amask) | src->a255;
      if(sa == 0){ tp++; continue; }
      if(da == 0 || sa == 255)
      {
        *tp = *psrc;
        tp++;
        continue;
      }
      a1 = sa + 1;
      a2 = 256 - sa;
      sr = (*psrc & src->fmt->Rmask) >> src->fmt->Rshift;
      sg = (*psrc & src->fmt->Gmask) >> src->fmt->Gshift;
      sb = (*psrc & src->fmt->Bmask) >> src->fmt->Bshift;
      *tp = ((sr * a1 + dr * a2) >> 8) << dst->fmt->Rshift |
            ((sg * a1 + dg * a2) >> 8) << dst->fmt->Gshift |
            ((sb * a1 + db * a2) >> 8) << dst->fmt->Bshift |
            0xff;
#endif
      tp++;
    }
  }

  SDL_UnlockSurface(src->surface);
  SDL_UnlockSurface(dst->surface);
}

/*
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
*/
static VALUE sprite_render_transform(VALUE self, VALUE radian, VALUE xscale, VALUE yscale)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;

  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit_2(self, mScreen, scr, &src, &dst, Qnil, Qnil, 1);

  if(src.surface == dst.surface){ return Qnil; }

  transform_inner(&src, &dst, radian, xscale, yscale);
  return self;
}

/*
*/
static VALUE sprite_render_to_sprite_transform(VALUE self, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;

  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

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
