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
  rb_secure(4);
  StringValue(str);

  str = rb_funcall(str, id_encode, 1, rb_const_get(cEncoding, id_utf8));
  
  TTF_Font *font = Get_TTFont(rb_iv_get(self, "@font"))->font;

  VALUE *p_font_color = RARRAY_PTR(rb_iv_get(self, "@color"));
  SDL_Color fore_color;
  fore_color.r = NUM2INT(*(p_font_color+0));
  fore_color.g = NUM2INT(*(p_font_color+1));
  fore_color.b = NUM2INT(*(p_font_color+2));
  fore_color.unused = 0;

  VALUE *p_shadow_color = RARRAY_PTR(rb_iv_get(self, "@shadow_color"));
  SDL_Color shadow_color;
  shadow_color.r = NUM2INT(*(p_shadow_color+0));
  shadow_color.g = NUM2INT(*(p_shadow_color+1));
  shadow_color.b = NUM2INT(*(p_shadow_color+2));
  shadow_color.unused = 0;

  int font_size = NUM2INT(rb_iv_get(self, "@size"));
  VALUE use_shadow = rb_iv_get(self, "@use_shadow");
  VALUE shadow_margin = rb_iv_get(self, "@shadow_margin");
  int shadow_margin_x = (use_shadow == Qtrue ? NUM2INT(*(RARRAY_PTR(shadow_margin)+0)) : 0);
  int shadow_margin_y = (use_shadow == Qtrue ? NUM2INT(*(RARRAY_PTR(shadow_margin)+1)) : 0);
  int hspace = NUM2INT(rb_iv_get(self, "@hspace"));

  SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

	MiyakoBitmap src, dst;
  _miyako_setup_unit(vdst, scr, &dst, vx, vy, 0);

  char *sptr = RSTRING_PTR(str);

  src.x = dst.x;
  src.y = dst.y;

	int x, y;

  if(use_shadow == Qtrue)
  {
    SDL_Surface *ssrc2 = TTF_RenderUTF8_Blended(font, sptr, shadow_color);

    if(ssrc2 == NULL) return INT2NUM(src.x);
    Uint32 *psrc2 = (Uint32 *)(ssrc2->pixels);
	
    src.x += shadow_margin_x;
    src.y += shadow_margin_y;
    
		MiyakoSize size2;
		size2.w = dst.rect.w - (src.x < 0 ? -(src.x) : src.x);
		size2.h = dst.rect.h - (src.y < 0 ? -(src.y) : src.y);
		if(size2.w > ssrc2->w){ size2.w = ssrc2->w; }
		if(size2.h > ssrc2->h){ size2.h = ssrc2->h; }

    SDL_LockSurface(ssrc2);
    SDL_LockSurface(dst.surface);
  
    for(y = 0; y < size2.h; y++)
    {
      Uint32 *ppsrc2 = psrc2 + y * ssrc2->w;
      Uint32 *ppdst = dst.ptr + (src.y + y) * dst.surface->w + src.x;
      for(x = 0; x < size2.w; x++)
      {
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
				dst.color.a = (Uint32)(((*ppdst) >> 24) << dst.fmt->Aloss) & 0xff | dst.a255;
	      src.color.a = (Uint32)(((*ppsrc2) >> 24) << ssrc2->format->Aloss) & 0xff;
        if(src.color.a == 0){ ppsrc2++; ppdst++; continue; }
        if(dst.color.a == 0 || src.color.a == 255){
          *ppdst = *ppsrc2;
          ppsrc2++;
          ppdst++;
          continue;
        }
				dst.color.r = (Uint32)(((*ppdst) >> 16)) & 0xff;
				dst.color.g = (Uint32)(((*ppdst) >> 8)) & 0xff;
				dst.color.b = (Uint32)(((*ppdst))) & 0xff;
	      src.color.r = (Uint32)(((*ppsrc2) >> 16)) & 0xff;
	      src.color.g = (Uint32)(((*ppsrc2) >> 8)) & 0xff;
	      src.color.b = (Uint32)(((*ppsrc2))) & 0xff;
        int a1 = src.color.a + 1;
        int a2 = 256 - src.color.a;
        *ppdst = (((src.color.r * a1 + dst.color.r * a2) >> 8)) << 16 |
                 (((src.color.g * a1 + dst.color.g * a2) >> 8)) << 8 |
                 (((src.color.b * a1 + dst.color.b * a2) >> 8)) |
                 (255 >> dst.fmt->Aloss) << 24;
#else
				dst.color.a = (Uint32)(((*ppdst & dst.fmt->Amask)) << dst.fmt->Aloss) | dst.a255;
	      src.color.a = (Uint32)(((*ppsrc2 & ssrc2->format->Amask)) << ssrc2->format->Aloss);
        if(src.color.a == 0){ ppsrc2++; ppdst++; continue; }
        if(dst.color.a == 0 || src.color.a == 255){
          *ppdst = *ppsrc2;
          ppsrc2++;
          ppdst++;
          continue;
        }
				dst.color.r = (Uint32)(((*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift));
				dst.color.g = (Uint32)(((*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift));
				dst.color.b = (Uint32)(((*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift));
	      src.color.r = (Uint32)(((*ppsrc2 & ssrc2->format->Rmask) >> ssrc2->format->Rshift));
	      src.color.g = (Uint32)(((*ppsrc2 & ssrc2->format->Gmask) >> ssrc2->format->Gshift));
	      src.color.b = (Uint32)(((*ppsrc2 & ssrc2->format->Bmask) >> ssrc2->format->Bshift));
        int a1 = src.color.a + 1;
        int a2 = 256 - src.color.a;
        *ppdst = (((src.color.r * a1 + dst.color.r * a2) >> 8)) << dst.fmt->Rshift |
                 (((src.color.g * a1 + dst.color.g * a2) >> 8)) << dst.fmt->Gshift |
                 (((src.color.b * a1 + dst.color.b * a2) >> 8)) << dst.fmt->Bshift |
                 (255 >> dst.fmt->Aloss);
#endif
        ppsrc2++;
        ppdst++;
      }
    }

    SDL_UnlockSurface(ssrc2);
    SDL_UnlockSurface(dst.surface);

    SDL_FreeSurface(ssrc2);

    src.x = dst.x;
    src.y = dst.y;
  }

  SDL_Surface *ssrc = TTF_RenderUTF8_Blended(font, sptr, fore_color);

  if(ssrc == NULL) return INT2NUM(src.x);

  Uint32 *psrc = (Uint32 *)(ssrc->pixels);

	MiyakoSize size;
	size.w = dst.rect.w - (src.x < 0 ? -(src.x) : src.x);
	size.h = dst.rect.h - (src.y < 0 ? -(src.y) : src.y);
	if(size.w > ssrc->w){ size.w = ssrc->w; }
	if(size.h > ssrc->h){ size.h = ssrc->h; }

  SDL_LockSurface(ssrc);
  SDL_LockSurface(dst.surface);
  
	for(y = 0; y < size.h; y++)
	{
		Uint32 *ppsrc = psrc + y * ssrc->w;
		Uint32 *ppdst = dst.ptr + (src.y + y) * dst.surface->w + src.x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
			dst.color.a = (Uint32)(((*ppdst) >> 24) << dst.fmt->Aloss) & 0xff | dst.a255;
			src.color.a = (Uint32)(((*ppsrc) >> 24) << ssrc->format->Aloss) & 0xff;
			if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = *ppsrc;
				ppsrc++;
				ppdst++;
				continue;
			}
			dst.color.r = (Uint32)(((*ppdst) >> 16)) & 0xff;
			dst.color.g = (Uint32)(((*ppdst) >> 8)) & 0xff;
			dst.color.b = (Uint32)(((*ppdst))) & 0xff;
			src.color.r = (Uint32)(((*ppsrc) >> 16)) & 0xff;
			src.color.g = (Uint32)(((*ppsrc) >> 8)) & 0xff;
			src.color.b = (Uint32)(((*ppsrc))) & 0xff;
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*ppdst = (((src.color.r * a1 + dst.color.r * a2) >> 8)) << 16 |
							 (((src.color.g * a1 + dst.color.g * a2) >> 8)) << 8 |
							 (((src.color.b * a1 + dst.color.b * a2) >> 8)) |
							 (255 >> dst.fmt->Aloss) << 24;
#else
			dst.color.a = (Uint32)(((*ppdst & dst.fmt->Amask)) << dst.fmt->Aloss) | dst.a255;
			src.color.a = (Uint32)(((*ppsrc & ssrc->format->Amask)) << ssrc->format->Aloss);
			if(src.color.a == 0){ ppsrc++; ppdst++; continue; }
			if(dst.color.a == 0 || src.color.a == 255){
				*ppdst = *ppsrc;
				ppsrc++;
				ppdst++;
				continue;
			}
			dst.color.r = (Uint32)(((*ppdst & dst.fmt->Rmask) >> dst.fmt->Rshift));
			dst.color.g = (Uint32)(((*ppdst & dst.fmt->Gmask) >> dst.fmt->Gshift));
			dst.color.b = (Uint32)(((*ppdst & dst.fmt->Bmask) >> dst.fmt->Bshift));
			src.color.r = (Uint32)(((*ppsrc & ssrc->format->Rmask) >> ssrc->format->Rshift));
			src.color.g = (Uint32)(((*ppsrc & ssrc->format->Gmask) >> ssrc->format->Gshift));
			src.color.b = (Uint32)(((*ppsrc & ssrc->format->Bmask) >> ssrc->format->Bshift));
			int a1 = src.color.a + 1;
			int a2 = 256 - src.color.a;
			*ppdst = (((src.color.r * a1 + dst.color.r * a2) >> 8)) << dst.fmt->Rshift |
							 (((src.color.g * a1 + dst.color.g * a2) >> 8)) << dst.fmt->Gshift |
							 (((src.color.b * a1 + dst.color.b * a2) >> 8)) << dst.fmt->Bshift |
							 (255 >> dst.fmt->Aloss);
#endif
      ppsrc++;
			ppdst++;
		}
	}

  SDL_UnlockSurface(ssrc);
  SDL_UnlockSurface(dst.surface);
  SDL_FreeSurface(ssrc);

  int i, n;
  const char *ptr = RSTRING_PTR(str);
  int len = RSTRING_LEN(str);
  rb_encoding *enc = rb_enc_get(str);
  for(i=0; i<len; i+=n)
  {
    n = rb_enc_mbclen(ptr+i, ptr+len, enc);
    VALUE chr = rb_str_subseq(str, i, n);
    int clen = RSTRING_LEN(chr);
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

  int i, n, l=0;
  const char *ptr = RSTRING_PTR(str);
  int len = RSTRING_LEN(str);
  rb_encoding *enc = rb_enc_get(str);
  for(i=0; i<len; i+=n)
  {
    n = rb_enc_mbclen(ptr+i, ptr+len, enc);
    VALUE chr = rb_str_subseq(str, i, n);
    int clen = RSTRING_LEN(chr);
    l += (clen==1 ? font_size>>1 : font_size) + shadow_margin_x + hspace;
  }
  VALUE array = rb_ary_new();
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
