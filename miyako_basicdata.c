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
static VALUE counter_start(VALUE self)
{
  rb_iv_set(self, "@st", rb_funcall(mSDL, rb_intern("getTicks"), 0));
  rb_iv_set(self, "@counting", Qtrue);
  return self;
}

/*
:nodoc:
*/
static VALUE counter_stop(VALUE self)
{
  rb_iv_set(self, "@st", INT2NUM(0));
  rb_iv_set(self, "@counting", Qfalse);
  return self;
}

/*
:nodoc:
*/
static VALUE counter_wait_inner(VALUE self, VALUE f)
{
  VALUE counting = rb_iv_set(self, "@counting", Qtrue);
  if(counting == Qfalse){ return f == Qtrue ? Qfalse : Qtrue; }

  int t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int st = NUM2INT(rb_iv_get(self, "@st"));
  int wait = NUM2INT(rb_iv_get(self, "@wait"));
  if((t - st) < wait){ return f; }

  rb_iv_set(cWaitCounter, "@counting", Qfalse);

  return f == Qtrue ? Qfalse : Qtrue;
}

/*
:nodoc:
*/
static VALUE counter_waiting(VALUE self)
{
  return counter_wait_inner(self, Qtrue);
}

/*
:nodoc:
*/
static VALUE counter_finish(VALUE self)
{
  return counter_wait_inner(self, Qfalse);
}

/*
:nodoc:
*/
static VALUE counter_wait(VALUE self)
{
  int t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int st = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int wait = NUM2INT(rb_iv_get(self, "@wait"));
  while((t - st) < wait){
    t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  }
  return self;
}

static VALUE su_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+5;
  VALUE *py = st+6;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *py = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE su_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+5;
  VALUE *py = st+6;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = x;
  *py = y;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE point_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+0;
  VALUE *py = st+1;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *py = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE point_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *px = st+0;
  VALUE *py = st+1;
  VALUE tx = *px;
  VALUE ty = *py;
  *px = x;
  *py = y;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *px = tx;
    *py = ty;
  }
  return Qnil;
}

static VALUE size_resize(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+0;
  VALUE *ph = st+1;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = w;
  *ph = h;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pw = tw;
    *ph = th;
  }
  return Qnil;
}

static VALUE rect_resize(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+2;
  VALUE *ph = st+3;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = w;
  *ph = h;
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pw = tw;
    *ph = th;
  }
  return Qnil;
}

static VALUE rect_in_range(VALUE self, VALUE vx, VALUE vy)
{
  VALUE *st = RSTRUCT_PTR(self);
  int l = NUM2INT(*(st+0));
  int t = NUM2INT(*(st+1));
  int w = NUM2INT(*(st+2));
  int h = NUM2INT(*(st+3));
  int x = NUM2INT(vx);
  int y = NUM2INT(vy);
  
  if(x >= l && y >= t && x < (l+w) && y < (t+h)){ return Qtrue; }
  return Qfalse;
}

static VALUE square_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pl = st+0;
  VALUE *pt = st+1;
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tl = *pl;
  VALUE tt = *pt;
  VALUE tr = *pr;
  VALUE tb = *pb;
  *pl = INT2NUM(NUM2INT(tl)+NUM2INT(dx));
  *pt = INT2NUM(NUM2INT(tt)+NUM2INT(dy));
  *pr = INT2NUM(NUM2INT(tr)+NUM2INT(dx));
  *pb = INT2NUM(NUM2INT(tb)+NUM2INT(dy));
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pl = tl;
    *pt = tt;
    *pr = tr;
    *pb = tb;
  }
  return Qnil;
}

static VALUE square_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pl = st+0;
  VALUE *pt = st+1;
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tl = *pl;
  VALUE tt = *pt;
  VALUE tr = *pr;
  VALUE tb = *pb;
  int w = NUM2INT(tr)-NUM2INT(tl);
  int h = NUM2INT(tb)-NUM2INT(tt);
  *pl = x;
  *pt = y;
  *pr = INT2NUM(NUM2INT(x)+w);
  *pb = INT2NUM(NUM2INT(y)+h);
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pl = tl;
    *pt = tt;
    *pr = tr;
    *pb = tb;
  }
  return Qnil;
}

static VALUE square_resize(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pl = st+0;
  VALUE *pt = st+1;
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tr = *pr;
  VALUE tb = *pb;
  *pr = INT2NUM(NUM2INT(*pl) + NUM2INT(w) - 1);
  *pb = INT2NUM(NUM2INT(*pt) + NUM2INT(h) - 1);
  if(rb_block_given_p() == Qtrue){
    rb_yield(Qnil);
    *pr = tr;
    *pb = tb;
  }
  return Qnil;
}

static VALUE square_in_range(VALUE self, VALUE vx, VALUE vy)
{
  VALUE *st = RSTRUCT_PTR(self);
  int l = NUM2INT(*(st+0));
  int t = NUM2INT(*(st+1));
  int r = NUM2INT(*(st+2));
  int b = NUM2INT(*(st+3));
  int x = NUM2INT(vx);
  int y = NUM2INT(vy);
  
  if(x >= l && y >= t && x <= r && y <= b){ return Qtrue; }
  return Qfalse;
}

void Init_miyako_basicdata()
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

  rb_define_method(cWaitCounter, "start", counter_start, 0);
  rb_define_method(cWaitCounter, "stop",  counter_stop,  0);
  rb_define_method(cWaitCounter, "wait_inner", counter_wait_inner, 1);
  rb_define_method(cWaitCounter, "waiting?", counter_waiting, 0);
  rb_define_method(cWaitCounter, "finish?", counter_finish, 0);
  rb_define_method(cWaitCounter, "wait", counter_wait, 0);
  
  rb_define_method(sSpriteUnit, "move", su_move, 2);
  rb_define_method(sSpriteUnit, "move_to", su_move_to, 2);

  rb_define_method(sPoint, "move", point_move, 2);
  rb_define_method(sPoint, "move_to", point_move_to, 2);
  rb_define_method(sSize, "resize", size_resize, 2);
  rb_define_method(sRect, "move", point_move, 2);
  rb_define_method(sRect, "move_to", point_move_to, 2);
  rb_define_method(sRect, "resize", rect_resize, 2);
  rb_define_method(sRect, "in_range?", rect_in_range, 2);
  rb_define_method(sSquare, "move", square_move, 2);
  rb_define_method(sSquare, "move_to", square_move_to, 2);
  rb_define_method(sSquare, "resize", square_resize, 2);
  rb_define_method(sSquare, "in_range?", square_in_range, 2);
}
