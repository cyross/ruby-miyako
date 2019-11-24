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

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mLayout = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;
static const char *str_lo = "@layout";

static VALUE layout_snap(int argc, VALUE *argv, VALUE self);
static VALUE layout_move(VALUE self, VALUE dx, VALUE dy);

static VALUE get_layout(VALUE self)
{
  return rb_iv_get(self, str_lo);
}

static VALUE layout_pos(VALUE self)
{
  return RSTRUCT_GET(get_layout(self), 0);
}

VALUE _miyako_layout_pos(VALUE self)
{
  return layout_pos(self);
}

static VALUE layout_size(VALUE self)
{
  return RSTRUCT_GET(get_layout(self), 1);
}

VALUE _miyako_layout_size(VALUE self)
{
  return layout_size(self);
}

static VALUE layout_x(VALUE self)
{
  return RSTRUCT_GET(layout_pos(self), 0);
}

VALUE _miyako_layout_x(VALUE self)
{
  return layout_x(self);
}

static VALUE layout_y(VALUE self)
{
  return RSTRUCT_GET(layout_pos(self), 1);
}

VALUE _miyako_layout_y(VALUE self)
{
  return layout_y(self);
}

static VALUE layout_update_layout(VALUE self, VALUE dx, VALUE dy)
{
  int i;
  VALUE layout, children;
  rb_funcall(self, rb_intern("update_layout_position"), 0);
  layout   = get_layout(self);
  children = RSTRUCT_GET(RSTRUCT_GET(layout, 3), 1);
  for(i=0; i<RARRAY_LEN(children); i++)
  {
    layout_move(*(RARRAY_PTR(children) + i), dx, dy);
  }
  return Qnil;
}

static VALUE layout_move(VALUE self, VALUE dx, VALUE dy)
{
  int i;
  VALUE on_move;
  VALUE pos = RSTRUCT_GET(get_layout(self), 0);
  VALUE tx = RSTRUCT_GET(pos, 0);
  VALUE ty = RSTRUCT_GET(pos, 1);
  VALUE nx = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  VALUE ny = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  RSTRUCT_SET(pos, 0, nx);
  RSTRUCT_SET(pos, 1, ny);
  layout_update_layout(self, dx, dy);
  on_move = RSTRUCT_GET(get_layout(self), 4);
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, nx, ny, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qnil || ret == Qfalse)
    {
      RSTRUCT_SET(pos, 0, tx);
      RSTRUCT_SET(pos, 1, ty);
      layout_update_layout(self, INT2NUM(-(NUM2INT(dx))), INT2NUM(-(NUM2INT(dy))));
    }
  }
  return self;
}

VALUE _miyako_layout_move(VALUE self, VALUE dx, VALUE dy)
{
  return layout_move(self, dx, dy);
}

static VALUE layout_move_to(VALUE self, VALUE x, VALUE y)
{
  int i;
  VALUE on_move;
  VALUE pos = RSTRUCT_GET(get_layout(self), 0);
  VALUE tx = RSTRUCT_GET(pos, 0);
  VALUE ty = RSTRUCT_GET(pos, 1);
  VALUE dx = INT2NUM((NUM2INT(x))-(NUM2INT(tx)));
  VALUE dy = INT2NUM((NUM2INT(y))-(NUM2INT(ty)));

  RSTRUCT_SET(pos, 0, x);
  RSTRUCT_SET(pos, 1, y);
  layout_update_layout(self, dx, dy);
  on_move = RSTRUCT_GET(get_layout(self), 4);
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, tx, ty, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qnil || ret == Qfalse)
    {
      RSTRUCT_SET(pos, 0, tx);
      RSTRUCT_SET(pos, 1, ty);
      layout_update_layout(self, INT2NUM(-(NUM2INT(dx))), INT2NUM(-(NUM2INT(dy))));
    }
  }
  return self;
}

VALUE _miyako_layout_move_to(VALUE self, VALUE x, VALUE y)
{
  return layout_move_to(self, x, y);
}

static VALUE layout_relative_move_to(VALUE self, VALUE x, VALUE y)
{
  int i;
  VALUE on_move, dx, dy;
  //      bpos = @layout.base.pos
  // Size.new(bpos.x+x,bpos.y+y)
  VALUE pos = RSTRUCT_GET(get_layout(self), 0);
  VALUE tx = RSTRUCT_GET(pos, 0);
  VALUE ty = RSTRUCT_GET(pos, 1);
  VALUE base = RSTRUCT_GET(get_layout(self), 2);
  VALUE bpos = rb_funcall(base, rb_intern("pos"), 0);
  VALUE nx = INT2NUM(NUM2INT(x)+NUM2INT(RSTRUCT_GET(bpos, 0)));
  VALUE ny = INT2NUM(NUM2INT(y)+NUM2INT(RSTRUCT_GET(bpos, 1)));

  RSTRUCT_SET(pos, 0, nx);
  RSTRUCT_SET(pos, 1, ny);
  dx = INT2NUM(NUM2INT(nx)-NUM2INT(tx));
  dy = INT2NUM(NUM2INT(ny)-NUM2INT(ty));
  layout_update_layout(self, dx, dy);
  on_move = RSTRUCT_GET(get_layout(self), 4);
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, nx, ny, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qnil || ret == Qfalse)
    {
      RSTRUCT_SET(pos, 0, tx);
      RSTRUCT_SET(pos, 1, ty);
      layout_update_layout(self, INT2NUM(-(NUM2INT(dx))), INT2NUM(-(NUM2INT(dy))));
    }
  }
  return self;
}

static VALUE layout_add_snap_child(VALUE self, VALUE spr)
{
  VALUE layout   = get_layout(self);
  VALUE snap     = RSTRUCT_GET(layout, 3);
  VALUE children = RSTRUCT_GET(snap, 1);
  if(rb_ary_includes(children, spr)==Qfalse){ rb_ary_push(children, spr); }
  return self;
}

static VALUE layout_delete_snap_child(VALUE self, VALUE spr)
{
  VALUE layout   = get_layout(self);
  VALUE snap     = RSTRUCT_GET(layout, 3);
  VALUE children = RSTRUCT_GET(snap, 1);
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
  VALUE layout, tmp, sprite;
  VALUE spr = Qnil;
  rb_scan_args(argc, argv, "01", &spr);
  layout  = get_layout(self);
  tmp = RSTRUCT_GET(layout, 3);
  sprite = RSTRUCT_GET(tmp, 0);
  if(spr != Qnil)
  {
    if(sprite != Qnil){ layout_delete_snap_child(sprite, self); }
    RSTRUCT_SET(tmp, 0, spr);
    layout_add_snap_child(spr, self);
  }
  if(sprite != Qnil)
  {
    RSTRUCT_SET(layout, 2, sprite);
  }
  else
  {
    RSTRUCT_SET(layout, 2, mScreen);
  }
  return self;
}

void Init_miyako_layout()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  mLayout = rb_define_module_under(mMiyako, "Layout");

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_method(mLayout, "x", layout_x, 0);
  rb_define_method(mLayout, "y", layout_y, 0);
  rb_define_method(mLayout, "pos", layout_pos, 0);
  rb_define_method(mLayout, "size", layout_size, 0);
  rb_define_method(mLayout, "move!", layout_move, 2);
  rb_define_method(mLayout, "move_to!", layout_move_to, 2);
  rb_define_method(mLayout, "relative_move_to!", layout_relative_move_to, 2);
  rb_define_method(mLayout, "update_layout", layout_update_layout, 2);
  rb_define_method(mLayout, "snap", layout_snap, -1);
  rb_define_method(mLayout, "add_snap_child", layout_add_snap_child, 1);
  rb_define_method(mLayout, "delete_snap_child", layout_delete_snap_child, 1);
}
