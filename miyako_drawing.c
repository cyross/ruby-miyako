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
#include <sge.h>

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mDrawing = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cSurface = Qnil;
static VALUE cColor = Qnil;

// from rubysdl_video.c
static GLOBAL_DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");

static Uint32 value_2_color(VALUE color, SDL_PixelFormat *fmt, Uint8 *alpha)
{
  VALUE *array = RARRAY_PTR(color);
  if(alpha != NULL){ *alpha = (Uint8)(NUM2INT(*(array+3))); }
  return SDL_MapRGBA(fmt,
                     (Uint8)(NUM2INT(*(array+0))),
                     (Uint8)(NUM2INT(*(array+1))),
                     (Uint8)(NUM2INT(*(array+2))),
                     (Uint8)(NUM2INT(*(array+3)))
                    );
}

/*
:nodoc:
*/
static void get_position(VALUE pos, Sint16 *x, Sint16 *y)
{
  VALUE *tmp;
  switch(TYPE(pos))
  {
  case T_ARRAY:
    if(RARRAY_LEN(pos) < 2)
      rb_raise(eMiyakoError, "pairs have illegal array!");
    tmp = RARRAY_PTR(pos);
    *x = (Sint16)(NUM2INT(*tmp++));
    *y = (Sint16)(NUM2INT(*tmp));
    break;
  case T_STRUCT:
    if(RSTRUCT_LEN(pos) < 2)
      rb_raise(eMiyakoError, "pairs have illegal struct!");
    tmp = RSTRUCT_PTR(pos);
    *x = (Sint16)(NUM2INT(*tmp++));
    *y = (Sint16)(NUM2INT(*tmp));
    break;
  default:
    *x = (Sint16)(NUM2INT(rb_funcall(pos, rb_intern("x"), 0)));
    *y = (Sint16)(NUM2INT(rb_funcall(pos, rb_intern("y"), 0)));
    break;
  }
}

/*
ポリゴン描画
*/
static VALUE drawing_draw_polygon(int argc, VALUE *argv, VALUE self)
{
  VALUE vdst;
  VALUE pairs;
  VALUE mcolor;
  VALUE fill;
  VALUE aa;
  Uint8 alpha;
  Uint32 color;
  int i, vertexes;
  
  rb_scan_args(argc, argv, "32", &vdst, &pairs, &mcolor, &fill, &aa);
  
  // bitmapメソッドを持っていれば、メソッドの値をvdstとする
  VALUE methods = rb_funcall(vdst, rb_intern("methods"), 0);
  if(rb_ary_includes(methods, rb_str_intern(rb_str_new2("to_unit"))) == Qfalse &&
     rb_ary_includes(methods, rb_str_intern(rb_str_new2("bitmap"))) == Qfalse
    )
    rb_raise(eMiyakoError, "this method needs sprite have to_method or bitmap method!");
  if(rb_ary_includes(methods, rb_str_intern(rb_str_new2("to_unit"))) == Qtrue)
    vdst = rb_funcall(vdst, rb_intern("to_unit"), 0);
  vdst = rb_funcall(vdst, rb_intern("bitmap"), 0);

  vertexes = RARRAY_LEN(pairs);
  // 頂点数チェック
  if(vertexes > 65536)
    rb_raise(eMiyakoError, "too many pairs. pairs is less than 65536.");
  
  // 範囲チェック
  for(i=0; i<vertexes; i++)
  {
    VALUE vertex = *(RARRAY_PTR(pairs)+i);
    Sint16 x, y;
    get_position(vertex, &x, &y);
  }
  
	SDL_Surface  *dst = GetSurface(vdst)->surface;

  color = value_2_color(rb_funcall(cColor, rb_intern("to_rgb"), 1, mcolor), dst->format, &alpha);

  if(RTEST(fill) && RTEST(aa) && alpha < 255)
    rb_raise(eMiyakoError, "can't draw filled antialiased alpha polygon");

  Sint16 *px = (Sint16 *)malloc(sizeof(Sint16) * vertexes);
  Sint16 *py = (Sint16 *)malloc(sizeof(Sint16) * vertexes);
  for(i=0; i<vertexes; i++)
  {
    VALUE vertex = *(RARRAY_PTR(pairs)+i);
    get_position(vertex, px+i, py+i);
  }
  
  if(!RTEST(fill) && !RTEST(aa) && alpha == 255)
  {
    for(i=0; i<vertexes-1; i++)
      sge_Line(dst, px[i], py[i], px[i+1], py[i+1], color);
    sge_Line(dst, px[vertexes-1], py[vertexes-1], px[0], py[0], color);
  }
  else if(!RTEST(fill) && !RTEST(aa) && alpha < 255)
  {
    for(i=0; i<vertexes-1; i++)
      sge_LineAlpha(dst, px[i], py[i], px[i+1], py[i+1], color, alpha);
    sge_LineAlpha(dst, px[vertexes-1], py[vertexes-1], px[0], py[0], color, alpha);
  }
  else if(!RTEST(fill) && RTEST(aa) && alpha == 255)
  {
    for(i=0; i<vertexes-1; i++)
      sge_AALine(dst, px[i], py[i], px[i+1], py[i+1], color);
    sge_AALine(dst, px[vertexes-1], py[vertexes-1], px[0], py[0], color);
  }
  else if(!RTEST(fill) && RTEST(aa) && alpha < 255)
  {
    for(i=0; i<vertexes-1; i++)
      sge_AALineAlpha(dst, px[i], py[i], px[i+1], py[i+1], color, alpha);
    sge_AALineAlpha(dst, px[vertexes-1], py[vertexes-1], px[0], py[0], color, alpha);
  }
  else if(RTEST(fill) && !RTEST(aa) && alpha == 255)
    sge_FilledPolygon(dst, (Uint16)vertexes, px, py, color);
  else if(RTEST(fill) && !RTEST(aa) && alpha < 255)
    sge_FilledPolygonAlpha(dst, (Uint16)vertexes, px, py, color, alpha);
  else if(RTEST(fill) && RTEST(aa) && alpha == 255)
    sge_AAFilledPolygon(dst, (Uint16)vertexes, px, py, color);
  
  free(py);
  free(px);

  return Qnil;
}

void Init_miyako_drawing()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  mDrawing = rb_define_module_under(mMiyako, "Drawing");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cColor = rb_define_class_under(mMiyako, "Color", rb_cObject);
  
  rb_define_singleton_method(mDrawing, "polygon", drawing_draw_polygon, -1);
}
