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

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mDiagram = Qnil;
static VALUE cSurface = Qnil;
static VALUE cGL = Qnil;
static VALUE cFont = Qnil;
static VALUE cThread = Qnil;
static VALUE cSprite = Qnil;
static VALUE cSpriteAnimation = Qnil;
static VALUE cPlane = Qnil;
static VALUE cParts = Qnil;
static VALUE cMap = Qnil;
static VALUE cMapLayer = Qnil;
static VALUE cFixedMap = Qnil;
static VALUE cFixedMapLayer = Qnil;
static VALUE cProcessor = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

// from rubysdl_video.c
static GLOBAL_DEFINE_GET_STRUCT(Surface, GetSurface, cSurface, "SDL::Surface");

static VALUE use_opengl = Qnil;

extern void Init_miyako_bitmap();
extern void Init_miyako_transform();
extern void Init_miyako_hsv();
extern void Init_miyako_drawing();
extern void Init_miyako_layout();
extern void Init_miyako_collision();
extern void Init_miyako_basicdata();
extern void Init_miyako_font();
extern void Init_miyako_utility();

/*
===内部用レンダメソッド
*/
static void render_to_inner(MiyakoBitmap *sb, MiyakoBitmap *db)
{
	if(sb->ptr == db->ptr){ return; }
	
	MiyakoSize size;
  if(_miyako_init_rect(sb, db, &size) == 0) return;
	
	SDL_LockSurface(sb->surface);
	SDL_LockSurface(db->surface);
  
	int x, y;
	for(y = 0; y < size.h; y++)
	{
    Uint32 *psrc = sb->ptr + (sb->rect.y         + y) * sb->surface->w + sb->rect.x;
    Uint32 *pdst = db->ptr + (db->rect.y + sb->y + y) * db->surface->w + db->rect.x + sb->x;
		for(x = 0; x < size.w; x++)
		{
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      sb->color.a = (*psrc >> 24) & 0xff | sb->a255;
      if(sb->color.a == 0){ psrc++; pdst++; continue; }
      db->color.a = (*pdst >> 24) & 0xff | db->a255;
      if(db->color.a == 0 || sb->color.a == 255){
        *pdst = *psrc | (sb->a255 << 24);
        psrc++;
        pdst++;
        continue;
      }
      int a1 = sb->color.a + 1;
      int a2 = 256 - sb->color.a;
      sb->color.r = (*psrc >> 16) & 0xff;
      sb->color.g = (*psrc >>  8) & 0xff;
      sb->color.b = (*psrc      ) & 0xff;
      db->color.r = (*pdst >> 16) & 0xff;
      db->color.g = (*pdst >>  8) & 0xff;
      db->color.b = (*pdst      ) & 0xff;
			*pdst = ((sb->color.r * a1 + db->color.r * a2) >> 8) << 16 |
						  ((sb->color.g * a1 + db->color.g * a2) >> 8) <<  8 |
							((sb->color.b * a1 + db->color.b * a2) >> 8)       |
							0xff << 24;
#else
      sb->color.a = (*psrc & sb->fmt->Amask) | sb->a255;
      if(sb->color.a == 0){ psrc++; pdst++; continue; }
      db->color.a = (*pdst & db->fmt->Amask) | db->a255;
      if(db->color.a == 0 || sb->color.a == 255){
        *pdst = *psrc | sb->a255;
        psrc++;
        pdst++;
        continue;
      }
      int a1 = sb->color.a + 1;
      int a2 = 256 - sb->color.a;
      sb->color.r = (*psrc & sb->fmt->Rmask) >> sb->fmt->Rshift;
      sb->color.g = (*psrc & sb->fmt->Gmask) >> sb->fmt->Gshift;
      sb->color.b = (*psrc & sb->fmt->Bmask) >> sb->fmt->Bshift;
      db->color.r = (*pdst & db->fmt->Rmask) >> db->fmt->Rshift;
      db->color.g = (*pdst & db->fmt->Gmask) >> db->fmt->Gshift;
      db->color.b = (*pdst & db->fmt->Bmask) >> db->fmt->Bshift;
			*pdst = ((sb->color.r * a1 + db->color.r * a2) >> 8) << db->fmt->Rshift |
						  ((sb->color.g * a1 + db->color.g * a2) >> 8) << db->fmt->Gshift |
							((sb->color.b * a1 + db->color.b * a2) >> 8) << db->fmt->Bshift |
							0xff;
#endif
      psrc++;
      pdst++;
    }
  }

	SDL_UnlockSurface(sb->surface);
	SDL_UnlockSurface(db->surface);
}

/*
===内部用レンダメソッド
*/
static void render_inner(MiyakoBitmap *sb, MiyakoBitmap *db)
{
	db->rect.x += sb->x;
	db->rect.y += sb->y;
  SDL_BlitSurface(sb->surface, &(sb->rect), db->surface, &(db->rect));
}

/*
インスタンスの内容を別のインスタンスに描画する
*/
static VALUE sprite_c_render_to_sprite(VALUE self, VALUE vsrc, VALUE vdst)
{
	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  render_to_inner(&src, &dst);
  return self;
}

/*
インスタンスの内容を画面に描画する
*/
static VALUE sprite_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, mScreen, scr, &src, &dst, Qnil, Qnil, 1);
  render_inner(&src, &dst);
  return self;
}

/*
インスタンスの内容を別のインスタンスに描画する
*/
static VALUE sprite_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  render_to_inner(&src, &dst);
  return self;
}

/*
:nodoc:
*/
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

/*
:nodoc:
*/
static VALUE render_auto_render_array(VALUE array)
{
  int len = RARRAY_LEN(array);
  if(len == 0){ return Qnil; }
  VALUE *ptr = RARRAY_PTR(array);

  int i;
  for(i=0; i<len; i++)
  {
    VALUE v = *ptr;
    if(v == Qnil)
    {
      ptr++;
      continue;
    }
    else if(TYPE(v) == T_ARRAY)
    {
      render_auto_render_array(v);
    }
    else
    {
      rb_funcall(v, id_render, 0);
    }
    ptr++;
  }
  
  return Qnil;
}

/*
:nodoc:
*/
static VALUE screen_pre_render(VALUE self)
{
  VALUE pre_render_array = rb_iv_get(mScreen, "@@pre_render_array");
  if(RARRAY_LEN(pre_render_array) > 0)
  {
    render_auto_render_array(pre_render_array);
  }
  return Qnil;
}

/*
画面を更新する
*/
static VALUE screen_render(VALUE self)
{
  VALUE dst = rb_iv_get(mScreen, "@@unit");
	SDL_Surface *pdst = GetSurface(*(RSTRUCT_PTR(dst)))->surface;
  VALUE fps_view = rb_iv_get(mScreen, "@@fpsView");
  
  VALUE auto_render_array = rb_iv_get(mScreen, "@@auto_render_array");
  if(RARRAY_LEN(auto_render_array) > 0)
  {
    render_auto_render_array(auto_render_array);
  }
  
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
    sprite_render(fps_sprite);
  }

  screen_update_tick(self);

  if(use_opengl == Qfalse)
  {
    SDL_Flip(pdst);
    return Qnil;
  }
  rb_funcall(cGL, rb_intern("swap_buffers"), 0);
  
  return Qnil;
}

/*
インスタンスの内容を画面に描画する
*/
static VALUE screen_render_screen(VALUE self, VALUE vsrc)
{
	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(vsrc, mScreen, scr, &src, &dst, Qnil, Qnil, 1);
  render_inner(&src, &dst);
  return self;
}


/*
===マップレイヤー転送インナーメソッド
*/
static void maplayer_render_inner(VALUE self, MiyakoBitmap *dst)
{
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE margin = rb_iv_get(self, "@pos");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(margin) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(margin) + 1));

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

  MiyakoBitmap src;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  
  int bx = dst->rect.x;
  int by = dst->rect.y;
  
  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      _miyako_setup_unit(
			  rb_funcall(*(RARRAY_PTR(munits) + code),
                   rb_intern("to_unit"), 0),
        scr, &src, 
        INT2NUM(x * ow - mx), INT2NUM(y * oh - my), 0);
      render_inner(&src, dst);
      dst->rect.x = bx;
      dst->rect.y = by;
    }
  }
}

/*
===固定マップレイヤー転送インナーメソッド
*/
static void fixedmaplayer_render_inner(VALUE self, MiyakoBitmap *dst)
{
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

  MiyakoBitmap src;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  
  int bx = dst->rect.x;
  int by = dst->rect.y;
  
  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = y % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      _miyako_setup_unit(rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0),
                         scr, &src, INT2NUM(pos_x + x * ow), INT2NUM(pos_y + y * oh), 0);
      render_inner(&src, dst);
      dst->rect.x = bx;
      dst->rect.y = by;
    }
  }
}

/*
===マップレイヤー転送インナーメソッド
*/
static void maplayer_render_to_inner(VALUE self, MiyakoBitmap *dst)
{
  int cw = NUM2INT(rb_iv_get(self, "@cw"));
  int ch = NUM2INT(rb_iv_get(self, "@ch"));
  int ow = NUM2INT(rb_iv_get(self, "@ow"));
  int oh = NUM2INT(rb_iv_get(self, "@oh"));

  VALUE margin = rb_iv_get(self, "@pos");
  int pos_x = NUM2INT(*(RSTRUCT_PTR(margin) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(margin) + 1));

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

  MiyakoBitmap src;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  
  int bx = dst->rect.x;
  int by = dst->rect.y;
  
  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      _miyako_setup_unit(rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0),
                         scr, &src, INT2NUM(x * ow - mx), INT2NUM(y * oh - my), 0);
      render_inner(&src, dst);
      dst->rect.x = bx;
      dst->rect.y = by;
    }
  }
}

/*
===固定マップレイヤー転送インナーメソッド
*/
static void fixedmaplayer_render_to_inner(VALUE self, MiyakoBitmap *dst)
{
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

  MiyakoBitmap src;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  
  int bx = dst->rect.x;
  int by = dst->rect.y;
  
  int x, y, idx1, idx2;
  for(y = 0; y < ch; y++){
    idx1 = y % size_h;
    VALUE mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      int code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
      if(code == -1){ continue; }
      _miyako_setup_unit(rb_funcall(*(RARRAY_PTR(munits) + code), rb_intern("to_unit"), 0),
                         scr, &src, INT2NUM(pos_x + x * ow), INT2NUM(pos_y + y * oh), 0);
      render_inner(&src, dst);
      dst->rect.x = bx;
      dst->rect.y = by;
    }
  }
}

/*
マップレイヤーを画面に描画する
*/
static VALUE maplayer_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  maplayer_render_inner(self, &dst);
  return self;
}

/*
マップレイヤーを画面に描画する
*/
static VALUE fixedmaplayer_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  fixedmaplayer_render_inner(self, &dst);
  return self;
}

/*
マップレイヤーを画像に転送する
*/
static VALUE maplayer_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);
  maplayer_render_to_inner(self, &dst);
  return self;
}

/*
マップレイヤーを画像に転送する
*/
static VALUE fixedmaplayer_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);
  maplayer_render_inner(self, &dst);
  return self;
}

/*
マップを画面に描画する
*/
static VALUE map_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }
  
  return self;
}

/*
マップを画面に描画する
*/
static VALUE fixedmap_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }

  return self;
}

/*
マップを画像に描画する
*/
static VALUE map_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render_to_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }

  return self;
}

/*
マップを画像に描画する
*/
static VALUE fixedmap_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
	MiyakoBitmap dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  VALUE map_layers = rb_iv_get(self, "@map_layers");
  int i;
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render_to_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }

  return self;
}

/*
:nodoc:
*/
static VALUE sa_set_pat(VALUE self)
{
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE units = rb_iv_get(self, "@units");
  rb_iv_set(self, "@now", *(RARRAY_PTR(units) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num)))));
  return self;
}

/*
:nodoc:
*/
static VALUE sa_update_frame(VALUE self)
{
  int cnt = NUM2INT(rb_iv_get(self, "@cnt"));

  if(cnt > 0){
    cnt--;
    rb_iv_set(self, "@cnt", INT2NUM(cnt));
    return Qfalse;
  }

  VALUE num = rb_iv_get(self, "@pnum");
  VALUE loop = rb_iv_get(self, "@loop");

  int pnum = NUM2INT(num);
  int pats = NUM2INT(rb_iv_get(self, "@pats"));
  pnum = (pnum + 1) % pats;

  rb_iv_set(self, "@pnum", INT2NUM(pnum));

  if(loop == Qfalse && pnum == 0){
    rb_funcall(self, rb_intern("stop"), 0);
    return Qfalse;
  }

  sa_set_pat(self);
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE waits = rb_iv_get(self, "@waits");
  rb_iv_set(self, "@cnt", *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum))));

  return Qtrue;
}

/*
:nodoc:
*/
static VALUE sa_update_wait_counter(VALUE self)
{
  VALUE cnt = rb_iv_get(self, "@cnt");
  VALUE waiting = rb_funcall(cnt, rb_intern("waiting?"), 0);

  if(waiting == Qtrue) return Qfalse;
  
  VALUE num = rb_iv_get(self, "@pnum");
  VALUE loop = rb_iv_get(self, "@loop");

  int pnum = NUM2INT(num);
  int pats = NUM2INT(rb_iv_get(self, "@pats"));
  pnum = (pnum + 1) % pats;
    
  rb_iv_set(self, "@pnum", INT2NUM(pnum));
    
  if(loop == Qfalse && pnum == 0){
    rb_funcall(self, rb_intern("stop"), 0);
    return Qfalse;
  }

  sa_set_pat(self);
  VALUE plist = rb_iv_get(self, "@plist");
  VALUE waits = rb_iv_get(self, "@waits");
  cnt = *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum)));
  rb_iv_set(self, "@cnt", cnt);
  rb_funcall(cnt, rb_intern("start"), 0);
  return Qtrue;
}

/*
:nodoc:
*/
static VALUE sa_update(VALUE self)
{
  VALUE is_change = Qfalse;
  VALUE exec = rb_iv_get(self, "@exec");
  if(exec == Qfalse){ return is_change; }

  if(rb_obj_is_kind_of(rb_iv_get(self, "@cnt"), rb_cInteger) == Qtrue)
    is_change = sa_update_frame(self);
  else
    is_change = sa_update_wait_counter(self);
  
  return is_change;
}

/*
アニメーションの現在の画像を画面に描画する
*/
static VALUE sa_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  VALUE vsrc = rb_iv_get(self, "@now");
  VALUE *runit = RSTRUCT_PTR(vsrc);
  VALUE polist = rb_iv_get(self, "@pos_offset");
  VALUE dir = rb_iv_get(self, "@dir");
  
  int num = NUM2INT(rb_iv_get(self, "@pnum"));

  VALUE *move_off = RARRAY_PTR(rb_funcall(*(RARRAY_PTR(rb_iv_get(self, "@move_offset")) + num), id_to_a, 0));

  int pos_off = NUM2INT(*(RARRAY_PTR(polist) + num));

  int didx = (rb_to_id(dir) == rb_intern("h") ? 2 : 1);
  
  VALUE tmp_oxy = *(runit +  didx);
  VALUE tmp_x = *(runit + 5);
  VALUE tmp_y = *(runit + 6);

  *(runit + didx) = INT2NUM(NUM2INT(tmp_oxy) - pos_off);
  *(runit + 5) = INT2NUM(NUM2INT(tmp_x) + NUM2INT(*(move_off+0)));
  *(runit + 6) = INT2NUM(NUM2INT(tmp_y) + NUM2INT(*(move_off+1)));

	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(vsrc, mScreen, scr, &src, &dst, Qnil, Qnil, 1);
  render_inner(&src, &dst);

  *(runit + 5) = tmp_x;
  *(runit + 6) = tmp_y;
  *(runit + didx) = tmp_oxy;

  return Qnil;
}

/*
アニメーションの現在の画像を画像に描画する
*/
static VALUE sa_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  VALUE vsrc = rb_iv_get(self, "@now");
  VALUE *runit = RSTRUCT_PTR(vsrc);
  VALUE polist = rb_iv_get(self, "@pos_offset");
  VALUE dir = rb_iv_get(self, "@dir");
  
  int num = NUM2INT(rb_iv_get(self, "@pnum"));

  int pos_off = NUM2INT(*(RARRAY_PTR(polist) + num));

  VALUE molist = rb_iv_get(self, "@move_offset");
  VALUE move_off = *(RARRAY_PTR(molist) + num);

  int didx = (rb_to_id(dir) == rb_intern("h") ? 3 : 2);
  
  VALUE tmp_oxy = *(runit +  didx);
  VALUE tmp_x = *(runit + 5);
  VALUE tmp_y = *(runit + 6);

  *(runit + didx) = INT2NUM(NUM2INT(tmp_oxy) - pos_off);
  *(runit + 5) = INT2NUM(NUM2INT(tmp_x) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nZero)));
  *(runit + 6) = INT2NUM(NUM2INT(tmp_y) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nOne )));

	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  render_to_inner(&src, &dst);

  *(runit + 5) = tmp_x;
  *(runit + 6) = tmp_y;
  *(runit + didx) = tmp_oxy;

  return Qnil;
}

/*
プレーンを画面に描画する
*/
static VALUE plane_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  VALUE sprite = rb_iv_get(self, "@sprite");

  VALUE ssize = rb_iv_get(mScreen, "@@size");
  int ssw = NUM2INT(*(RSTRUCT_PTR(ssize) + 0));
  int ssh = NUM2INT(*(RSTRUCT_PTR(ssize) + 1));
  VALUE pos = rb_iv_get(self, "@pos");
  VALUE size = rb_iv_get(self, "@size");
  int w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	_miyako_setup_unit_2(sprite, mScreen, scr, &src, &dst, Qnil, Qnil, 1);

  int sw = src.rect.w;
  int sh = src.rect.h;

  int x, y;
  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      src.x = (x-1) * sw + pos_x;
      src.y = (y-1) * sh + pos_y;
      if(src.x > 0 || src.y > 0
      || (src.x+sw) <= ssw || (src.y+sh) <= ssh){
				render_inner(&src, &dst);
      }
    }
  }
  
  return Qnil;
}

/*
プレーンを画像に描画する
*/
static VALUE plane_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  VALUE sprite = rb_iv_get(self, "@sprite");

  VALUE ssize = rb_iv_get(mScreen, "@@size");
  int ssw = NUM2INT(*(RSTRUCT_PTR(ssize) + 0));
  int ssh = NUM2INT(*(RSTRUCT_PTR(ssize) + 1));
  VALUE pos = rb_iv_get(self, "@pos");
  VALUE size = rb_iv_get(self, "@size");
  int w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  int h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  int pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  int pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));

	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
	_miyako_setup_unit_2(sprite, vdst, scr, &src, &dst, Qnil, Qnil, 1);

  int sw = src.rect.w;
  int sh = src.rect.h;

  int x, y;
  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      src.x = (x-1) * sw + pos_x;
      src.y = (y-1) * sh + pos_y;
      if(src.x > 0 || src.y > 0
      || (src.x+sw) <= ssw || (src.y+sh) <= ssh){
        render_to_inner(&src, &dst);
      }
    }
  }
  
  return Qnil;
}

/*
パーツを画面に描画する
*/
static VALUE parts_render(VALUE self)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  VALUE parts_list = rb_iv_get(self, "@parts_list");
  VALUE parts_hash = rb_iv_get(self, "@parts");

  int i;
  for(i=0; i<RARRAY_LEN(parts_list); i++)
  {
    VALUE parts = rb_hash_aref(parts_hash, *(RARRAY_PTR(parts_list) + i));
    rb_funcall(parts, id_render, 0);
  }
  
  return Qnil;
}

/*
パーツを画面に描画する
*/
static VALUE parts_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE visible = rb_iv_get(self, "@visible");
  if(visible == Qfalse) return self;
  VALUE parts_list = rb_iv_get(self, "@parts_list");
  VALUE parts_hash = rb_iv_get(self, "@parts");

  int i;
  for(i=0; i<RARRAY_LEN(parts_list); i++)
  {
    VALUE parts = rb_hash_aref(parts_hash, *(RARRAY_PTR(parts_list) + i));
    rb_funcall(parts, rb_intern("render_to"), 1, vdst);
  }
  
  return Qnil;
}

/*
:nodoc:
*/
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

void Init_miyako_no_katana()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  mDiagram = rb_define_module_under(mMiyako, "Diagram");
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cGL  = rb_define_module_under(mSDL, "GL");
  cFont  = rb_define_class_under(mMiyako, "Font", rb_cObject);
  cThread = rb_define_class("Thread", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);
  cSpriteAnimation = rb_define_class_under(mMiyako, "SpriteAnimation", rb_cObject);
  cPlane = rb_define_class_under(mMiyako, "Plane", rb_cObject);
  cParts = rb_define_class_under(mMiyako, "Parts", rb_cObject);
  cMap = rb_define_class_under(mMiyako, "Map", rb_cObject);
  cMapLayer = rb_define_class_under(cMap, "MapLayer", rb_cObject);
  cFixedMap = rb_define_class_under(mMiyako, "FixedMap", rb_cObject);
  cFixedMapLayer = rb_define_class_under(cFixedMap, "FixedMapLayer", rb_cObject);
  cProcessor = rb_define_class_under(mDiagram, "Processor", rb_cObject);

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);
  
  rb_define_module_function(mScreen, "update_tick", screen_update_tick, 0);
  rb_define_module_function(mScreen, "pre_render", screen_pre_render, 0);
  rb_define_module_function(mScreen, "render", screen_render, 0);
  rb_define_module_function(mScreen, "render_screen", screen_render_screen, 1);

  rb_define_method(cSpriteAnimation, "update_animation", sa_update, 0);
  rb_define_method(cSpriteAnimation, "update_frame", sa_update_frame, 0);
  rb_define_method(cSpriteAnimation, "update_wait_counter", sa_update_wait_counter, 0);
  rb_define_method(cSpriteAnimation, "set_pat", sa_set_pat, 0);
  rb_define_method(cSpriteAnimation, "render", sa_render, 0);
  rb_define_method(cSpriteAnimation, "render_to", sa_render_to_sprite, 1);

  rb_define_singleton_method(cSprite, "render_to", sprite_c_render_to_sprite, 2);
  rb_define_method(cSprite, "render", sprite_render, 0);
  rb_define_method(cSprite, "render_to", sprite_render_to_sprite, 1);

  rb_define_method(cPlane, "render", plane_render, 0);
  rb_define_method(cPlane, "render_to", plane_render_to_sprite, 1);

  rb_define_method(cParts, "render", parts_render, 0);
  rb_define_method(cParts, "render_to", parts_render_to_sprite, 1);

  rb_define_method(cProcessor, "main_loop", processor_mainloop, 0);
  
  rb_define_method(cMapLayer, "render", maplayer_render, 0);
  rb_define_method(cFixedMapLayer, "render", fixedmaplayer_render, 0);
  rb_define_method(cMap, "render", map_render, 0);
  rb_define_method(cFixedMap, "render", fixedmap_render, 0);
  rb_define_method(cMap, "render_to", map_render_to_sprite, 1);
  rb_define_method(cFixedMap, "render_to", fixedmap_render_to_sprite, 1);
  rb_define_method(cMapLayer, "render_to", maplayer_render_to_sprite, 1);
  rb_define_method(cFixedMapLayer, "render_to", fixedmaplayer_render_to_sprite, 1);

  use_opengl = rb_gv_get("$miyako_use_opengl");
  
  Init_miyako_bitmap();
  Init_miyako_transform();
  Init_miyako_hsv();
  Init_miyako_drawing();
  Init_miyako_layout();
  Init_miyako_collision();
  Init_miyako_basicdata();
  Init_miyako_font();
  Init_miyako_utility();
}
