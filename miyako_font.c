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
static VALUE cTTFFont = Qnil;
static VALUE cFont = Qnil;
static VALUE cEncoding = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

static volatile ID id_encode = Qnil;
static volatile ID id_utf8 = Qnil;

typedef struct {
  TTF_Font* font;
} TTFont;

// from rubysdl_video.c
static GLOBAL_DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");
// from rubysdl_ttf.c
static GLOBAL_DEFINE_GET_STRUCT(TTFont, Get_TTFont, cTTFFont, "SDL::TT::Font");

static VALUE font_draw_text(VALUE self, VALUE vdst, VALUE str, VALUE vx, VALUE vy)
{
  int font_size, shadow_margin_x, shadow_margin_y, hspace, x, y, a1, a2, margin_x, margin_y;
  TTF_Font *font;
  VALUE *p_font_color, *p_shadow_color;
  VALUE use_shadow, shadow_margin, chr;
  SDL_Color fore_color, shadow_color;
  SDL_Surface *scr, *ssrc, *ssrc2;
  SDL_Rect drect;
  MiyakoBitmap src, dst;
  char *sptr;
  Uint32 sr, sg, sb, sa;
  Uint32 dr, dg, db, da;
  Uint32 *psrc2, *psrc, *ppsrc2, *ppdst;
  int i, n, clen;
  const char *ptr;
  int len;
  rb_encoding *enc;

  rb_secure(4);
  StringValue(str);

  str = rb_funcall(str, id_encode, 1, rb_const_get(cEncoding, id_utf8));

  font = Get_TTFont(rb_iv_get(self, "@font"))->font;

  p_font_color = RARRAY_PTR(rb_iv_get(self, "@color"));

  fore_color.r = NUM2INT(*(p_font_color+0));
  fore_color.g = NUM2INT(*(p_font_color+1));
  fore_color.b = NUM2INT(*(p_font_color+2));
  fore_color.unused = 0;

  p_shadow_color = RARRAY_PTR(rb_iv_get(self, "@shadow_color"));
  shadow_color.r = NUM2INT(*(p_shadow_color+0));
  shadow_color.g = NUM2INT(*(p_shadow_color+1));
  shadow_color.b = NUM2INT(*(p_shadow_color+2));
  shadow_color.unused = 0;

  font_size = NUM2INT(rb_iv_get(self, "@size"));
  use_shadow = rb_iv_get(self, "@use_shadow");
  shadow_margin = rb_iv_get(self, "@shadow_margin");
  shadow_margin_x = (use_shadow == Qtrue ? NUM2INT(*(RARRAY_PTR(shadow_margin)+0)) : 0);
  shadow_margin_y = (use_shadow == Qtrue ? NUM2INT(*(RARRAY_PTR(shadow_margin)+1)) : 0);
  hspace = NUM2INT(rb_iv_get(self, "@hspace"));

  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  _miyako_setup_unit(vdst, scr, &dst, vx, vy, 0);

  sptr = RSTRING_PTR(str);

  src.x = dst.x;
  src.y = dst.y;

  if(use_shadow == Qtrue)
  {
    ssrc2 = TTF_RenderUTF8_Blended(font, sptr, shadow_color);

    if(ssrc2 == NULL) return INT2NUM(src.x);
    psrc2 = (Uint32 *)(ssrc2->pixels);

    src.x += shadow_margin_x;
    src.y += shadow_margin_y;

    if(dst.surface == scr)
    {
      drect.x = src.x;
      drect.y = src.y;
      SDL_BlitSurface(ssrc2, NULL, dst.surface, &(drect));
    }
    else
    {
      MiyakoSize size2;
      size2.w = dst.rect.w - (src.x < 0 ? 0 : src.x);
      if(size2.w <= 0)
      {
        SDL_FreeSurface(ssrc2);
        return INT2NUM(dst.x);
      }
      if(size2.w > ssrc2->w){ size2.w = ssrc2->w; }

      margin_x = 0;
      if(src.x < 0)
      {
        int tmp_w = ssrc2->w + src.x;
        if(tmp_w < size2.w) size2.w += src.x;
        if(size2.w <= 0)
        {
          SDL_FreeSurface(ssrc2);
          return INT2NUM(dst.x);
        }
        margin_x = -src.x;
        src.x = 0;
      }

      size2.h = dst.rect.h - (src.y < 0 ? 0 : src.y);
      if(size2.h <= 0)
      {
        SDL_FreeSurface(ssrc2);
        return INT2NUM(dst.x);
      }
      if(size2.h > ssrc2->h){ size2.h = ssrc2->h; }

      margin_y = 0;
      if(src.y < 0)
      {
        int tmp_h = ssrc2->h + src.y;
        if(tmp_h < size2.h) size2.h += src.y;
        if(size2.h <= 0)
        {
          SDL_FreeSurface(ssrc2);
          return INT2NUM(dst.x);
        }
        margin_y = -src.y;
        src.y = 0;
      }

      SDL_LockSurface(ssrc2);
      SDL_LockSurface(dst.surface);

      for(y = 0; y < size2.h; y++)
      {
        ppsrc2 = psrc2 + (y+margin_y) * ssrc2->w + margin_x;
        ppdst = dst.ptr + (src.y + y) * dst.surface->w + src.x;
        for(x = 0; x < size2.w; x++)
        {
  #if SDL_BYTEORDER == SDL_LIL_ENDIAN
          da = (*ppdst >> 24) | dst.a255;
          sa = *ppsrc2 >> 24;
          if(sa == 0){ ppsrc2++; ppdst++; continue; }
          if(da == 0 || sa == 255){
            *ppdst = *ppsrc2;
            ppsrc2++;
            ppdst++;
            continue;
          }
  #if 0
          dr = (Uint32)((*ppdst >> 16)) & 0xff;
          dg = (Uint32)((*ppdst >> 8)) & 0xff;
          db = (Uint32)((*ppdst)) & 0xff;
          sr = (Uint32)((*ppsrc2 >> 16)) & 0xff;
          sg = (Uint32)((*ppsrc2 >> 8)) & 0xff;
          sb = (Uint32)((*ppsrc2)) & 0xff;
          a1 = sa + 1;
          a2 = 256 - sa;
          *ppdst = (((sr * a1 + dr * a2) >> 8)) << 16 |
                   (((sg * a1 + dg * a2) >> 8)) << 8 |
                   (((sb * a1 + db * a2) >> 8)) |
                   0xff000000;
  #else
          dr = *ppdst & 0xff0000;
          dg = *ppdst & 0xff00;
          db = *ppdst & 0xff;
          sr = *ppsrc2 & 0xff0000;
          sg = *ppsrc2 & 0xff00;
          sb = *ppsrc2 & 0xff;
          a1 = sa + 1;
          a2 = 256 - sa;
          *ppdst = ((sr * a1 + dr * a2) & 0xff000000 |
                    (sg * a1 + dg * a2) & 0xff0000   |
                    (sb * a1 + db * a2)) >> 8        |
                   0xff000000;
  #endif
  #else
          da = (Uint32)(((*ppdst & dst.fmt->Amask) | dst.a255;
          sa = (Uint32)(((*ppsrc2 & ssrc2->format->Amask)));
          if(sa == 0){ ppsrc2++; ppdst++; continue; }
          if(da == 0 || sa == 255){
            *ppdst = *ppsrc2;
            ppsrc2++;
            ppdst++;
            continue;
          }
          dr = (Uint32)(((*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift));
          dg = (Uint32)(((*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift));
          db = (Uint32)(((*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift));
          sr = (Uint32)(((*ppsrc2 & ssrc2->format->Rmask) >> ssrc2->format->Rshift));
          sg = (Uint32)(((*ppsrc2 & ssrc2->format->Gmask) >> ssrc2->format->Gshift));
          sb = (Uint32)(((*ppsrc2 & ssrc2->format->Bmask) >> ssrc2->format->Bshift));
          a1 = sa + 1;
          a2 = 256 - sa;
          *ppdst = (((sr * a1 + dr * a2) >> 8)) << dst.fmt->Rshift |
                   (((sg * a1 + dg * a2) >> 8)) << dst.fmt->Gshift |
                   (((sb * a1 + db * a2) >> 8)) << dst.fmt->Bshift |
                   (255 >> dst.fmt->Aloss);
  #endif
          ppsrc2++;
          ppdst++;
        }
      }

      SDL_UnlockSurface(ssrc2);
      SDL_UnlockSurface(dst.surface);
    }

    SDL_FreeSurface(ssrc2);

    src.x = dst.x;
    src.y = dst.y;
  }

  ssrc = TTF_RenderUTF8_Blended(font, sptr, fore_color);

  if(ssrc == NULL) return INT2NUM(src.x);

  if(dst.surface == scr)
  {
    drect.x = src.x;
    drect.y = src.y;
    SDL_BlitSurface(ssrc, NULL, dst.surface, &(drect));
  }
  else
  {
    MiyakoSize size;

    psrc = (Uint32 *)(ssrc->pixels);

    size.w = dst.rect.w - (src.x < 0 ? 0 : src.x);
    if(size.w <= 0)
    {
      SDL_FreeSurface(ssrc);
      return INT2NUM(dst.x);
    }
    if(size.w > ssrc->w){ size.w = ssrc->w; }

    margin_x = 0;
    if(src.x < 0)
    {
      int tmp_w = ssrc->w + src.x;
      if(tmp_w < size.w) size.w += src.x;
      if(size.w <= 0)
      {
        SDL_FreeSurface(ssrc);
        return INT2NUM(dst.x);
      }
      margin_x = -src.x;
      src.x = 0;
    }

    size.h = dst.rect.h - (src.y < 0 ? 0 : src.y);
    if(size.h <= 0)
    {
      SDL_FreeSurface(ssrc);
      return INT2NUM(dst.x);
    }
    if(size.h > ssrc->h){ size.h = ssrc->h; }

    margin_y = 0;
    if(src.y < 0)
    {
      int tmp_h = ssrc->h + src.y;
      if(tmp_h < size.h) size.h += src.y;
      if(size.h <= 0)
      {
        SDL_FreeSurface(ssrc);
        return INT2NUM(dst.x);
      }
      margin_y = -src.y;
      src.y = 0;
    }

    SDL_LockSurface(ssrc);
    SDL_LockSurface(dst.surface);

    for(y = 0; y < size.h; y++)
    {
      Uint32 *ppsrc = psrc + (y+margin_y) * ssrc->w + margin_x;
      Uint32 *ppdst = dst.ptr + (src.y + y) * dst.surface->w + src.x;
      for(x = 0; x < size.w; x++)
      {
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
        da = (*ppdst >> 24) | dst.a255;
        sa = *ppsrc >> 24;
        if(sa == 0){ ppsrc++; ppdst++; continue; }
        if(da == 0 || sa == 255){
          *ppdst = *ppsrc;
          ppsrc++;
          ppdst++;
          continue;
        }
#if 0
        dr = (Uint32)(((*ppdst) >> 16)) & 0xff;
        dg = (Uint32)(((*ppdst) >> 8)) & 0xff;
        db = (Uint32)(((*ppdst))) & 0xff;
        sr = (Uint32)(((*ppsrc) >> 16)) & 0xff;
        sg = (Uint32)(((*ppsrc) >> 8)) & 0xff;
        sb = (Uint32)(((*ppsrc))) & 0xff;
        a1 = sa + 1;
        a2 = 256 - sa;
        *ppdst = (((sr * a1 + dr * a2) >> 8)) << 16 |
                 (((sg * a1 + dg * a2) >> 8)) << 8 |
                 (((sb * a1 + db * a2) >> 8)) |
                 0xff000000;
#else
        dr = *ppdst & 0xff0000;
        dg = *ppdst & 0xff00;
        db = *ppdst & 0xff;
        sr = *ppsrc & 0xff0000;
        sg = *ppsrc & 0xff00;
        sb = *ppsrc & 0xff;
        a1 = sa + 1;
        a2 = 256 - sa;
        *ppdst = ((sr * a1 + dr * a2) & 0xff000000 |
                  (sg * a1 + dg * a2) & 0xff0000   |
                  (sb * a1 + db * a2)) >> 8        |
                 0xff000000;
#endif
#else
        da = (Uint32)(((*ppdst & dst.fmt->Amask)) << dst.fmt->Aloss) | dst.a255;
        sa = (Uint32)(((*ppsrc & ssrc->format->Amask)) << ssrc->format->Aloss);
        if(sa == 0){ ppsrc++; ppdst++; continue; }
        if(da == 0 || sa == 255){
          *ppdst = *ppsrc;
          ppsrc++;
          ppdst++;
          continue;
        }
        dr = (Uint32)(((*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift));
        dg = (Uint32)(((*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift));
        db = (Uint32)(((*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift));
        sr = (Uint32)(((*ppsrc & ssrc->format->Rmask) >> ssrc->format->Rshift));
        sg = (Uint32)(((*ppsrc & ssrc->format->Gmask) >> ssrc->format->Gshift));
        sb = (Uint32)(((*ppsrc & ssrc->format->Bmask) >> ssrc->format->Bshift));
        a1 = sa + 1;
        a2 = 256 - sa;
        *ppdst = (((sr * a1 + dr * a2) >> 8)) << dst.fmt->Rshift |
                 (((sg * a1 + dg * a2) >> 8)) << dst.fmt->Gshift |
                 (((sb * a1 + db * a2) >> 8)) << dst.fmt->Bshift |
                 (255 >> dst.fmt->Aloss);
#endif
        ppsrc++;
        ppdst++;
      }
    }

    SDL_UnlockSurface(ssrc);
    SDL_UnlockSurface(dst.surface);
  }
  SDL_FreeSurface(ssrc);

  ptr = RSTRING_PTR(str);
  len = RSTRING_LEN(str);
  enc = rb_enc_get(str);
  for(i=0; i<len; i+=n)
  {
    n = rb_enc_mbclen(ptr+i, ptr+len, enc);
    chr = rb_str_subseq(str, i, n);
    clen = RSTRING_LEN(chr);
    dst.x += (clen==1 ? font_size>>1 : font_size) + shadow_margin_x + hspace;
  }
  return INT2NUM(dst.x);
}

static VALUE font_line_height(VALUE self)
{
  int height = NUM2INT(rb_iv_get(self, "@line_skip"));
  height += NUM2INT(rb_iv_get(self, "@vspace"));
  height += (rb_iv_get(self, "@use_shadow") == Qtrue ? NUM2INT(*(RARRAY_PTR(rb_iv_get(self, "@shadow_margin"))+1)) : 0);
  return INT2NUM(height);
}

static VALUE font_text_size(VALUE self, VALUE str)
{
  int font_size = NUM2INT(rb_iv_get(self, "@size"));
  VALUE use_shadow = rb_iv_get(self, "@use_shadow");
  VALUE shadow_margin = rb_iv_get(self, "@shadow_margin");
  int shadow_margin_x = (use_shadow == Qtrue ? NUM2INT(*(RARRAY_PTR(shadow_margin)+0)) : 0);
  int hspace = NUM2INT(rb_iv_get(self, "@hspace"));

  VALUE chr, array;
  int i, n, l=0, clen;
  const char *ptr = RSTRING_PTR(str);
  int len = RSTRING_LEN(str);
  rb_encoding *enc = rb_enc_get(str);
  for(i=0; i<len; i+=n)
  {
    n = rb_enc_mbclen(ptr+i, ptr+len, enc);
    chr = rb_str_subseq(str, i, n);
    clen = RSTRING_LEN(chr);
    l += (clen==1 ? font_size>>1 : font_size) + shadow_margin_x + hspace;
  }
  array = rb_ary_new();
  rb_ary_push(array, INT2NUM(l));
  rb_ary_push(array, font_line_height(self));
  return array;
}

void Init_miyako_font()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  cFont  = rb_define_class_under(mMiyako, "Font", rb_cObject);
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cTTFFont = rb_define_class_under(mSDL, "TTF", rb_cObject);
  cEncoding = rb_define_class("Encoding", rb_cObject);

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  id_utf8   = rb_intern("UTF_8");
  id_encode = rb_intern("encode");

  rb_define_method(cFont, "draw_text", font_draw_text, 4);
  rb_define_method(cFont, "line_height", font_line_height, 0);
  rb_define_method(cFont, "text_size", font_text_size, 1);
}
