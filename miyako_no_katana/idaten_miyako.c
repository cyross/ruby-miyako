/* 
Miyako v2.0 Extend Library "Idaten Miyako"
Copyright (C) 2007-2008  Cyross Makoto

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
*/

#include <stdlib.h>
#include "ruby.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mInput = Qnil;
static VALUE mMapEvent = Qnil;
static VALUE mLayout = Qnil;
static VALUE mDiagram = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cSurface = Qnil;
static VALUE cEvent2 = Qnil;
static VALUE cJoystick = Qnil;
static VALUE cWaitCounter = Qnil;
static VALUE cColor = Qnil;
static VALUE cFont = Qnil;
static VALUE cSprite = Qnil;
static VALUE cSpriteAnimation = Qnil;
static VALUE cPlane = Qnil;
static VALUE cTextBox = Qnil;
static VALUE cMap = Qnil;
static VALUE cMapLayer = Qnil;
static VALUE cFixedMap = Qnil;
static VALUE cFixedMapLayer = Qnil;
static VALUE cCollision = Qnil;
static VALUE cCollisions = Qnil;
static VALUE cMovie = Qnil;
static VALUE cProcessor = Qnil;
static VALUE cYuki = Qnil;
static VALUE cThread = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

static VALUE sprite_update(VALUE self)
{
  VALUE update = rb_iv_get(self, "@update");
  
  if(update != Qnil){ rb_funcall(update, rb_intern("call"), 1, self); }
  if(rb_block_given_p() == Qtrue){ rb_yield(self); }

  return self;
}

static VALUE screen_update_tick(VALUE self)
{
  int t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
  int tt = NUM2INT(rb_iv_get(mScreen, "@@t"));
  int interval = t - tt;
  int fps_cnt = NUM2INT(rb_iv_get(mScreen, "@@fpscnt"));

  while(interval < fps_cnt){
    t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
    interval = t - tt;
  }

  rb_iv_set(mScreen, "@@t", INT2NUM(t));
  rb_iv_set(mScreen, "@@interval", INT2NUM(interval));

  return Qnil;
}

static VALUE screen_render(VALUE self)
{
  VALUE mvScreen = rb_iv_get(mScreen, "@@screen");
  VALUE fps_view = rb_iv_get(mScreen, "@@fpsView");

  if(fps_view == Qtrue){
    char str[256];
    int interval = NUM2INT(rb_iv_get(mScreen, "@@interval"));
    int fps_max = NUM2INT(rb_const_get(mScreen, rb_intern("FpsMax")));
    VALUE sans_serif = rb_funcall(cFont, rb_intern("sans_serif"), 0);
    VALUE fps_sprite = Qnil;

    if(interval == 0){ interval = 1; }

    sprintf(str, "%d fps", fps_max / interval);
    VALUE fps_str = rb_str_new2((const char *)str);
		
    fps_sprite = rb_funcall(fps_str, rb_intern("to_sprite"), 1, sans_serif);
    rb_funcall(fps_sprite, rb_intern("render"), 0);
  }

  rb_funcall(mScreen, rb_intern("update_tick"), 0, NULL);

  rb_funcall(mvScreen, rb_intern("flip"), 0, NULL);
  
  return Qnil;
}

static VALUE screen_render_screen1(VALUE unit)
{
  VALUE mvScreen = rb_iv_get(mScreen, "@@screen");
	VALUE bitmap   = *(RSTRUCT_PTR(unit) + 0);
	VALUE x        = INT2NUM(NUM2INT(*(RSTRUCT_PTR(unit) + 5)) + NUM2INT(*(RSTRUCT_PTR(unit) + 7)));
	VALUE y        = INT2NUM(NUM2INT(*(RSTRUCT_PTR(unit) + 6)) + NUM2INT(*(RSTRUCT_PTR(unit) + 8)));

  rb_funcall(cSurface, rb_intern("blit"), 8,
             bitmap,
             *(RSTRUCT_PTR(unit) + 1), *(RSTRUCT_PTR(unit) + 2),
             *(RSTRUCT_PTR(unit) + 3), *(RSTRUCT_PTR(unit) + 4),
             mvScreen, x, y);
  
  return Qtrue;
}

static VALUE screen_render_screen2(VALUE unit)
{
  return Qfalse;
}

static VALUE screen_render_screen(VALUE self, VALUE unit)
{
  while(1)
  {
    if(rb_rescue(screen_render_screen1, unit, screen_render_screen2, unit) == Qtrue)
      break;
  }
  
  return Qnil;
}

static VALUE screen_transform_screen1(VALUE unit)
{
  VALUE mvScreen = rb_iv_get(mScreen, "@@screen");
	VALUE bitmap   = *(RSTRUCT_PTR(unit) + 0);
	VALUE x        = INT2NUM(NUM2INT(*(RSTRUCT_PTR(unit) + 5))
                         + NUM2INT(*(RSTRUCT_PTR(unit) + 7))
                         + NUM2INT(*(RSTRUCT_PTR(unit) + 14)));
	VALUE y        = INT2NUM(NUM2INT(*(RSTRUCT_PTR(unit) + 6))
                         + NUM2INT(*(RSTRUCT_PTR(unit) + 8))
                         + NUM2INT(*(RSTRUCT_PTR(unit) + 15)));

  rb_funcall(cSurface, rb_intern("transform_blit"), 10,
             bitmap, mvScreen,
             *(RSTRUCT_PTR(unit) + 9),
             *(RSTRUCT_PTR(unit) + 10), *(RSTRUCT_PTR(unit) + 11),
             *(RSTRUCT_PTR(unit) + 12), *(RSTRUCT_PTR(unit) + 13),
             x, y, nZero);
  
  return Qtrue;
}

static VALUE screen_transform_screen(VALUE self, VALUE unit)
{
  while(1)
  {
    if(rb_rescue(screen_transform_screen1, unit, screen_render_screen2, unit) == Qtrue)
      break;
  }
  
  return Qnil;
}

static VALUE counter_start(VALUE self)
{
  rb_iv_set(self, "@st", rb_funcall(mSDL, rb_intern("getTicks"), 0));
  rb_iv_set(self, "@counting", Qtrue);
  return self;
}

static VALUE counter_stop(VALUE self)
{
  rb_iv_set(self, "@st", INT2NUM(0));
  rb_iv_set(self, "@counting", Qfalse);
  return self;
}

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

static VALUE counter_waiting(VALUE self)
{
  return counter_wait_inner(self, Qtrue);
}

static VALUE counter_finish(VALUE self)
{
  return counter_wait_inner(self, Qfalse);
}

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

static VALUE maplayer_render(int argc, VALUE *argv, VALUE self)
{
  VALUE mvScreen = rb_iv_get(mScreen, "@@screen");
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE pos = rb_iv_get(self, "@pos");
  VALUE margin = rb_iv_get(self, "@margin");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0)) + NUM2INT(*(RSTRUCT_PTR(margin) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1)) + NUM2INT(*(RSTRUCT_PTR(margin) + 1));

  VALUE size = rb_iv_get(self, "@size");
  int size_w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int size_h = NUM2INT(*(RSTRUCT_PTR(size) + 1));

  VALUE real_size = rb_iv_get(self, "@real_size");
  int real_size_w = NUM2INT(*(RSTRUCT_PTR(real_size) + 0));
  int real_size_h = NUM2INT(*(RSTRUCT_PTR(real_size) + 1));

  VALUE param = rb_iv_get(self, "@mapchip");
  VALUE mc_chip_size = *(RSTRUCT_PTR(param) + 3);
  int mc_chip_size_w = NUM2INT(*(RSTRUCT_PTR(mc_chip_size) + 0));
  int mc_chip_size_h = NUM2INT(*(RSTRUCT_PTR(mc_chip_size) + 1));

  VALUE munits = rb_iv_get(self, "@mapchip_units");
  VALUE mapdat = rb_iv_get(self, "@mapdat");
  
  if(pos_x < 0){ pos_x = real_size_w + (pos_x % real_size_w); }
  if(pos_y < 0){ pos_y = real_size_h + (pos_y % real_size_h); }
  if(pos_x >= real_size_w){ pos_x %= real_size_w; }
  if(pos_y >= real_size_h){ pos_y %= real_size_h; }

  int dx = pos_x / mc_chip_size_w;
  int mx = pos_x % mc_chip_size_w;
  int dy = pos_y / mc_chip_size_h;
  int my = pos_y % mc_chip_size_h;

  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      VALUE unit = rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0);
      *(RSTRUCT_PTR(unit) + 5) = INT2NUM(x * ow - mx);
      *(RSTRUCT_PTR(unit) + 6) = INT2NUM(y * oh - my);
      screen_render_screen(mvScreen, unit);
    }
  }
  return Qnil;
}

static VALUE fixedmaplayer_render(int argc, VALUE *argv, VALUE self)
{
  VALUE mvScreen = rb_iv_get(mScreen, "@@screen");
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE pos = rb_iv_get(self, "@pos");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

  VALUE size = rb_iv_get(self, "@size");
  int size_w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int size_h = NUM2INT(*(RSTRUCT_PTR(size) + 1));

  VALUE munits = rb_iv_get(self, "@mapchip_units");
  VALUE mapdat = rb_iv_get(self, "@mapdat");

  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = y % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      VALUE unit = rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0);
      *(RSTRUCT_PTR(unit) + 5) = INT2NUM(pos_x + x * ow);
      *(RSTRUCT_PTR(unit) + 6) = INT2NUM(pos_y + y * oh);
      screen_render_screen(mvScreen, unit);
    }
  }

  return Qnil;
}

static VALUE map_render(int argc, VALUE *argv, VALUE self)
{
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render(argc, argv, *(RARRAY_PTR(map_layers) + i));
  }
  
  return Qnil;
}

static VALUE fixedmap_render(int argc, VALUE *argv, VALUE self)
{
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render(argc, argv, *(RARRAY_PTR(map_layers) + i));
  }

  return Qnil;
}

static VALUE sa_update(VALUE self)
{
  VALUE exec = rb_iv_get(self, "@exec");
  if(exec == Qfalse){ return Qnil; }

  VALUE polist = rb_iv_get(self, "@pos_offset");
  VALUE dir = rb_iv_get(self, "@dir");
  
  VALUE now = rb_iv_get(self, "@now");
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE pos_off = *(RARRAY_PTR(polist) + NUM2INT(num));
  
  if(rb_to_id(dir) == rb_intern("h")){
    *(RSTRUCT_PTR(now) +  3) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  3)) - NUM2INT(pos_off));
  }
  else{
    *(RSTRUCT_PTR(now) +  2) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  2)) - NUM2INT(pos_off));
  }

  VALUE kind = rb_funcall(rb_iv_get(self, "@cnt"), rb_intern("kind_of?"), 1, rb_cInteger);
  if(kind == Qtrue){
    rb_funcall(self, rb_intern("update_frame"), 0);
  }
  else{
    rb_funcall(self, rb_intern("update_wait_counter"), 0);
  }
  
  now = rb_iv_get(self, "@now");
  num = rb_iv_get(self, "@pnum");

  VALUE slist = rb_iv_get(self, "@slist");
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE molist = rb_iv_get(self, "@move_offset");

  VALUE s = *(RARRAY_PTR(slist) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num))));
  VALUE move_off = *(RARRAY_PTR(molist) + NUM2INT(num));

  *(RSTRUCT_PTR(now) + 5) = INT2NUM(NUM2INT(rb_funcall(s, rb_intern("x"), 0)) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nZero)));
  *(RSTRUCT_PTR(now) + 6) = INT2NUM(NUM2INT(rb_funcall(s, rb_intern("y"), 0)) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nOne)));

  pos_off = *(RARRAY_PTR(polist) + NUM2INT(num));
  
  if(rb_to_id(dir) == rb_intern("h")){
    *(RSTRUCT_PTR(now) +  2) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  2)) + NUM2INT(pos_off));
  }
  else{
    *(RSTRUCT_PTR(now) +  1) = INT2NUM(NUM2INT(*(RSTRUCT_PTR(now) +  1)) + NUM2INT(pos_off));
  }

  return Qnil;
}

static VALUE sa_update_frame(VALUE self)
{
  int cnt = NUM2INT(rb_iv_get(self, "@cnt"));
  if(cnt == 0){
    VALUE num = rb_iv_get(self, "@pnum");
    VALUE loop = rb_iv_get(self, "@loop");

    int pnum = NUM2INT(num);
    int pats = NUM2INT(rb_iv_get(self, "@pats"));
    pnum = (pnum + 1) % pats;

    rb_iv_set(self, "@pnum", INT2NUM(pnum));

    if(loop == Qfalse && pnum == 0){
      rb_funcall(self, rb_intern("stop"), 0);
      return Qnil;
    }

    rb_funcall(self, rb_intern("set_pat"), 0);
    VALUE plist = rb_iv_get(self, "@plist");
    VALUE waits = rb_iv_get(self, "@waits");
    rb_iv_set(self, "@cnt", *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum))));
  }
  else{
    cnt--;
    rb_iv_set(self, "@cnt", INT2NUM(cnt));
  }
  return Qnil;
}

static VALUE sa_update_wait_counter(VALUE self)
{
  VALUE cnt = rb_iv_get(self, "@cnt");
  VALUE waiting = rb_funcall(cnt, rb_intern("waiting?"), 0);
  if(waiting == Qfalse){
    VALUE num = rb_iv_get(self, "@pnum");
    VALUE loop = rb_iv_get(self, "@loop");

    int pnum = NUM2INT(num);
    int pats = NUM2INT(rb_iv_get(self, "@pats"));
    pnum = (pnum + 1) % pats;
    
    rb_iv_set(self, "@pnum", INT2NUM(pnum));
    
    if(loop == Qfalse && pnum == 0){
      rb_funcall(self, rb_intern("stop"), 0);
      return Qnil;
    }

    rb_funcall(self, rb_intern("set_pat"), 0);
    VALUE plist = rb_iv_get(self, "@plist");
    VALUE waits = rb_iv_get(self, "@waits");
    cnt = *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum)));
    rb_iv_set(self, "@cnt", cnt);
    rb_funcall(cnt, rb_intern("start"), 0);
  }
  return Qnil;
}

static VALUE sa_set_pat(VALUE self)
{
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE units = rb_iv_get(self, "@units");
  rb_iv_set(self, "@now", *(RARRAY_PTR(units) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num)))));
  return self;
}

static VALUE plane_render(int argc, VALUE *argv, VALUE self)
{
  VALUE mvScreen = rb_iv_get(mScreen, "@@screen");
  VALUE pos = rb_iv_get(self, "@pos");
  VALUE size = rb_iv_get(self, "@size");
  VALUE sprite = rb_iv_get(self, "@sprite");

  int w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));
  int sw = NUM2INT(rb_funcall(sprite, rb_intern("w"), 0));
  int sh = NUM2INT(rb_funcall(sprite, rb_intern("h"), 0));

  int x, y;
  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      VALUE unit = rb_funcall(sprite, rb_intern("to_unit"), 0);
      *(RSTRUCT_PTR(unit) + 5) = INT2NUM((x-1) * sw + pos_x);
      *(RSTRUCT_PTR(unit) + 6) = INT2NUM((y-1) * sh + pos_y);
      screen_render_screen(mvScreen, unit);
    }
  }
  
  return Qnil;
}

static VALUE collision_c_collision(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2))) - 1;
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3))) - 1;
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2))) - 1;
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3))) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_collision_with_move(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  VALUE dir1 = rb_funcall(c1, rb_intern("direction"), 0);
  VALUE dir2 = rb_funcall(c2, rb_intern("direction"), 0);
  VALUE amt1 = rb_funcall(c1, rb_intern("amount"), 0);
  VALUE amt2 = rb_funcall(c2, rb_intern("amount"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(dir1, id_kakko, 1, nZero))
    * NUM2INT(rb_funcall(amt1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(dir1, id_kakko, 1, nOne))
    * NUM2INT(rb_funcall(amt1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2))) - 1;
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3))) - 1;
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(dir2, id_kakko, 1, nZero))
    * NUM2INT(rb_funcall(amt2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(dir2, id_kakko, 1, nOne))
    * NUM2INT(rb_funcall(amt2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2))) - 1;
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3))) - 1;

  int v = 0;
  if(l1 <= l2 && l2 <= r1) v |= 1;
  if(l1 <= r2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && t2 <= b1) v |= 2;
  if(t1 <= b2 && b2 <= b1) v |= 2;

  if(v == 3) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_meet(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2)));
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3)));
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2)));
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3)));

  int v = 0;
  if(r1 == l2) v |= 1;
  if(b1 == t2) v |= 1;
  if(l1 == r2) v |= 1;
  if(t1 == b2) v |= 1;

  if(v == 1) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_into(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qfalse && f2 == Qtrue) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_out(VALUE self, VALUE c1, VALUE c2)
{
  VALUE f1 = collision_c_collision(self, c1, c2);
  VALUE f2 = collision_c_collision_with_move(self, c1, c2);
  if(f1 == Qtrue && f2 == Qfalse) return Qtrue;
  return Qfalse;
}

static VALUE collision_c_cover(VALUE self, VALUE c1, VALUE c2)
{
  VALUE rect1 = rb_funcall(c1, rb_intern("rect"), 0);
  VALUE rect2 = rb_funcall(c2, rb_intern("rect"), 0);
  VALUE pos1 = rb_funcall(c1, rb_intern("pos"), 0);
  VALUE pos2 = rb_funcall(c2, rb_intern("pos"), 0);
  int l1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nZero));
  int t1 = NUM2INT(rb_funcall(pos1, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect1, id_kakko, 1, nOne));
  int r1 = l1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(2))) - 1;
  int b1 = t1 + NUM2INT(rb_funcall(rect1, id_kakko, 1, INT2NUM(3))) - 1;
  int l2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nZero))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nZero));
  int t2 = NUM2INT(rb_funcall(pos2, id_kakko, 1, nOne))
    + NUM2INT(rb_funcall(rect2, id_kakko, 1, nOne));
  int r2 = l2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(2))) - 1;
  int b2 = t2 + NUM2INT(rb_funcall(rect2, id_kakko, 1, INT2NUM(3))) - 1;

  int v = 0;
  if(l1 <= l2 && r2 <= r1) v |= 1;
  if(t1 <= t2 && b2 <= b1) v |= 2;
  if(l2 <= l1 && r1 <= r2) v |= 4;
  if(t2 <= t1 && b1 <= b2) v |= 8;

  if(v == 3 || v == 12) return Qtrue;
  return Qfalse;
}

static VALUE collision_collision(VALUE self, VALUE c2)
{
  return collision_c_collision(cCollision, self, c2);
}

static VALUE collision_meet(VALUE self, VALUE c2)
{
  return collision_c_meet(cCollision, self, c2);
}

static VALUE collision_into(VALUE self, VALUE c2)
{
  return collision_c_into(cCollision, self, c2);
}

static VALUE collision_out(VALUE self, VALUE c2)
{
  return collision_c_out(cCollision, self, c2);
}

static VALUE collision_cover(VALUE self, VALUE c2)
{
  return collision_c_cover(cCollision, self, c2);
}

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

static VALUE processor_mainloop(VALUE self)
{
  VALUE diagram = rb_iv_get(self, "@diagram");
  VALUE states = rb_iv_get(self, "@states");
  VALUE mutex = rb_iv_get(self, "@mutex");
  VALUE str_execute = rb_str_new2("execute");
  VALUE sym_execute = rb_funcall(str_execute, rb_intern("to_sym"), 0);
  VALUE str_pause = rb_str_new2("pause");
  VALUE sym_pause = rb_funcall(str_pause, rb_intern("to_sym"), 0);
  rb_funcall(diagram, rb_intern("start"), 0);
  VALUE executing = rb_funcall(states, id_kakko, 1, sym_execute);
  while(executing == Qtrue){
    VALUE pausing = rb_funcall(states, id_kakko, 1, sym_pause);
    if(pausing == Qfalse){
        rb_funcall(mutex, rb_intern("lock"), 0);
        rb_funcall(diagram, id_update, 0);
        rb_funcall(mutex, rb_intern("unlock"), 0);
        rb_funcall(cThread, rb_intern("pass"), 0);
        VALUE is_finish = rb_funcall(diagram, rb_intern("finish?"), 0);
        if(is_finish == Qtrue){ rb_funcall(states, rb_intern("[]="), 2, sym_execute, Qfalse); }
    }
    executing = rb_funcall(states, id_kakko, 1, sym_execute);
  }
  rb_funcall(diagram, rb_intern("stop"), 0);
  return self;
}

static VALUE yuki_update_plot_thread(VALUE self)
{
  VALUE yuki = rb_iv_get(self, "@yuki");
  VALUE str_exec = rb_str_new2("exec_plot");
  VALUE sym_exec = rb_funcall(str_exec, rb_intern("to_sym"), 0);
  VALUE str_pausing = rb_str_new2("pausing");
  VALUE sym_pausing = rb_funcall(str_pausing, rb_intern("to_sym"), 0);
  VALUE str_selecting = rb_str_new2("exec_selecting");
  VALUE sym_selecting = rb_funcall(str_selecting, rb_intern("to_sym"), 0);
  VALUE str_waiting = rb_str_new2("waiting");
  VALUE sym_waiting = rb_funcall(str_waiting, rb_intern("to_sym"), 0);
  VALUE exec = rb_funcall(yuki, id_kakko, 1, sym_exec);
  while(exec == Qtrue){
    VALUE pausing   = rb_funcall(yuki, id_kakko, 1, sym_pausing);
    if(pausing == Qtrue){ rb_funcall(self, rb_intern("pausing"), 0); }
    VALUE selecting = rb_funcall(yuki, id_kakko, 1, sym_selecting);
    if(selecting == Qtrue){ rb_funcall(self, rb_intern("selecting"), 0); }
    VALUE waiting   = rb_funcall(yuki, id_kakko, 1, sym_waiting);
    if(waiting == Qtrue){ rb_funcall(self, rb_intern("waiting"), 0); }
    rb_funcall(cThread, rb_intern("pass"), 0);
    exec = rb_funcall(yuki, id_kakko, 1, sym_exec);
  }
  return self;
}

void Init_idaten_miyako()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  mInput = rb_define_module_under(mMiyako, "Input");
  mMapEvent = rb_define_module_under(mMiyako, "MapEvent");
  mLayout = rb_define_module_under(mMiyako, "Layout");
  mDiagram = rb_define_module_under(mMiyako, "Diagram");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cEvent2  = rb_define_class_under(mSDL, "Event2", rb_cObject);
  cJoystick  = rb_define_class_under(mSDL, "Joystick", rb_cObject);
  cWaitCounter  = rb_define_class_under(mMiyako, "WaitCounter", rb_cObject);
  cFont  = rb_define_class_under(mMiyako, "Font", rb_cObject);
  cColor  = rb_define_class_under(mMiyako, "Color", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);
  cSpriteAnimation = rb_define_class_under(mMiyako, "SpriteAnimation", rb_cObject);
  cPlane = rb_define_class_under(mMiyako, "Plane", rb_cObject);
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

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_module_function(mScreen, "update_tick", screen_update_tick, 0);
  rb_define_module_function(mScreen, "render", screen_render, 0);
  rb_define_module_function(mScreen, "render_screen", screen_render_screen, 1);
  rb_define_module_function(mScreen, "transform_screen", screen_transform_screen, 1);

  rb_define_method(cWaitCounter, "start", counter_start, 0);
  rb_define_method(cWaitCounter, "stop",  counter_stop,  0);
  rb_define_method(cWaitCounter, "wait_inner", counter_wait_inner, 1);
  rb_define_method(cWaitCounter, "waiting?", counter_waiting, 0);
  rb_define_method(cWaitCounter, "finish?", counter_finish, 0);
  rb_define_method(cWaitCounter, "wait", counter_wait, 0);

  rb_define_method(cSpriteAnimation, "update_animation", sa_update, 0);
  rb_define_method(cSpriteAnimation, "update_frame", sa_update_frame, 0);
  rb_define_method(cSpriteAnimation, "update_wait_counter", sa_update_wait_counter, 0);
  rb_define_method(cSpriteAnimation, "set_pat", sa_set_pat, 0);

  rb_define_method(cPlane, "render", plane_render, -1);

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

  rb_define_method(cProcessor, "main_loop", processor_mainloop, 0);
  rb_define_method(cYuki, "update_plot_thread", yuki_update_plot_thread, 0);
  
  rb_define_method(cMapLayer, "render", maplayer_render, -1);
  rb_define_method(cFixedMapLayer, "render", fixedmaplayer_render, -1);
  rb_define_method(cMap, "render", map_render, -1);
  rb_define_method(cFixedMap, "render", fixedmap_render, -1);
}
