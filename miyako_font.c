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

  MIYAKO_GET_UNIT_1(vdst, dunit, dst);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
  MiyakoColor scolor, dcolor;
  SDL_Rect srect, drect;
	Uint32 dst_a = 0;
  Uint32 pixel;

	SDL_PixelFormat *fmt = dst->format;
  SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }

	MIYAKO_SET_RECT(drect, dunit);

  int x =  NUM2INT(vx);
  int y =  NUM2INT(vy);
  
  char *sptr = RSTRING_PTR(str);

  int tx = x;
  int ty = y;

  if(use_shadow == Qtrue)
  {
    SDL_Surface *src2 = TTF_RenderUTF8_Blended(font, sptr, shadow_color);

    if(src2 == NULL) return INT2NUM(tx);
    Uint32 *psrc2 = (Uint32 *)(src2->pixels);
	
    srect.x = 0;
    srect.y = 0;
    srect.w = src2->w;
    srect.h = src2->h;

    x += shadow_margin_x;
    y += shadow_margin_y;
      
    MIYAKO_INIT_RECT1;
    if(dmx > dst->w){ dmx = dst->w; }
    if(dmy > dst->h){ dmy = dst->h; }

    SDL_LockSurface(src2);
    SDL_LockSurface(dst);
  
    int px, py, sy;
    for(py = dly, sy = srect.y; py < dmy; py++, sy++)
    {
      Uint32 *ppsrc2 = psrc2 + sy * src2->w;
      Uint32 *ppdst = pdst + py * dst->w + dlx;
      for(px = dlx; px < dmx; px++)
      {
        pixel = *ppdst | dst_a;
        MIYAKO_GETCOLOR(dcolor);
        pixel = *ppsrc2;
        MIYAKO_GETCOLOR(scolor);
        if(scolor.a == 0){ ppsrc2++; ppdst++; continue; }
        if(dcolor.a == 0 || scolor.a == 255){
          *ppdst = pixel;
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
        ppsrc2++;
        ppdst++;
      }
    }

    SDL_UnlockSurface(src2);
    SDL_UnlockSurface(dst);

    SDL_FreeSurface(src2);

    drect.x = NUM2INT(*(RSTRUCT_PTR(dunit) + 1));
    drect.y = NUM2INT(*(RSTRUCT_PTR(dunit) + 2));
    drect.w = NUM2INT(*(RSTRUCT_PTR(dunit) + 3));
    drect.h = NUM2INT(*(RSTRUCT_PTR(dunit) + 4));
  }

  x = tx;
  y = ty;

  SDL_Surface *src = TTF_RenderUTF8_Blended(font, sptr, fore_color);

  if(src == NULL) return INT2NUM(x);

  Uint32 *psrc = (Uint32 *)(src->pixels);

  srect.x = 0;
  srect.y = 0;
  srect.w = src->w;
  srect.h = src->h;

  MIYAKO_INIT_RECT1;
  if(dmx > dst->w){ dmx = dst->w; }
  if(dmy > dst->h){ dmy = dst->h; }

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int px, py, sy;
  for(py = dly, sy = srect.y; py < dmy; py++, sy++)
  {
    Uint32 *ppsrc = psrc + sy * src->w;
    Uint32 *ppdst = pdst + py * dst->w + dlx;
    for(px = dlx; px < dmx; px++)
    {
      pixel = *ppdst | dst_a;
      MIYAKO_GETCOLOR(dcolor);
      pixel = *ppsrc;
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
  SDL_FreeSurface(src);

  int i, n;
  const char *ptr = RSTRING_PTR(str);
  int len = RSTRING_LEN(str);
  rb_encoding *enc = rb_enc_get(str);
  for(i=0; i<len; i+=n)
  {
    n = rb_enc_mbclen(ptr+i, ptr+len, enc);
    VALUE chr = rb_str_subseq(str, i, n);
    int clen = RSTRING_LEN(chr);
    x += (clen==1 ? font_size>>1 : font_size) + shadow_margin_x + hspace;
  }
  return INT2NUM(x);
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

  id_utf8   = rb_intern("UTF_8");
  id_encode = rb_intern("encode");

  rb_define_method(cFont, "draw_text", font_draw_text, 4);
  rb_define_method(cFont, "line_height", font_line_height, 0);
  rb_define_method(cFont, "text_size", font_text_size, 1);
}
