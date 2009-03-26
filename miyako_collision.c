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


/*
:nodoc:
*/
static VALUE collision_c_collision(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1));
  int r1 = l1 + NUM2INT(*(prect1+2)) - 1;
  int b1 = t1 + NUM2INT(*(prect1+3)) - 1;
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1));
  int r2 = l2 + NUM2INT(*(prect2+2)) - 1;
  int b2 = t2 + NUM2INT(*(prect2+3)) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_collision_with_move(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  VALUE *pdir1 = RSTRUCT_PTR(rb_iv_get(c1, "@direction"));
  VALUE *pdir2 = RSTRUCT_PTR(rb_iv_get(c2, "@direction"));
  VALUE *pamt1 = RSTRUCT_PTR(rb_iv_get(c1, "@amount"));
  VALUE *pamt2 = RSTRUCT_PTR(rb_iv_get(c2, "@amount"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1) + NUM2INT(*pdir1) * NUM2INT(*pamt1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1)) + NUM2INT(*(pdir1+1)) * NUM2INT(*(pamt1+1));
  int r1 = l1 + NUM2INT(*(prect1+2)) - 1;
  int b1 = t1 + NUM2INT(*(prect1+3)) - 1;
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2) + NUM2INT(*pdir2) * NUM2INT(*pamt2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1)) + NUM2INT(*(pdir2+1)) * NUM2INT(*(pamt2+1));
  int r2 = l2 + NUM2INT(*(prect2+2)) - 1;
  int b2 = t2 + NUM2INT(*(prect2+3)) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_meet(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1));
  int r1 = l1 + NUM2INT(*(prect1+2));
  int b1 = t1 + NUM2INT(*(prect1+3));
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1));
  int r2 = l2 + NUM2INT(*(prect2+2));
  int b2 = t2 + NUM2INT(*(prect2+3));

  int v = 0;
  if(r1 == l2) v |= 1;
  if(b1 == t2) v |= 1;
  if(l1 == r2) v |= 1;
  if(t1 == b2) v |= 1;

  if(v == 1) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_into(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qfalse && f2 == Qtrue) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_out(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qtrue && f2 == Qfalse) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_cover(VALUE self, VALUE c1, VALUE c2)
{
  VALUE *prect1 = RSTRUCT_PTR(rb_iv_get(c1, "@rect"));
  VALUE *prect2 = RSTRUCT_PTR(rb_iv_get(c2, "@rect"));
  VALUE *ppos1 = RSTRUCT_PTR(rb_iv_get(c1, "@pos"));
  VALUE *ppos2 = RSTRUCT_PTR(rb_iv_get(c2, "@pos"));
  int l1 = NUM2INT(*ppos1) + NUM2INT(*prect1);
  int t1 = NUM2INT(*(ppos1+1)) + NUM2INT(*(prect1+1));
  int r1 = l1 + NUM2INT(*(prect1+2)) - 1;
  int b1 = t1 + NUM2INT(*(prect1+3)) - 1;
  int l2 = NUM2INT(*ppos2) + NUM2INT(*prect2);
  int t2 = NUM2INT(*(ppos2+1)) + NUM2INT(*(prect2+1));
  int r2 = l2 + NUM2INT(*(prect2+2)) - 1;
  int b2 = t2 + NUM2INT(*(prect2+3)) - 1;

  int v = 0;
  if(l1 <= l2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && b2 <= b1) v |= 2;
  if(l2 <= l1 && r1 <= r2) v |= 4;
  if(t2 <= t1 && b1 <= b2) v |= 8;

  if(v == 3 || v == 12) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_collision(VALUE self, VALUE c2)
{
  return collision_c_collision(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_meet(VALUE self, VALUE c2)
{
  return collision_c_meet(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_into(VALUE self, VALUE c2)
{
  return collision_c_into(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_out(VALUE self, VALUE c2)
{
  return collision_c_out(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_cover(VALUE self, VALUE c2)
{
  return collision_c_cover(cCollision, self, c2);
}

/*
:nodoc:
*/
static VALUE collisions_collision(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_collision(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_meet(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_meet(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_into(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_into(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_out(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_out(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_cover(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_cover(c, cc) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_collision_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_collision(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_meet_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_meet(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_into_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_into(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_out_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_out(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_cover_all(VALUE self, VALUE c)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE cc = *(RARRAY_PTR(cs) + 0);
    if(collision_cover(c, cc) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

void Init_miyako_collision()
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

  rb_define_singleton_method(cCollision, "collision?", collision_c_collision, 2);
  rb_define_singleton_method(cCollision, "meet?", collision_c_meet, 2);
  rb_define_singleton_method(cCollision, "into?", collision_c_into, 2);
  rb_define_singleton_method(cCollision, "out?", collision_c_out, 2);
  rb_define_singleton_method(cCollision, "cover?", collision_c_cover, 2);
  rb_define_method(cCollision, "collision?", collision_collision, 1);
  rb_define_method(cCollision, "meet?", collision_meet, 1);
  rb_define_method(cCollision, "into?", collision_into, 1);
  rb_define_method(cCollision, "out?", collision_out, 1);
  rb_define_method(cCollision, "cover?", collision_cover, 1);

  rb_define_method(cCollisions, "collision?", collisions_collision, 1);
  rb_define_method(cCollisions, "meet?", collisions_meet, 1);
  rb_define_method(cCollisions, "into?", collisions_into, 1);
  rb_define_method(cCollisions, "out?", collisions_out, 1);
  rb_define_method(cCollisions, "cover?", collisions_cover, 1);
  rb_define_method(cCollisions, "collision_all?", collisions_collision_all, 1);
  rb_define_method(cCollisions, "meet_all?", collisions_meet_all, 1);
  rb_define_method(cCollisions, "into_all?", collisions_into_all, 1);
  rb_define_method(cCollisions, "out_all?", collisions_out_all, 1);
  rb_define_method(cCollisions, "cover_all?", collisions_cover_all, 1);
}
