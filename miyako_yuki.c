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
#include "extern.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE cYuki = Qnil;
static VALUE cIYuki = Qnil;
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
static volatile ID id_executing = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_update_input = Qnil;
static volatile ID id_update_inner = Qnil;
static volatile ID id_update_input_inner = Qnil;
static volatile ID id_update_animation_inner = Qnil;
static volatile ID id_render_inner = Qnil;
static volatile ID id_render_to_inner = Qnil;
static volatile int zero = 0;
static volatile int one = 1;
static const char *str_visible = "@visible";
static const char *str_visibles = "@visibles";
static const char *str_o_yuki = "@over_yuki";
static const char *str_executing = "@executing";

/*
:nodoc:
*/
static VALUE yuki_is_exec(VALUE self)
{
  return rb_iv_get(self, str_executing);
}

/*
:nodoc:
*/
static VALUE yuki_ua(VALUE self)
{
  _miyako_sprite_list_update_animation(rb_iv_get(self, str_visibles));
  VALUE over_yuki = rb_iv_get(self, str_o_yuki);
  if(over_yuki == Qnil) return self;
  if(yuki_is_exec(self) == Qtrue){
    yuki_ua(over_yuki);
  }
  return self;
}

/*
:nodoc:
*/
static VALUE yuki_render(VALUE self)
{
  if(rb_iv_get(self, str_visible) == Qtrue){
    _miyako_sprite_list_render(rb_iv_get(self, str_visibles));
  }
  VALUE over_yuki = rb_iv_get(self, str_o_yuki);
  if(over_yuki == Qnil) return self;
  if(yuki_is_exec(self) == Qtrue){
    yuki_render(over_yuki);
  }
  return self;
}

/*
:nodoc:
*/
static VALUE yuki_render_to(VALUE self, VALUE dst)
{
  if(rb_iv_get(self, str_visible) == Qtrue){
    _miyako_sprite_list_render_to(rb_iv_get(self, str_visibles), dst);
  }
  VALUE over_yuki = rb_iv_get(self, str_o_yuki);
  if(over_yuki == Qnil) return self;
  if(yuki_is_exec(self) == Qtrue){
    yuki_render_to(over_yuki, dst);
  }
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_pre_process(VALUE self)
{
  _miyako_audio_update();
  _miyako_input_update();
  rb_funcall(self, id_update_input, 0);
  rb_funcall(self, id_update, 0);
  rb_funcall(self, id_update_animation, 0);
  _miyako_screen_clear();
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_post_process(VALUE self)
{
  rb_funcall(self, id_render, 0);
  _miyako_screen_render();
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_update(VALUE self)
{
  rb_funcall(self, id_update_inner, 1, self);
  rb_iv_set(self, "@pause_release", Qfalse);
  rb_iv_set(self, "@select_ok", Qfalse);
  rb_iv_set(self, "@select_cansel", Qfalse);
  VALUE amt = rb_iv_get(self, "@select_amount");
  *(RARRAY_PTR(amt)+0) = nZero;
  *(RARRAY_PTR(amt)+1) = nZero;
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_update_input(VALUE self)
{
  rb_funcall(self, id_update_input_inner, 1, self);
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_ua(VALUE self)
{
  rb_funcall(self, id_update_animation_inner, 1, self);
  _miyako_sprite_list_update_animation(rb_iv_get(self, str_visibles));
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_render(VALUE self)
{
  if(rb_iv_get(self, str_visible) == Qtrue){
    _miyako_sprite_list_render(rb_iv_get(self, str_visibles));
  }
  rb_funcall(self, id_render_inner, 1, self);
  return self;
}

/*
:nodoc:
*/
static VALUE iyuki_render_to(VALUE self, VALUE dst)
{
  if(rb_iv_get(self, str_visible) == Qtrue){
    _miyako_sprite_list_render_to(rb_iv_get(self, str_visibles), dst);
  }
  rb_funcall(self, id_render_to_inner, 2, self, dst);
  return self;
}

void Init_miyako_yuki()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  cYuki = rb_define_class_under(mMiyako, "Yuki", rb_cObject);
  cIYuki = rb_define_class_under(mMiyako, "InitiativeYuki", rb_cObject);

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
  id_executing = rb_intern("executing?");
  id_update = rb_intern("update");
  id_update_input = rb_intern("update_input");
  id_update_inner = rb_intern("update_inner");
  id_update_input_inner = rb_intern("input_inner");
  id_update_animation_inner = rb_intern("update_animation_inner");
  id_render_inner = rb_intern("render_inner");
  id_render_to_inner = rb_intern("render_to_inner");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_method(cYuki, "executing?",  yuki_is_exec,  0);
  rb_define_method(cYuki, "update_animation",  yuki_ua,  0);
  rb_define_method(cYuki, "render",  yuki_render,  0);
  rb_define_method(cYuki, "render_to",  yuki_render_to,  1);
  rb_define_method(cIYuki, "pre_process",  iyuki_pre_process,  0);
  rb_define_method(cIYuki, "post_process",  iyuki_post_process,  0);
  rb_define_method(cIYuki, "update",  iyuki_update,  0);
  rb_define_method(cIYuki, "update_input",  iyuki_update_input,  0);
  rb_define_method(cIYuki, "update_animation",  iyuki_ua,  0);
  rb_define_method(cIYuki, "render",  iyuki_render,  0);
  rb_define_method(cIYuki, "render_to",  iyuki_render_to,  1);
}
