/*
--
Miyako v2.1 Extend Library "Miyako no Katana"
Copyright (C) 2009  Cyross Makoto

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
Version:: 2.1
Copyright:: 2007-2009 Cyross Makoto
License:: LGPL2.1
 */
#include "defines.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mSpriteArray = Qnil;
static VALUE mSpriteBase = Qnil;
static VALUE cSpriteList = Qnil;
static VALUE cListPairStruct = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_start = Qnil;
static volatile ID id_stop = Qnil;
static volatile ID id_reset = Qnil;
static volatile ID id_update_animation = Qnil;
static volatile ID id_move = Qnil;
static volatile ID id_move_to = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_render_to = Qnil;
static volatile ID id_sprite_only = Qnil;
static volatile int zero = 0;
static volatile int one = 1;
static char *str_list = "@list";

/*
:nodoc:
*/
static VALUE lps_to_ary(VALUE self)
{
  VALUE array = rb_ary_new();
  rb_ary_push(array, *(RSTRUCT_PTR(self)+0));
  rb_ary_push(array, *(RSTRUCT_PTR(self)+1));
  return array;
}

/*
:nodoc:
*/
static void lps_move_inner(VALUE value, ID id, VALUE x, VALUE y)
{
  rb_funcall(*(RSTRUCT_PTR(value)+1), id, 2, x, y);
}

/*
:nodoc:
*/
static VALUE lps_move(VALUE self, VALUE dx, VALUE dy)
{
  lps_move_inner(self, id_move, dx, dy);
  return self;
}

/*
:nodoc:
*/
static VALUE lps_move_to(VALUE self, VALUE x, VALUE y)
{
  lps_move_inner(self, id_move_to, x, y);
  return self;
}

/*
:nodoc:
*/
static void lps_inner(VALUE value, ID id)
{
  rb_funcall(*(RSTRUCT_PTR(value)+1), id, 0);
}

/*
:nodoc:
*/
static VALUE lps_start(VALUE self)
{
  lps_inner(self, id_start);
  return self;
}

/*
:nodoc:
*/
static VALUE lps_stop(VALUE self)
{
  lps_inner(self, id_stop);
  return self;
}

/*
:nodoc:
*/
static VALUE lps_reset(VALUE self)
{
  lps_inner(self, id_reset);
  return self;
}

/*
:nodoc:
*/
static VALUE lps_update_animation(VALUE self)
{
  return rb_funcall(*(RSTRUCT_PTR(self)+1), id_update_animation, 0);
}

/*
:nodoc:
*/
static VALUE lps_render(VALUE self)
{
  lps_inner(self, id_render);
  return self;
}

/*
:nodoc:
*/
static VALUE lps_render_to(VALUE self, VALUE dst)
{
  rb_funcall(*(RSTRUCT_PTR(self)+1), id_render_to, 1, dst);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_array_sprite_only(VALUE self)
{
  VALUE array = rb_ary_new();

  int i;
  VALUE *ptr = RARRAY_PTR(self);
  for(i=0; i<RARRAY_LEN(self); i++)
  {
    VALUE e = *(ptr+i);
    VALUE c = CLASS_OF(*(RSTRUCT_PTR(e)+1));
    if(rb_mod_include_p(c, mSpriteBase) == Qtrue ||
       rb_mod_include_p(c, mSpriteArray) == Qtrue)
    {
      rb_ary_push(array, e);
    }
  }
  return array;
}

/*
:nodoc:
*/
static void sprite_array_move_inner(VALUE array, ID id, VALUE x, VALUE y)
{
  int i;
  VALUE *ptr = RARRAY_PTR(array);
  if(rb_block_given_p() == Qtrue)
  {
    for(i=0; i<RARRAY_LEN(array); i++)
    {
      VALUE e = *(ptr+i);
      VALUE ret = rb_yield_values(4, e, INT2NUM(i), x, y);
      VALUE r1 = rb_funcall(ret, id_kakko, 1, nZero);
      VALUE r2 = rb_funcall(ret, id_kakko, 1, nOne);
      rb_funcall(e, id, 2, r1, r2);
    }
  }
  else
  {
    for(i=0; i<RARRAY_LEN(array); i++)
    {
      rb_funcall(*(ptr+i), id, 2, x, y);
    }
  }
}

/*
:nodoc:
*/
static VALUE sprite_array_move(VALUE self, VALUE dx, VALUE dy)
{
  sprite_array_move_inner(sprite_array_sprite_only(self),
                          id_move, dx, dy);

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_array_move_to(VALUE self, VALUE x, VALUE y)
{
  sprite_array_move_inner(sprite_array_sprite_only(self),
                          id_move_to, x, y);

  return self;
}

/*
:nodoc:
*/
static void sprite_array_inner(VALUE array, ID id)
{
  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    rb_funcall(*(RARRAY_PTR(array)+i), id, 0);
  }
}

/*
:nodoc:
*/
static VALUE sprite_array_start(VALUE self)
{
  sprite_array_inner(sprite_array_sprite_only(self), id_start);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_array_stop(VALUE self)
{
  sprite_array_inner(sprite_array_sprite_only(self), id_stop);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_array_reset(VALUE self)
{
  sprite_array_inner(sprite_array_sprite_only(self), id_reset);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_array_update_animation(VALUE self)
{
  VALUE array = sprite_array_sprite_only(self);
  VALUE ret = rb_ary_new();
  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    rb_ary_push(ret, rb_funcall(*(RARRAY_PTR(array)+i), id_update_animation, 0));
  }
  return ret;
}

/*
:nodoc:
*/
static VALUE sprite_array_render(VALUE self)
{
  sprite_array_inner(sprite_array_sprite_only(self), id_render);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_array_render_to(VALUE self, VALUE dst)
{
  VALUE array = sprite_array_sprite_only(self);

  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    rb_funcall(*(RARRAY_PTR(array)+i), id_render_to, 1, dst);
  }

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_sprite_only(VALUE self)
{
  VALUE hash  = rb_hash_new();
  VALUE list = rb_iv_get(self, str_list);

  int i;
  VALUE *ptr = RARRAY_PTR(list);
  for(i=0; i<RARRAY_LEN(list); i++)
  {
    VALUE *p2 = RSTRUCT_PTR(*(ptr+i));
    VALUE n = *(p2+0);
    VALUE v = *(p2+1);
    VALUE c = CLASS_OF(v);
    if(rb_mod_include_p(c, mSpriteBase) == Qtrue ||
       rb_mod_include_p(c, mSpriteArray) == Qtrue)
    {
      rb_hash_aset(hash, n, v);
    }
  }
  return rb_funcall(cSpriteList, rb_intern("new"), 1, hash);
}

/*
:nodoc:
*/
static void sprite_list_move_inner(VALUE vlist, ID id, VALUE x, VALUE y)
{
  VALUE list = rb_iv_get(vlist, str_list);
  int i;
  VALUE *ptr = RARRAY_PTR(list);
  if(rb_block_given_p() == Qtrue)
  {
    for(i=0; i<RARRAY_LEN(list); i++)
    {
      VALUE e = *(ptr+i);
      VALUE ret = rb_yield_values(4, e, INT2NUM(i), x, y);
      VALUE r1 = rb_funcall(ret, id_kakko, 1, nZero);
      VALUE r2 = rb_funcall(ret, id_kakko, 1, nOne);
      rb_funcall(e, id, 2, r1, r2);
    }
  }
  else
  {
    for(i=0; i<RARRAY_LEN(list); i++)
    {
      VALUE v = *(RSTRUCT_PTR(*(ptr+i))+1);
      rb_funcall(v, id, 2, x, y);
    }
  }
}

/*
:nodoc:
*/
static VALUE sprite_list_move(VALUE self, VALUE dx, VALUE dy)
{
  sprite_list_move_inner(self, id_move, dx, dy);

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_move_to(VALUE self, VALUE x, VALUE y)
{
  sprite_list_move_inner(self, id_move_to, x, y);

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_each(VALUE self)
{
  RETURN_ENUMERATOR(self, 0, 0);

  VALUE array = rb_iv_get(self, str_list);

  int i;
  VALUE *ptr = RARRAY_PTR(array);
  for(i=0; i<RARRAY_LEN(array); i++)
    rb_yield_values(1, *(ptr+i));

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_each_pair(VALUE self)
{
  RETURN_ENUMERATOR(self, 0, 0);

  VALUE array = rb_iv_get(self, str_list);

  int i;
  VALUE *ptr = RARRAY_PTR(array);
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    VALUE *sptr = RSTRUCT_PTR(*(ptr+i));
    rb_yield_values(2, *(sptr+0), *(sptr+1));
  }

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_each_name(VALUE self)
{
  RETURN_ENUMERATOR(self, 0, 0);

  VALUE array = rb_iv_get(self, str_list);

  int i;
  VALUE *ptr = RARRAY_PTR(array);
  for(i=0; i<RARRAY_LEN(array); i++)
    rb_yield_values(1, *(RSTRUCT_PTR(*(ptr+i))+0));

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_each_value(VALUE self)
{
  RETURN_ENUMERATOR(self, 0, 0);

  VALUE array = rb_iv_get(self, str_list);

  int i;
  VALUE *ptr = RARRAY_PTR(array);
  for(i=0; i<RARRAY_LEN(array); i++)
    rb_yield_values(1, *(RSTRUCT_PTR(*(ptr+i))+1));

  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_each_index(VALUE self)
{
  RETURN_ENUMERATOR(self, 0, 0);

  VALUE array = rb_iv_get(self, str_list);

  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
    rb_yield_values(1, INT2NUM(i));

  return self;
}

/*
:nodoc:
*/
static void sprite_list_inner(VALUE list, ID id)
{
  VALUE array = rb_iv_get(list, str_list);
  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    lps_inner(*(RARRAY_PTR(array)+i), id);
  }
}

/*
:nodoc:
*/
static VALUE sprite_list_start(VALUE self)
{
  sprite_list_inner(self, id_start);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_stop(VALUE self)
{
  sprite_list_inner(self, id_stop);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_reset(VALUE self)
{
  sprite_list_inner(self, id_reset);
  return self;
}

/*
:nodoc:
*/
static VALUE sprite_list_update_animation(VALUE self)
{
  VALUE array = rb_iv_get(self, str_list);
  VALUE ret = rb_ary_new();
  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    rb_ary_push(ret, lps_update_animation(*(RARRAY_PTR(array)+i)));
  }
  return ret;
}

/*
:nodoc:
*/
VALUE _miyako_sprite_list_update_animation(VALUE splist)
{
  sprite_list_update_animation(splist);
  return splist;
}

/*
:nodoc:
*/
static VALUE sprite_list_render(VALUE self)
{
  sprite_list_inner(self, id_render);
  return self;
}

/*
:nodoc:
*/
VALUE _miyako_sprite_list_render(VALUE splist)
{
  sprite_list_inner(splist, id_render);
  return splist;
}

/*
:nodoc:
*/
static VALUE sprite_list_render_to(VALUE self, VALUE dst)
{
  VALUE array = rb_iv_get(self, str_list);
  int i;
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    VALUE pair = *(RARRAY_PTR(array)+i);
    rb_funcall(*(RSTRUCT_PTR(pair)+1), id_render_to, 1, dst);
  }

  return self;
}

/*
:nodoc:
*/
VALUE _miyako_sprite_list_render_to(VALUE splist, VALUE dst)
{
  sprite_list_render_to(splist, dst);
  return splist;
}

/*
:nodoc:
*/
static VALUE sprite_list_map_inner(VALUE self, int idx)
{
  VALUE array = rb_iv_get(self, str_list);
  int i;
  VALUE ret = rb_ary_new();
  VALUE *ptr = RARRAY_PTR(array);
  for(i=0; i<RARRAY_LEN(array); i++)
  {
    rb_ary_push(ret, *(RSTRUCT_PTR(*(ptr+i))+idx));
  }
  return ret;
}

/*
:nodoc:
*/
static VALUE sprite_list_names(VALUE self)
{
  return sprite_list_map_inner(self, 0);
}

/*
:nodoc:
*/
static VALUE sprite_list_values(VALUE self)
{
  return sprite_list_map_inner(self, 1);
}

void Init_miyako_sprite2()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mSpriteArray = rb_define_module_under(mMiyako, "SpriteArray");
  mSpriteBase = rb_define_module_under(mMiyako, "SpriteBase");
  cSpriteList = rb_define_class_under(mMiyako, "SpriteList", rb_cObject);
  cListPairStruct = rb_define_class_under(mMiyako, "ListPairStruct", rb_cStruct);

  id_kakko  = rb_intern("[]");
  id_start = rb_intern("start");
  id_stop = rb_intern("stop");
  id_reset = rb_intern("reset");
  id_update_animation = rb_intern("update_animation");
  id_move = rb_intern("move!");
  id_move_to = rb_intern("move_to!");
  id_render = rb_intern("render");
  id_render_to = rb_intern("render_to");
  id_sprite_only = rb_intern("sprite_only");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_method(cListPairStruct, "to_ary", lps_to_ary, 0);
  rb_define_method(cListPairStruct, "to_a", lps_to_ary, 0);
  rb_define_method(cListPairStruct, "start", lps_start, 0);
  rb_define_method(cListPairStruct, "stop", lps_stop, 0);
  rb_define_method(cListPairStruct, "reset", lps_reset, 0);
  rb_define_method(cListPairStruct, "update_animation", lps_update_animation, 0);
  rb_define_method(cListPairStruct, "move!", lps_move, 2);
  rb_define_method(cListPairStruct, "move_to!", lps_move_to, 2);
  rb_define_method(cListPairStruct, "render", lps_render, 0);
  rb_define_method(cListPairStruct, "render_to",  lps_render_to,  1);
  rb_define_method(mSpriteArray, "sprite_only", sprite_array_sprite_only, 0);
  rb_define_method(mSpriteArray, "start", sprite_array_start, 0);
  rb_define_method(mSpriteArray, "stop", sprite_array_stop, 0);
  rb_define_method(mSpriteArray, "reset", sprite_array_reset, 0);
  rb_define_method(mSpriteArray, "update_animation", sprite_array_update_animation, 0);
  rb_define_method(mSpriteArray, "move!", sprite_array_move, 2);
  rb_define_method(mSpriteArray, "move_to!", sprite_array_move_to, 2);
  rb_define_method(mSpriteArray, "render", sprite_array_render, 0);
  rb_define_method(mSpriteArray, "render_to",  sprite_array_render_to,  1);
  rb_define_method(cSpriteList, "sprite_only", sprite_list_sprite_only, 0);
  rb_define_method(cSpriteList, "start", sprite_list_start, 0);
  rb_define_method(cSpriteList, "stop", sprite_list_stop, 0);
  rb_define_method(cSpriteList, "reset", sprite_list_reset, 0);
  rb_define_method(cSpriteList, "update_animation", sprite_list_update_animation, 0);
  rb_define_method(cSpriteList, "move!", sprite_list_move, 2);
  rb_define_method(cSpriteList, "move_to!", sprite_list_move_to, 2);
  rb_define_method(cSpriteList, "each", sprite_list_each, 0);
  rb_define_method(cSpriteList, "each_pair", sprite_list_each_pair, 0);
  rb_define_method(cSpriteList, "each_name", sprite_list_each_name, 0);
  rb_define_method(cSpriteList, "each_value", sprite_list_each_value, 0);
  rb_define_method(cSpriteList, "each_index", sprite_list_each_index, 0);
  rb_define_method(cSpriteList, "names", sprite_list_names, 0);
  rb_define_method(cSpriteList, "values", sprite_list_values, 0);
  rb_define_method(cSpriteList, "render", sprite_list_render, 0);
  rb_define_method(cSpriteList, "render_to",  sprite_list_render_to,  1);
}
