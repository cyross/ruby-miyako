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
画像を回転させて貼り付ける
*/
static VALUE bitmap_miyako_rotate(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = 255; }
	if(dst == scr){ dst_a = 255; }

	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	
	if(psrc == pdst){ return Qnil; }
	
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

  if(drect.w >= 32768 || drect.h >= 32768){ return Qnil; }

  MIYAKO_INIT_RECT2;
  
  double rad = NUM2DBL(radian) * -1.0;
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

	int px = srect.x + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int py = srect.y + NUM2INT(*(RSTRUCT_PTR(sunit)+8));
	int qx = NUM2INT(*(RSTRUCT_PTR(sunit)+5)) + NUM2INT(*(RSTRUCT_PTR(dunit)+7));
	int qy = NUM2INT(*(RSTRUCT_PTR(sunit)+6)) + NUM2INT(*(RSTRUCT_PTR(dunit)+8));

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int x, y;
  for(y = dly; y < dmy; y++)
  {
    int ty = y - qy;
    Uint32 *tp = pdst + y * dst->w;
    for(x = dlx; x < dmx; x++)
    {
      int nx = (((x-qx)*icos-ty*isin) >> 12) + px;
      if(nx < srect.x || nx >= (srect.x+srect.w)){ continue; }
      int ny = (((x-qx)*isin+ty*icos) >> 12) + py;
      if(ny < srect.y || ny >= (srect.y+srect.h)){ continue; }
      pixel = *(tp + x) | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *(psrc + ny * src->w + nx) | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ continue; }
      if(dcolor.a == 0 || scolor.a == 255)
      {
        *(tp + x) = pixel;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *(tp + x) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                  (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                  (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                    put_a;
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);
	
  return vdst;
}

/*
画像を拡大・縮小・鏡像(ミラー反転)させて貼り付ける
*/
static VALUE bitmap_miyako_scale(VALUE self, VALUE vsrc, VALUE vdst, VALUE xscale, VALUE yscale)
{
  MIYAKO_GET_UNIT_2(vsrc, vdst, sunit, dunit, src, dst);
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = 255; }
	if(dst == scr){ dst_a = 255; }

	SDL_PixelFormat *fmt = src->format;
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	
	if(psrc == pdst){ return Qnil; }
	
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

  if(drect.w >= 32768 || drect.h >= 32768){ return Qnil; }

  MIYAKO_INIT_RECT2;

  double tscx = NUM2DBL(xscale);
  double tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0){ return Qnil; }

  int scx = (int)(4096.0 / tscx);
  int scy = (int)(4096.0 / tscy);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

	int px = srect.x + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int py = srect.y + NUM2INT(*(RSTRUCT_PTR(sunit)+8));
	int qx = NUM2INT(*(RSTRUCT_PTR(sunit)+5)) + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int qy = NUM2INT(*(RSTRUCT_PTR(sunit)+6)) + NUM2INT(*(RSTRUCT_PTR(sunit)+8));

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int x, y;
  for(y = dly; y < dmy; y++)
  {
    int ty = y - qy;
    Uint32 *tp = pdst + y * dst->w;
    for(x = dlx; x < dmx; x++)
    {
      int nx = (((x-qx) * scx) >> 12) + px - off_x;
      if(nx < srect.x || nx >= (srect.x+srect.w)){ continue; }
      int ny = ((ty * scy) >> 12) + py - off_y;
      if(ny < srect.y || ny >= (srect.y+srect.h)){ continue; }
      pixel = *(tp + x) | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *(psrc + ny * src->w + nx) | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ continue; }
      if(dcolor.a == 0 || scolor.a == 255)
      {
        *(tp + x) = pixel;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *(tp + x) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                  (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                  (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                  put_a;
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);

  return vdst;
}

/*
===回転・拡大・縮小・鏡像用インナーメソッド
*/
static void transform_inner(VALUE sunit, VALUE dunit, VALUE radian, VALUE xscale, VALUE yscale)
{
	SDL_Surface *src = GetSurface(*(RSTRUCT_PTR(sunit)))->surface;
	SDL_Surface *dst = GetSurface(*(RSTRUCT_PTR(dunit)))->surface;
	Uint32 *psrc = (Uint32 *)(src->pixels);
	Uint32 *pdst = (Uint32 *)(dst->pixels);
	Uint32 src_a = 0;
	Uint32 dst_a = 0;

	SDL_PixelFormat *fmt = src->format;
	SDL_Surface *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	if(src == scr){ src_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	if(dst == scr){ dst_a = (0xff >> fmt->Aloss) << fmt->Ashift; }
	
	MiyakoColor scolor, dcolor;
	Uint32 pixel;
	SDL_Rect srect, drect;
	
	if(psrc == pdst){ return; }
	
	MIYAKO_SET_RECT(srect, sunit);
	MIYAKO_SET_RECT(drect, dunit);

  if(drect.w >= 32768 || drect.h >= 32768){ return; }

  MIYAKO_INIT_RECT2;
  
  double rad = NUM2DBL(radian) * -1.0;
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

  double tscx = NUM2DBL(xscale);
  double tscy = NUM2DBL(yscale);

  if(tscx == 0.0 || tscy == 0.0){ return; }

  int scx = (int)(4096.0 / tscx);
  int scy = (int)(4096.0 / tscy);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

	int px = srect.x + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int py = srect.y + NUM2INT(*(RSTRUCT_PTR(sunit)+8));
	int qx = NUM2INT(*(RSTRUCT_PTR(sunit)+5)) + NUM2INT(*(RSTRUCT_PTR(sunit)+7));
	int qy = NUM2INT(*(RSTRUCT_PTR(sunit)+6)) + NUM2INT(*(RSTRUCT_PTR(sunit)+8));

  Uint32 put_a = (255 >> fmt->Aloss) << fmt->Ashift;

  SDL_LockSurface(src);
  SDL_LockSurface(dst);
  
  int x, y;
  for(y = dly; y < dmy; y++)
  {
    int ty = y - qy;
    Uint32 *tp = pdst + y * dst->w;
    for(x = dlx; x < dmx; x++)
    {
      int nx = (((((x-qx)*icos-ty*isin) >> 12) * scx) >> 12) + px - off_x;
      if(nx < srect.x || nx >= (srect.x+srect.w)){ continue; }
      int ny = (((((x-qx)*isin+ty*icos) >> 12) * scy) >> 12) + py - off_y;
      if(ny < srect.y || ny >= (srect.y+srect.h)){ continue; }
      pixel = *(tp + x) | dst_a;
      MIYAKO_GETCOLOR(dcolor);
			pixel = *(psrc + ny * src->w + nx) | src_a;
			MIYAKO_GETCOLOR(scolor);
      if(scolor.a == 0){ continue; }
      if(dcolor.a == 0 || scolor.a == 255)
      {
        *(tp + x) = pixel;
        continue;
      }
      int a1 = scolor.a + 1;
      int a2 = 256 - scolor.a;
      *(tp + x) = (((scolor.r * a1 + dcolor.r * a2) >> 8) >> fmt->Rloss) << fmt->Rshift |
                  (((scolor.g * a1 + dcolor.g * a2) >> 8) >> fmt->Gloss) << fmt->Gshift |
                  (((scolor.b * a1 + dcolor.b * a2) >> 8) >> fmt->Bloss) << fmt->Bshift |
                  put_a;
    }
  }

  SDL_UnlockSurface(src);
  SDL_UnlockSurface(dst);
}

/*
画像を変形(回転・拡大・縮小・鏡像)させて貼り付ける
*/
static VALUE bitmap_miyako_transform(VALUE self, VALUE vsrc, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  MIYAKO_GET_UNIT_NO_SURFACE_2(vsrc, vdst, sunit, dunit);
  transform_inner(sunit, dunit, radian, xscale, yscale);
  return vdst;
}

/*
インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
*/
static VALUE sprite_render_transform(VALUE self, VALUE radian, VALUE xscale, VALUE yscale)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  MIYAKO_GET_UNIT_NO_SURFACE_2(self, mScreen, sunit, dunit);
  transform_inner(sunit, dunit, radian, xscale, yscale);
  return self;
}

/*
インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
*/
static VALUE sprite_render_to_sprite_transform(VALUE self, VALUE vdst, VALUE radian, VALUE xscale, VALUE yscale)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  MIYAKO_GET_UNIT_NO_SURFACE_2(self, vdst, sunit, dunit);
  transform_inner(sunit, dunit, radian, xscale, yscale);
  return self;
}

void Init_miyako_transform()
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
