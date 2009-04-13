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

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cSurface = Qnil;
static VALUE sSpriteUnit = Qnil;

// from rubysdl_video.c
static GLOBAL_DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");

void _miyako_yield_unit_1(MiyakoBitmap *src)
{
  if(rb_block_given_p() == Qtrue){ src->unit = rb_obj_dup(src->unit); rb_yield(src->unit); }
}

void _miyako_yield_unit_2(MiyakoBitmap *src, MiyakoBitmap *dst)
{
  if(rb_block_given_p() == Qtrue)
  {
    src->unit = rb_obj_dup(src->unit);
    dst->unit = rb_obj_dup(dst->unit);
    rb_yield_values(2, src->unit, dst->unit);
  }
}

void _miyako_setup_unit(VALUE unit, SDL_Surface *screen, MiyakoBitmap *mb, VALUE x, VALUE y, int use_yield)
{
  mb->unit = unit;
  if(rb_obj_is_kind_of(mb->unit, sSpriteUnit) == Qfalse){
    mb->unit = rb_funcall(mb->unit, rb_intern("to_unit"), 0);
    if(mb->unit == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); }
  }

  if(use_yield) _miyako_yield_unit_1(mb);

  mb->rect.x = NUM2INT(*(RSTRUCT_PTR(mb->unit) + 1));
  mb->rect.y = NUM2INT(*(RSTRUCT_PTR(mb->unit) + 2));
  mb->rect.w = NUM2INT(*(RSTRUCT_PTR(mb->unit) + 3));
  mb->rect.h = NUM2INT(*(RSTRUCT_PTR(mb->unit) + 4));
  
	mb->surface = GetSurface(*(RSTRUCT_PTR(mb->unit)))->surface;
	mb->ptr = (Uint32 *)(mb->surface->pixels);
	mb->fmt = mb->surface->format;

  // adjust clip_rect
  if(mb->surface == screen)
  {
    SDL_Rect *crect = &(mb->surface->clip_rect);
    mb->rect.x += crect->x;
    if(mb->rect.x < 0){
      mb->rect.w += mb->rect.x;
      mb->rect.x = 0;
    }
    mb->rect.y += crect->y;
    if(mb->rect.y < 0){
      mb->rect.h += mb->rect.y;
      mb->rect.y = 0;
    }
    if(mb->rect.w > crect->w) mb->rect.w = crect->w;
    if(mb->rect.h > crect->h) mb->rect.h = crect->h;
    if(mb->rect.x + mb->rect.w > mb->surface->w)
      mb->rect.w = mb->surface->w - mb->rect.x;
    if(mb->rect.y + mb->rect.h > mb->surface->h)
      mb->rect.h = mb->surface->h - mb->rect.y;
  }
  
  mb->a255 = (mb->surface == screen) ? 0xff : 0;
  
  mb->x = (x == Qnil ? NUM2INT(*(RSTRUCT_PTR(mb->unit) + 5)) : NUM2INT(x));
  mb->y = (y == Qnil ? NUM2INT(*(RSTRUCT_PTR(mb->unit) + 6)) : NUM2INT(y));
}

void _miyako_setup_unit_2(VALUE unit_s, VALUE unit_d, 
                         SDL_Surface *screen,
                         MiyakoBitmap *mb_s, MiyakoBitmap *mb_d,
                         VALUE x, VALUE y, int use_yield)
{
  mb_s->unit = unit_s;
  if(rb_obj_is_kind_of(mb_s->unit, sSpriteUnit) == Qfalse){
    mb_s->unit = rb_funcall(mb_s->unit, rb_intern("to_unit"), 0);
    if(mb_s->unit == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); }
  }

  mb_d->unit = unit_d;
  if(rb_obj_is_kind_of(mb_d->unit, sSpriteUnit) == Qfalse){
    mb_d->unit = rb_funcall(mb_d->unit, rb_intern("to_unit"), 0);
    if(mb_d->unit == Qnil){ rb_raise(eMiyakoError, "Source instance has not SpriteUnit!"); }
  }

  if(use_yield) _miyako_yield_unit_2(mb_s, mb_d);

	mb_s->surface = GetSurface(*(RSTRUCT_PTR(mb_s->unit)))->surface;
	mb_s->ptr = (Uint32 *)(mb_s->surface->pixels);
	mb_s->fmt = mb_s->surface->format;

  mb_s->rect.x = NUM2INT(*(RSTRUCT_PTR(mb_s->unit) + 1));
  mb_s->rect.y = NUM2INT(*(RSTRUCT_PTR(mb_s->unit) + 2));
  mb_s->rect.w = NUM2INT(*(RSTRUCT_PTR(mb_s->unit) + 3));
  mb_s->rect.h = NUM2INT(*(RSTRUCT_PTR(mb_s->unit) + 4));

  // adjust clip_rect
  if(mb_s->surface == screen)
  {
    SDL_Rect *crect = &(mb_s->surface->clip_rect);
    mb_s->rect.x += crect->x;
    if(mb_s->rect.x < 0){
      mb_s->rect.w += mb_s->rect.x;
      mb_s->rect.x = 0;
    }
    mb_s->rect.y += crect->y;
    if(mb_s->rect.y < 0){
      mb_s->rect.h += mb_s->rect.y;
      mb_s->rect.y = 0;
    }
    if(mb_s->rect.w > crect->w) mb_s->rect.w = crect->w;
    if(mb_s->rect.h > crect->h) mb_s->rect.h = crect->h;
    if(mb_s->rect.x + mb_s->rect.w > mb_s->surface->w)
      mb_s->rect.w = mb_s->surface->w - mb_s->rect.x;
    if(mb_s->rect.y + mb_s->rect.h > mb_s->surface->h)
      mb_s->rect.h = mb_s->surface->h - mb_s->rect.y;
  }

  mb_s->a255 = (mb_s->surface == screen) ? 0xff : 0;
  
  mb_s->x = (x == Qnil ? NUM2INT(*(RSTRUCT_PTR(mb_s->unit) + 5)) : NUM2INT(x));
  mb_s->y = (y == Qnil ? NUM2INT(*(RSTRUCT_PTR(mb_s->unit) + 6)) : NUM2INT(y));

	mb_d->surface = GetSurface(*(RSTRUCT_PTR(mb_d->unit)))->surface;
	mb_d->ptr = (Uint32 *)(mb_d->surface->pixels);
	mb_d->fmt = mb_d->surface->format;

  mb_d->rect.x = NUM2INT(*(RSTRUCT_PTR(mb_d->unit) + 1));
  mb_d->rect.y = NUM2INT(*(RSTRUCT_PTR(mb_d->unit) + 2));
  mb_d->rect.w = NUM2INT(*(RSTRUCT_PTR(mb_d->unit) + 3));
  mb_d->rect.h = NUM2INT(*(RSTRUCT_PTR(mb_d->unit) + 4));

  // adjust clip_rect
  if(mb_d->surface == screen)
  {
    SDL_Rect *crect = &(mb_d->surface->clip_rect);
    mb_d->rect.x += crect->x;
    if(mb_d->rect.x < 0){
      mb_d->rect.w += mb_d->rect.x;
      mb_d->rect.x = 0;
    }
    mb_d->rect.y += crect->y;
    if(mb_d->rect.y < 0){
      mb_d->rect.h += mb_d->rect.y;
      mb_d->rect.y = 0;
    }
    if(mb_d->rect.w > crect->w) mb_d->rect.w = crect->w;
    if(mb_d->rect.h > crect->h) mb_d->rect.h = crect->h;
    if(mb_d->rect.x + mb_d->rect.w > mb_d->surface->w)
      mb_d->rect.w = mb_d->surface->w - mb_d->rect.x;
    if(mb_d->rect.y + mb_d->rect.h > mb_d->surface->h)
      mb_d->rect.h = mb_d->surface->h - mb_d->rect.y;
  }

  mb_d->a255 = (mb_d->surface == screen) ? 0xff : 0;
  
  mb_d->x = NUM2INT(*(RSTRUCT_PTR(mb_d->unit) + 5));
  mb_d->y = NUM2INT(*(RSTRUCT_PTR(mb_d->unit) + 6));
}

int _miyako_init_rect(MiyakoBitmap *src, MiyakoBitmap *dst, MiyakoSize *size)
{
  int w, h;

  if(src->x >= dst->rect.w || src->x <= -(dst->rect.w)) return 0;
  if(src->y >= dst->rect.h || src->y <= -(dst->rect.h)) return 0;

  if(src->x < 0){
    w = dst->rect.w + src->x;
    src->x = 0;
  }
  else{ w = dst->rect.w - src->x; }
  if(w <= 0) return 0;
  if(src->y < 0){
    h = dst->rect.h + src->y;
    src->y = 0;
  }
  else{ h = dst->rect.h - src->y; }
  if(h <= 0) return 0;

  size->w = (w > src->rect.w ? src->rect.w : w);
  size->h = (h > src->rect.h ? src->rect.h : h);
  
  return 1;
}

void Init_miyako_utility()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  sSpriteUnit = rb_define_class_under(mMiyako, "SpriteUnitBase", rb_cStruct);
}
