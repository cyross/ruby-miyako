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
  return *(RSTRUCT_PTR(get_layout(self)));
}

VALUE _miyako_layout_pos(VALUE self)
{
  return layout_pos(self);
}

static VALUE layout_size(VALUE self)
{
  return *(RSTRUCT_PTR(get_layout(self))+1);
}

VALUE _miyako_layout_size(VALUE self)
{
  return layout_size(self);
}

static VALUE layout_x(VALUE self)
{
  return *(RSTRUCT_PTR(layout_pos(self))+0);
}

VALUE _miyako_layout_x(VALUE self)
{
  return layout_x(self);
}

static VALUE layout_y(VALUE self)
{
  return *(RSTRUCT_PTR(layout_pos(self))+1);
}

VALUE _miyako_layout_y(VALUE self)
{
  return layout_y(self);
}

static VALUE layout_update_layout(VALUE self, VALUE dx, VALUE dy)
{
  rb_funcall(self, rb_intern("update_layout_position"), 0);
  VALUE layout   = get_layout(self);
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
  VALUE *pos = RSTRUCT_PTR(*(RSTRUCT_PTR(get_layout(self))));
  VALUE *pox = pos+0;
  VALUE *poy = pos+1;
  VALUE tx = *pox;
  VALUE ty = *poy;
  *pox = INT2NUM(NUM2INT(tx)+NUM2INT(dx));
  *poy = INT2NUM(NUM2INT(ty)+NUM2INT(dy));
  layout_update_layout(self, dx, dy);
  VALUE on_move = *(RSTRUCT_PTR(get_layout(self)) + 4);
  int i;
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, *pox, *poy, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qnil || ret == Qfalse)
    {
      *pox = tx;
      *poy = ty;
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
  VALUE *pos = RSTRUCT_PTR(*(RSTRUCT_PTR(get_layout(self))));
  VALUE *pox = pos+0;
  VALUE *poy = pos+1;
  VALUE tx = *pox;
  VALUE ty = *poy;
  *pox = x;
  *poy = y;
	VALUE dx = INT2NUM((NUM2INT(x))-(NUM2INT(tx)));
	VALUE dy = INT2NUM((NUM2INT(y))-(NUM2INT(ty)));
  layout_update_layout(self, dx, dy);
  VALUE on_move = *(RSTRUCT_PTR(get_layout(self)) + 4);
  int i;
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, *pox, *poy, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qnil || ret == Qfalse)
    {
      *pox = tx;
      *poy = ty;
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
  //      bpos = @layout.base.pos
  // Size.new(bpos.x+x,bpos.y+y)
  VALUE *pos = RSTRUCT_PTR(*(RSTRUCT_PTR(get_layout(self))));
  VALUE *pox = pos+0;
  VALUE *poy = pos+1;
  VALUE tx = *pox;
  VALUE ty = *poy;

  VALUE base = *(RSTRUCT_PTR(get_layout(self))+2);
  VALUE *bpos = RSTRUCT_PTR(rb_funcall(base, rb_intern("pos"), 0));

  *pox = INT2NUM(NUM2INT(x)+NUM2INT(*(bpos+0)));
  *poy = INT2NUM(NUM2INT(y)+NUM2INT(*(bpos+1)));

  VALUE dx = INT2NUM(NUM2INT(*pox)-NUM2INT(tx));
  VALUE dy = INT2NUM(NUM2INT(*poy)-NUM2INT(ty));
  layout_update_layout(self, dx, dy);
  VALUE on_move = *(RSTRUCT_PTR(get_layout(self)) + 4);
  int i;
  for(i=0; i<RARRAY_LEN(on_move); i++)
  {
    rb_funcall(*(RARRAY_PTR(on_move) + i), rb_intern("call"), 5, self, *pox, *poy, dx, dy);
  }
  if(rb_block_given_p() == Qtrue){
    VALUE ret = rb_yield(self);
    if(ret == Qnil || ret == Qfalse)
    {
      *pox = tx;
      *poy = ty;
      layout_update_layout(self, INT2NUM(-(NUM2INT(dx))), INT2NUM(-(NUM2INT(dy))));
    }
  }
  return self;
}

static VALUE layout_add_snap_child(VALUE self, VALUE spr)
{
  VALUE layout   = get_layout(self);
  VALUE snap     = *(RSTRUCT_PTR(layout)+3);
  VALUE children = *(RSTRUCT_PTR(snap)+1);
  if(rb_ary_includes(children, spr)==Qfalse){ rb_ary_push(children, spr); }
  return self;
}

static VALUE layout_delete_snap_child(VALUE self, VALUE spr)
{
  VALUE layout   = get_layout(self);
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
  VALUE layout  = get_layout(self);
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
