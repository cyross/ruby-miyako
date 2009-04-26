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
static VALUE cWaitCounter = Qnil;
static VALUE sSpriteUnit = Qnil;
static VALUE sPoint = Qnil;
static VALUE sSize = Qnil;
static VALUE sRect = Qnil;
static VALUE sSquare = Qnil;
static VALUE sSegment = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

/*
:nodoc:
*/
static void get_min_max(VALUE segment, VALUE *min, VALUE *max)
{
  VALUE *tmp;
  switch(TYPE(segment))
  {
  case T_ARRAY:
    if(RARRAY_LEN(segment) < 2)
      rb_raise(eMiyakoError, "pairs have illegal array! (above 2 elements)");
    tmp = RARRAY_PTR(segment);
    *min = *tmp++;
    *max = *tmp;
    break;
  case T_STRUCT:
    if(RSTRUCT_LEN(segment) < 2)
      rb_raise(eMiyakoError, "pairs have illegal struct! (above 2 attributes)");
    tmp = RSTRUCT_PTR(segment);
    *min = *tmp++;
    *max = *tmp;
    break;
  default:
    *min = rb_funcall(segment, rb_intern("min"), 0);
    *max = rb_funcall(segment, rb_intern("max"), 0);
    break;
  }
}

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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *px = tx;
      *py = ty;
    }
  }
  return self;
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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *px = tx;
      *py = ty;
    }
  }
  return self;
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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *px = tx;
      *py = ty;
    }
  }
  return self;
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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *px = tx;
      *py = ty;
    }
  }
  return self;
}

static VALUE size_resize(VALUE self, VALUE dw, VALUE dh)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+0;
  VALUE *ph = st+1;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = INT2NUM(NUM2INT(tw)+NUM2INT(dw));
  *ph = INT2NUM(NUM2INT(th)+NUM2INT(dh));
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pw = tw;
      *ph = th;
    }
  }
  return self;
}

static VALUE size_resize_to(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+0;
  VALUE *ph = st+1;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = w;
  *ph = h;
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pw = tw;
      *ph = th;
    }
  }
  return self;
}

static VALUE rect_resize(VALUE self, VALUE dw, VALUE dh)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+2;
  VALUE *ph = st+3;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = INT2NUM(NUM2INT(*pw) + NUM2INT(dw));
  *ph = INT2NUM(NUM2INT(*pw) + NUM2INT(dh));
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pw = tw;
      *ph = th;
    }
  }
  return self;
}

static VALUE rect_resize_to(VALUE self, VALUE w, VALUE h)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pw = st+2;
  VALUE *ph = st+3;
  VALUE tw = *pw;
  VALUE th = *ph;
  *pw = w;
  *ph = h;
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pw = tw;
      *ph = th;
    }
  }
  return self;
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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pl = tl;
      *pt = tt;
      *pr = tr;
      *pb = tb;
    }
  }
  return self;
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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pl = tl;
      *pt = tt;
      *pr = tr;
      *pb = tb;
    }
  }
  return self;
}

static VALUE square_resize(VALUE self, VALUE dw, VALUE dh)
{
  VALUE *st = RSTRUCT_PTR(self);
  VALUE *pr = st+2;
  VALUE *pb = st+3;
  VALUE tr = *pr;
  VALUE tb = *pb;
  *pr = INT2NUM(NUM2INT(*pr) + NUM2INT(dw));
  *pb = INT2NUM(NUM2INT(*pb) + NUM2INT(dh));
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pr = tr;
      *pb = tb;
    }
  }
  return self;
}

static VALUE square_resize_to(VALUE self, VALUE w, VALUE h)
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
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
    {
      *pr = tr;
      *pb = tb;
    }
  }
  return self;
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

static VALUE segment_move(VALUE self, VALUE dx, VALUE dy)
{
  VALUE min_x, max_x, min_y, max_y;
  VALUE *st = RSTRUCT_PTR(self);
  
  get_min_max(*(st+0), &min_x, &max_x);
  get_min_max(*(st+1), &min_y, &max_y);
  
  rb_funcall(self, rb_intern("reset"), 4, INT2NUM(NUM2INT(min_x)+NUM2INT(dx)),
                                          INT2NUM(NUM2INT(min_y)+NUM2INT(dy)),
                                          INT2NUM(NUM2INT(max_x)+NUM2INT(dx)),
                                          INT2NUM(NUM2INT(max_y)+NUM2INT(dy)));

  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
      rb_funcall(self, rb_intern("reset"), 4, min_x, max_x, min_y, max_y);
  }

  return self;
}

static VALUE segment_move_to(VALUE self, VALUE x, VALUE y)
{
  VALUE min_x, max_x, min_y, max_y;
  VALUE *st = RSTRUCT_PTR(self);
  
  get_min_max(*(st+0), &min_x, &max_x);
  get_min_max(*(st+1), &min_y, &max_y);
  
  int w = NUM2INT(max_x)-NUM2INT(min_x);
  int h = NUM2INT(max_y)-NUM2INT(min_y);

  rb_funcall(self, rb_intern("reset"), 4, x, y, INT2NUM(NUM2INT(x)+w), INT2NUM(NUM2INT(y)+h));

  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
      rb_funcall(self, rb_intern("reset"), 4, min_x, max_x, min_y, max_y);
  }

  return self;
}

static VALUE segment_resize(VALUE self, VALUE dw, VALUE dh)
{
  VALUE min_x, max_x, min_y, max_y;
  VALUE *st = RSTRUCT_PTR(self);
   
  get_min_max(*(st+0), &min_x, &max_x);
  get_min_max(*(st+1), &min_y, &max_y);

  int w = NUM2INT(max_x) + NUM2INT(dw);
  int h = NUM2INT(max_y) + NUM2INT(dh);
  
  if(w <= 0)
    rb_raise(eMiyakoError, "illegal width(result is 0 or minus)");
  if(h <= 0)
    rb_raise(eMiyakoError, "illegal height(result is 0 or minus)");
  
  rb_funcall(self, rb_intern("reset"), 4, INT2NUM(NUM2INT(min_x)),
                                          INT2NUM(NUM2INT(min_y)),
                                          INT2NUM(w),
                                          INT2NUM(h));

  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
      rb_funcall(self, rb_intern("reset"), 4, min_x, max_x, min_y, max_y);
  }

  return self;
}

static VALUE segment_resize_to(VALUE self, VALUE w, VALUE h)
{
  VALUE min_x, max_x, min_y, max_y;
  VALUE *st = RSTRUCT_PTR(self);
  
  get_min_max(*(st+0), &min_x, &max_x);
  get_min_max(*(st+1), &min_y, &max_y);
  
  int nw = NUM2INT(w);
  int nh = NUM2INT(h);
  
  if(nw <= 0)
    rb_raise(eMiyakoError, "illegal width(result is 0 or minus)");
  if(nh <= 0)
    rb_raise(eMiyakoError, "illegal height(result is 0 or minus)");
  
  rb_funcall(self, rb_intern("reset"), 4, INT2NUM(NUM2INT(min_x)),
                                          INT2NUM(NUM2INT(min_y)),
                                          INT2NUM(NUM2INT(min_x)+nw-1),
                                          INT2NUM(NUM2INT(min_y)+nh-1));

  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qfalse || ret == Qnil)
      rb_funcall(self, rb_intern("reset"), 4, min_x, max_x, min_y, max_y);
  }

  return self;
}

void Init_miyako_basicdata()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cWaitCounter  = rb_define_class_under(mMiyako, "WaitCounter", rb_cObject);
  sSpriteUnit = rb_define_class_under(mMiyako, "SpriteUnitBase", rb_cStruct);
  sPoint = rb_define_class_under(mMiyako, "PointStruct", rb_cStruct);
  sSize = rb_define_class_under(mMiyako, "SizeStruct", rb_cStruct);
  sRect = rb_define_class_under(mMiyako, "RectStruct", rb_cStruct);
  sSquare = rb_define_class_under(mMiyako, "SquareStruct", rb_cStruct);
  sSegment = rb_define_class_under(mMiyako, "SegmentStruct", rb_cStruct);

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
  rb_define_method(sSize, "resize_to", size_resize_to, 2);
  rb_define_method(sRect, "move", point_move, 2);
  rb_define_method(sRect, "move_to", point_move_to, 2);
  rb_define_method(sRect, "resize", rect_resize, 2);
  rb_define_method(sRect, "resize_to", rect_resize_to, 2);
  rb_define_method(sRect, "in_range?", rect_in_range, 2);
  rb_define_method(sSquare, "move", square_move, 2);
  rb_define_method(sSquare, "move_to", square_move_to, 2);
  rb_define_method(sSquare, "resize", square_resize, 2);
  rb_define_method(sSquare, "resize_to", square_resize_to, 2);
  rb_define_method(sSquare, "in_range?", square_in_range, 2);
  rb_define_method(sSegment, "move", segment_move, 2);
  rb_define_method(sSegment, "move_to", segment_move_to, 2);
  rb_define_method(sSegment, "resize", segment_resize, 2);
  rb_define_method(sSegment, "resize_to", segment_resize_to, 2);
}
