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

static VALUE mMiyako = Qnil;
static VALUE mDiagram = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cDiagramBody = Qnil;
static VALUE cManager = Qnil;
static VALUE cProcessor = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static VALUE symExecute = Qnil;
static VALUE symPause = Qnil;
static VALUE symImm = Qnil;
static VALUE symNext = Qnil;
static volatile ID id_start        = Qnil;
static volatile ID id_stop         = Qnil;
static volatile ID id_finish       = Qnil;
static volatile ID id_update       = Qnil;
static volatile ID id_update_input = Qnil;
static volatile ID id_render       = Qnil;
static volatile ID id_render_to    = Qnil;
static volatile ID id_post_render  = Qnil;
static volatile ID id_is_render    = Qnil;
static volatile ID id_go_next      = Qnil;
static volatile ID id_is_update    = Qnil;
static volatile ID id_post_update  = Qnil;
static volatile ID id_reset_input  = Qnil;
static volatile ID id_trigger      = Qnil;
static volatile ID id_to           = Qnil;
static volatile ID id_post_process = Qnil;
static volatile ID id_pre_process  = Qnil;
static volatile int zero         = Qnil;
static volatile int one          = Qnil;
static const char *str_visible       = "@visible";
static const char *str_diagram       = "@diagram";
static const char *str_states        = "@states";
static const char *str_ptr           = "@ptr";
static const char *str_node          = "@node";
static const char *str_trigger       = "@trigger";
static const char *str_next_trigger  = "@next_trigger";
static const char *str_arrow         = "@arrow";

/*
:nodoc:
*/
static VALUE dbody_update_input(int argc, VALUE *argv, VALUE self)
{
  VALUE params;
  rb_scan_args(argc, argv, "00*", &params);

  VALUE node = rb_iv_get(self, str_node);
  if(node == Qnil) return Qnil;
  rb_funcall2(node, id_update_input, argc, argv);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE dbody_update(int argc, VALUE *argv, VALUE self)
{
  VALUE params;
  rb_scan_args(argc, argv, "00*", &params);

  VALUE trigger = rb_iv_get(self, str_trigger);
  if(rb_funcall(trigger, id_is_update, 0) == Qfalse) return Qnil;

  VALUE node = rb_iv_get(self, str_node);
  rb_funcall2(node, id_update, argc, argv);
  rb_funcall(trigger, id_post_update, 0);
  rb_funcall(node, id_reset_input, 0);

  VALUE ntrigger = rb_iv_get(self, str_next_trigger);

  if(ntrigger == Qnil) return Qnil;

  rb_iv_set(self, str_trigger, ntrigger);
  rb_iv_set(self, str_next_trigger, Qnil);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE dbody_render(VALUE self)
{
  VALUE trigger = rb_iv_get(self, str_trigger);
  if(rb_funcall(trigger, id_is_render, 0) == Qfalse) return Qnil;
  VALUE node = rb_iv_get(self, str_node);
  rb_funcall(node, id_render, 0);
  rb_funcall(trigger, id_post_render, 0);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE dbody_go_next(VALUE self)
{
  VALUE next_obj = self;
  VALUE arrows = rb_iv_get(self, str_arrow);
  VALUE *arrows_p = RARRAY_PTR(arrows);
  VALUE node = rb_iv_get(self, str_node);
  VALUE call_arg = rb_ary_new();
  rb_ary_push(call_arg, node);
  int i;
  for(i=0;i<RARRAY_LEN(arrows);i++)
  {
    VALUE arrow = *(arrows_p+i);
    VALUE trigger = rb_funcall(arrow, id_trigger, 0);
    if((trigger != Qnil && rb_proc_call(trigger, call_arg)) || rb_funcall(node, id_finish, 0))
    {
      next_obj = rb_funcall(arrow, id_to, 0);
      break;
    }
  }
  if(!rb_eql(self, next_obj)){
    VALUE trigger = rb_iv_get(self, str_trigger);
    rb_funcall(trigger, id_post_process, 0);
  }
  return next_obj;
}

/*
:nodoc:
*/
static VALUE dbody_replace_trigger(int argc, VALUE *argv, VALUE self)
{
  VALUE new_trigger;
  VALUE timing;
  rb_scan_args(argc, argv, "11", &new_trigger, &timing);
  if(timing == Qnil) timing = symNext;
  else if(timing != symImm || timing != symNext)
  {
    char str[256];
    VALUE timing_str = StringValue(timing);
    sprintf(str, "I can't understand Timing Type! : %s", rb_string_value_ptr(&timing_str));
    rb_raise(eMiyakoError, str);
  }
  if(timing == symImm)
  {
    VALUE trigger = rb_iv_get(self, str_trigger);
    rb_funcall(trigger, id_post_process, 0);
    rb_iv_set(self, str_trigger, new_trigger);
    rb_funcall(trigger, id_pre_process, 0);

  }
  else if(timing == symNext)
  {
    rb_iv_set(self, str_next_trigger, new_trigger);
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE manager_update_input(int argc, VALUE *argv, VALUE self)
{
  VALUE params;
  rb_scan_args(argc, argv, "00*", &params);

  VALUE ptr = rb_iv_get(self, str_ptr);
  if(ptr == Qnil) return Qnil;
  dbody_update_input(argc, argv, ptr);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE manager_update(int argc, VALUE *argv, VALUE self)
{
  VALUE params;
  rb_scan_args(argc, argv, "00*", &params);

  VALUE ptr = rb_iv_get(self, str_ptr);
  if(ptr == Qnil) return Qnil;

  dbody_update(argc, argv, ptr);

  VALUE nxt = rb_funcall(ptr, id_go_next, 0);

  if(!rb_eql(ptr, nxt))
  {
    rb_funcall(ptr, id_stop, 0);
    rb_iv_set(self, str_ptr, nxt);
    ptr = rb_iv_get(self, str_ptr);
    if(ptr != Qnil) rb_funcall(ptr, id_start, 0);
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE manager_render(VALUE self)
{
  VALUE ptr = rb_iv_get(self, str_ptr);
  if(ptr == Qnil) return Qnil;
  dbody_render(ptr);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE processor_update_input(int argc, VALUE *argv, VALUE self)
{
  VALUE params;
  rb_scan_args(argc, argv, "00*", &params);

  VALUE states = rb_iv_get(self, str_states);
  if(rb_hash_lookup(states, symPause) == Qtrue) return Qnil;

  VALUE diagram = rb_iv_get(self, str_diagram);
  manager_update_input(argc, argv, diagram);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE processor_update(int argc, VALUE *argv, VALUE self)
{
  VALUE params;
  rb_scan_args(argc, argv, "00*", &params);

  VALUE states = rb_iv_get(self, str_states);

  if(rb_hash_lookup(states, symPause) == Qtrue) return Qnil;

  VALUE diagram = rb_iv_get(self, str_diagram);
  manager_update(argc, argv, diagram);

  if(rb_funcall(diagram, id_finish, 0) == Qtrue){
    rb_hash_aset(states, symExecute, Qfalse);
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE processor_render(VALUE self)
{
  if(rb_iv_get(self, str_visible) == Qfalse) return Qnil;
  manager_render(rb_iv_get(self, str_diagram));
  return Qnil;
}

void Init_miyako_diagram()
{
  mMiyako = rb_define_module("Miyako");
  mDiagram = rb_define_module_under(mMiyako, "Diagram");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cProcessor = rb_define_class_under(mDiagram, "Processor", rb_cObject);
  cManager = rb_define_class_under(mDiagram, "Manager", rb_cObject);
  cDiagramBody = rb_define_class_under(mDiagram, "DiagramBody", rb_cObject);

  id_start        = rb_intern("start");
  id_stop         = rb_intern("stop");
  id_finish       = rb_intern("finish?");
  id_update       = rb_intern("update");
  id_update_input = rb_intern("update_input");
  id_render       = rb_intern("render");
  id_render_to    = rb_intern("render_to");
  id_post_render  = rb_intern("post_render");
  id_is_render    = rb_intern("render?");
  id_go_next      = rb_intern("go_next");
  id_is_update    = rb_intern("update?");
  id_post_update  = rb_intern("post_update");
  id_reset_input  = rb_intern("reset_input");
  id_trigger      = rb_intern("trigger");
  id_to           = rb_intern("to");
  id_post_process = rb_intern("post_process");
  id_pre_process  = rb_intern("pre_process");

  symExecute    = ID2SYM(rb_intern("execute"));
  symPause      = ID2SYM(rb_intern("pause"));
  symImm        = ID2SYM(rb_intern("immediate"));
  symNext       = ID2SYM(rb_intern("next"));

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_method(cDiagramBody, "update_input", dbody_update_input, -1);
  rb_define_method(cDiagramBody, "update", dbody_update, -1);
  rb_define_method(cDiagramBody, "render", dbody_render, 0);
  rb_define_method(cDiagramBody, "go_next", dbody_go_next, 0);
  rb_define_method(cDiagramBody, "replace_trigger", dbody_replace_trigger, -1);

  rb_define_method(cManager, "update_input", manager_update_input, -1);
  rb_define_method(cManager, "update", manager_update, -1);
  rb_define_method(cManager, "render", manager_render, 0);

  rb_define_method(cProcessor, "update_input", processor_update_input, -1);
  rb_define_method(cProcessor, "update", processor_update, -1);
  rb_define_method(cProcessor, "render", processor_render, 0);
}
