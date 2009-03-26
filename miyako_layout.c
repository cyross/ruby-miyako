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

static VALUE layout_snap(int argc, VALUE *argv, VALUE self);
static VALUE layout_move(VALUE self, VALUE dx, VALUE dy);

static VALUE layout_update_layout(VALUE self, VALUE dx, VALUE dy)
{
  rb_funcall(self, rb_intern("update_layout_position"), 0);
  VALUE layout   = rb_iv_get(self, "@layout");
  VALUE children = *(RSTRUCT_PTR(*(RSTRUCT_PTR(layout)+3))+1);
  int i;
  for(i=0; i<RARRAY_LEN(children); i++)
  {
    layout_move(*(RARRAY_PTR(children) + i), dx, dy);
  }
  return Qnil;
}

static VALUE layout_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *pos = RSTRUCT_PTR(*(RSTRUCT_PTR(rb_iv_get(self, "@layout"))));
  VALUE *pox = pos+0;
  VALUE *poy = pos+1;
  VALUE tx = *pox;
  VALUE ty = *poy;
  *pox = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *poy = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  layout_update_layout(self, dx, dy);
  VALUE on_move = *(RSTRUCT_PTR(rb_iv_get(self, "@layout")) + 4);
  int i;
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, *pox, *poy, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pox = tx;
    *poy = ty;
    layout_update_layout(self, INT2NUM(-(NUM2INT(dx))), INT2NUM(-(NUM2INT(dy))));
  }
  return self;
}

static VALUE layout_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *pos = RSTRUCT_PTR(*(RSTRUCT_PTR(rb_iv_get(self, "@layout"))));
  VALUE *pox = pos+0;
  VALUE *poy = pos+1;
  VALUE tx = *pox;
  VALUE ty = *poy;
  *pox = x;
  *poy = y;
	VALUE dx = INT2NUM((NUM2INT(x))-(NUM2INT(tx)));
	VALUE dy = INT2NUM((NUM2INT(y))-(NUM2INT(ty)));
  layout_update_layout(self, dx, dy);
  VALUE on_move = *(RSTRUCT_PTR(rb_iv_get(self, "@layout")) + 4);
  int i;
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, *pox, *poy, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pox = tx;
    *poy = ty;
    layout_update_layout(self, INT2NUM(-(NUM2INT(dx))), INT2NUM(-(NUM2INT(dy))));
  }
  return self;
}

static VALUE layout_add_snap_child(VALUE self, VALUE spr)
{
  VALUE layout   = rb_iv_get(self, "@layout");
  VALUE snap     = *(RSTRUCT_PTR(layout)+3);
  VALUE children = *(RSTRUCT_PTR(snap)+1);
  if(rb_ary_includes(children, spr)==Qfalse){ rb_ary_push(children, spr); }
  return self;
}

static VALUE layout_delete_snap_child(VALUE self, VALUE spr)
{
  VALUE layout   = rb_iv_get(self, "@layout");
  VALUE snap     = *(RSTRUCT_PTR(layout)+3);
  VALUE children = *(RSTRUCT_PTR(snap)+1);
  if(TYPE(spr) == T_ARRAY)
  {
    int i;
    for(i=0; i<RARRAY_LEN(spr); i++){ rb_ary_delete(children, *(RARRAY_PTR(spr) + i)); }
  }
  else
  {
    rb_ary_delete(children, spr);
  }
  return self;
}

static VALUE layout_snap(int argc, VALUE *argv, VALUE self)
{
  VALUE spr = Qnil;
  rb_scan_args(argc, argv, "01", &spr);
  VALUE layout  = rb_iv_get(self, "@layout");
  VALUE *sprite = RSTRUCT_PTR(*(RSTRUCT_PTR(layout)+3));
  VALUE *base   = RSTRUCT_PTR(layout)+2;
  if(spr != Qnil)
  {
    if(*sprite != Qnil){ layout_delete_snap_child(*sprite, self); }
    *sprite = spr;
    layout_add_snap_child(spr, self);
  }
  if(*sprite != Qnil)
  {
    *base = *sprite;
  }
	else
	{
    *base = mScreen;
	}
  return self;
}

void Init_miyako_layout()
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

	rb_define_method(mLayout, "move", layout_move, 2);
	rb_define_method(mLayout, "move_to", layout_move_to, 2);
	rb_define_method(mLayout, "update_layout", layout_update_layout, 2);
	rb_define_method(mLayout, "snap", layout_snap, -1);
	rb_define_method(mLayout, "add_snap_child", layout_add_snap_child, 1);
	rb_define_method(mLayout, "delete_snap_child", layout_delete_snap_child, 1);
}
