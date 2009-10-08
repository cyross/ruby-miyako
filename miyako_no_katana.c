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
static VALUE mAudio = Qnil;
static VALUE mInput = Qnil;
static VALUE mSpriteBase = Qnil;
static VALUE mAnimation = Qnil;
static VALUE mDiagram = Qnil;
static VALUE cSurface = Qnil;
static VALUE cGL = Qnil;
static VALUE cFont = Qnil;
static VALUE cThread = Qnil;
static VALUE cSprite = Qnil;
static VALUE cSpriteAnimation = Qnil;
static VALUE cPlane = Qnil;
static VALUE cMap = Qnil;
static VALUE cMapLayer = Qnil;
static VALUE cFixedMap = Qnil;
static VALUE cFixedMapLayer = Qnil;
static VALUE cTextbox = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update     = Qnil;
static volatile ID id_kakko      = Qnil;
static volatile ID id_kakko_eq   = Qnil;
static volatile ID id_render     = Qnil;
static volatile ID id_render_to  = Qnil;
static volatile ID id_to_a       = Qnil;
static volatile ID id_move       = Qnil;
static volatile ID id_move_to    = Qnil;
static volatile ID id_defined    = Qnil;
static volatile ID id_pos        = Qnil;
static volatile ID id_ua         = Qnil;
static volatile ID id_start      = Qnil;
static volatile ID id_stop       = Qnil;
static volatile ID id_reset      = Qnil;
static volatile int zero         = Qnil;
static volatile int one          = Qnil;
static const char *str_visible       = "@visible";
static const char *str_textarea      = "@textarea";
static const char *str_waiting       = "@waiting";
static const char *str_wait_cursor   = "@wait_cursor";
static const char *str_selecting     = "@selecting";
static const char *str_select_cursor = "@select_cursor";
static const char *str_choices       = "@choices";
static const char *str_ahash          = "@@anim_hash";

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
extern void Init_miyako_sprite2();
extern void Init_miyako_input_audio();
extern void Init_miyako_diagram();
extern void Init_miyako_yuki();

static VALUE anim_m_update(VALUE self);

static VALUE miyako_main_loop(int argc, VALUE *argv, VALUE self)
{
  VALUE clear = Qnil;
  int is_clear = 0;
  if(argc == 0){ is_clear = 1; }
  rb_scan_args(argc, argv, "01", &clear);
  if(clear != Qnil && clear != Qfalse){ is_clear = 1; }
  rb_need_block();
  for(;;)
  {
    _miyako_audio_update();
    _miyako_input_update();
    _miyako_counter_update();
    if(is_clear){ _miyako_screen_clear(); }
    rb_yield(Qnil);
    _miyako_counter_post_update();
    anim_m_update(mAnimation);
    _miyako_screen_render();
  }
  return Qnil;
}

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
インスタンスの内容を画面に描画する
*/
static VALUE sprite_b_render_xy(VALUE self, VALUE vx, VALUE vy)
{
  if(rb_iv_get(self, str_visible) == Qfalse) return self;
  VALUE cls = rb_obj_class(self);
  if(rb_funcall(cls, id_defined, ID2SYM(id_move_to)) == Qfalse ||
      rb_funcall(cls, id_defined, ID2SYM(id_pos)) == Qfalse ){
    rb_funcall(self, id_render, 0);
    return self;
  }
  VALUE *p_pos = RSTRUCT_PTR(_miyako_layout_pos(self));
  VALUE x = *(p_pos + 0);
  VALUE y = *(p_pos + 1);
  _miyako_layout_move_to(self, vx, vy);
  rb_funcall(self, id_render, 0);
  _miyako_layout_move_to(self, x, y);
  return self;
}

/*
インスタンスの内容を別のインスタンスに描画する
*/
static VALUE sprite_b_render_xy_to_sprite(VALUE self, VALUE vdst, VALUE vx, VALUE vy)
{
  if(rb_iv_get(self, str_visible) == Qfalse) return self;
  VALUE cls = rb_obj_class(self);
  if(rb_funcall(cls, id_defined, ID2SYM(id_move_to)) == Qfalse ||
      rb_funcall(cls, id_defined, ID2SYM(id_pos)) == Qfalse ){
    rb_funcall(self, id_render_to, 1, vdst);
    return self;
  }
  VALUE *p_pos = RSTRUCT_PTR(_miyako_layout_pos(self));
  VALUE x = *(p_pos + 0);
  VALUE y = *(p_pos + 1);
  _miyako_layout_move_to(self, vx, vy);
  rb_funcall(self, id_render_to, 1, vdst);
  _miyako_layout_move_to(self, x, y);
  return self;
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
  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  VALUE src_unit = rb_iv_get(self, "@unit");
  VALUE dst_unit = rb_iv_get(mScreen, "@@unit");

  SDL_Surface  *src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  SDL_Surface  *dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  SDL_Rect srect, drect;

  VALUE *s_p = RSTRUCT_PTR(src_unit);
  srect.x = NUM2INT(*(s_p + 1));
  srect.y = NUM2INT(*(s_p + 2));
  srect.w = NUM2INT(*(s_p + 3));
  srect.h = NUM2INT(*(s_p + 4));

  VALUE *d_p = RSTRUCT_PTR(dst_unit);
  drect.x = NUM2INT(*(d_p + 1)) + NUM2INT(*(s_p + 5));
  drect.y = NUM2INT(*(d_p + 2)) + NUM2INT(*(s_p + 6));
  drect.w = NUM2INT(*(d_p + 3));
  drect.h = NUM2INT(*(d_p + 4));

  SDL_BlitSurface(src, &srect, dst, &drect);
  return self;
}

VALUE _miyako_sprite_render(VALUE sprite)
{
  return sprite_render(sprite);
}

/*
インスタンスの内容を別のインスタンスに描画する
*/
static VALUE sprite_render_to_sprite(VALUE self, VALUE vdst)
{
  if(rb_iv_get(self, str_visible) == Qfalse) return self;
	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  render_to_inner(&src, &dst);
  return self;
}

/*
インスタンスの内容を画面に描画する
*/
static VALUE sprite_render_xy(VALUE self, VALUE vx, VALUE vy)
{
  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  VALUE src_unit = rb_iv_get(self, "@unit");
  VALUE dst_unit = rb_iv_get(mScreen, "@@unit");

  SDL_Surface  *src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  SDL_Surface  *dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  SDL_Rect srect, drect;

  VALUE *s_p = RSTRUCT_PTR(src_unit);
  srect.x = NUM2INT(*(s_p + 1));
  srect.y = NUM2INT(*(s_p + 2));
  srect.w = NUM2INT(*(s_p + 3));
  srect.h = NUM2INT(*(s_p + 4));

  VALUE *d_p = RSTRUCT_PTR(dst_unit);
  drect.x = NUM2INT(*(d_p + 1)) + NUM2INT(vx);
  drect.y = NUM2INT(*(d_p + 2)) + NUM2INT(vy);
  drect.w = NUM2INT(*(d_p + 3));
  drect.h = NUM2INT(*(d_p + 4));

  SDL_BlitSurface(src, &srect, dst, &drect);
  return self;
}

VALUE _miyako_sprite_render_xy(VALUE sprite, VALUE x, VALUE y)
{
  return sprite_render_xy(sprite, x, y);
}

/*
インスタンスの内容を別のインスタンスに描画する
*/
static VALUE sprite_render_xy_to_sprite(VALUE self, VALUE vdst, VALUE vx, VALUE vy)
{
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
	MiyakoBitmap src, dst;
	SDL_Surface  *scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  src.x = NUM2INT(vx);
  src.y = NUM2INT(vy);
  render_to_inner(&src, &dst);
  return self;
}

/*
:nodoc:
*/
static VALUE screen_update_tick(VALUE self)
{
  Uint32 t = SDL_GetTicks();
  Uint32 tt = NUM2INT(rb_iv_get(mScreen, "@@t"));
  Uint32 interval = t - tt;
  int fps_cnt = NUM2INT(rb_iv_get(mScreen, "@@fpscnt"));

  while(interval < fps_cnt){
    t = NUM2INT(rb_funcall(mSDL, rb_intern("getTicks"), 0));
    interval = t - tt;
  }

  rb_iv_set(mScreen, "@@t", INT2NUM(t));
  rb_iv_set(mScreen, "@@interval", INT2NUM(interval));

  return Qnil;
}

void _miyako_screen_update_tick()
{
  screen_update_tick(mScreen);
}

/*
:nodoc:
*/
static VALUE screen_pre_render(VALUE self)
{
  _miyako_sprite_list_render(rb_iv_get(mScreen, "@@pre_render_array"));
  return Qnil;
}

void _miyako_screen_pre_render()
{
  screen_pre_render(mScreen);
}

/*
画面を更新する
*/
static VALUE screen_render(VALUE self)
{
  VALUE dst = rb_iv_get(mScreen, "@@unit");
	SDL_Surface *pdst = GetSurface(*(RSTRUCT_PTR(dst)))->surface;
  VALUE fps_view = rb_iv_get(mScreen, "@@fpsView");

  _miyako_sprite_list_render(rb_iv_get(cSprite, "@@sprites"));

  _miyako_sprite_list_render(rb_iv_get(mScreen, "@@auto_render_array"));

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

void _miyako_screen_render()
{
  screen_render(mScreen);
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

void _miyako_screen_render_screen(VALUE src)
{
  screen_render_screen(mScreen, src);
}

static int anim_m_hash_start(VALUE key, VALUE val)
{
  if(val == Qnil){ return 0; }
  rb_funcall(val, id_start, 0);
  return 0;
}

static int anim_m_hash_stop(VALUE key, VALUE val)
{
  if(val == Qnil){ return 0; }
  rb_funcall(val, id_stop, 0);
  return 0;
}

static int anim_m_hash_reset(VALUE key, VALUE val)
{
  if(val == Qnil){ return 0; }
  rb_funcall(val, id_reset, 0);
  return 0;
}

static int anim_m_hash_update(VALUE key, VALUE val)
{
  if(val == Qnil){ return 0; }
  rb_funcall(val, id_ua, 0);
  return 0;
}

/*
:nodoc:
*/
static VALUE anim_m_start(VALUE self)
{
  rb_hash_foreach(rb_iv_get(self, str_ahash), anim_m_hash_start, Qnil);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE anim_m_stop(VALUE self)
{
  rb_hash_foreach(rb_iv_get(self, str_ahash), anim_m_hash_stop, Qnil);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE anim_m_reset(VALUE self)
{
  rb_hash_foreach(rb_iv_get(self, str_ahash), anim_m_hash_reset, Qnil);
  return Qnil;
}

/*
:nodoc:
*/
static VALUE anim_m_update(VALUE self)
{
  rb_hash_foreach(rb_iv_get(self, str_ahash), anim_m_hash_update, Qnil);
  return Qnil;
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
  VALUE visible = rb_iv_get(self, str_visible);
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
:nodoc:
*/
static VALUE textbox_render(VALUE self)
{
  if(rb_iv_get(self, str_visible) == Qfalse){ return self; }
  sprite_render(rb_iv_get(self, str_textarea));
  VALUE wait_cursor = rb_iv_get(self, str_wait_cursor);
  if(wait_cursor != Qnil)
  {
    VALUE waiting = rb_iv_get(self, str_waiting);
    if(waiting == Qtrue)
    {
      rb_funcall(wait_cursor, id_render, 0);
    }
  }

  if(rb_iv_get(self, str_selecting) == Qtrue)
  {
    rb_funcall(rb_iv_get(self, str_choices), id_render, 0);
    VALUE select_cursor = rb_iv_get(self, str_select_cursor);
    if(select_cursor != Qnil)
    {
      rb_funcall(select_cursor, id_render, 0);
    }
  }
  return self;
}

/*
:nodoc:
*/
static VALUE textbox_render_to(VALUE self, VALUE dst)
{

  if(rb_iv_get(self, str_visible) == Qfalse){ return self; }
  sprite_render_to_sprite(rb_iv_get(self, str_textarea), dst);
  VALUE wait_cursor = rb_iv_get(self, str_wait_cursor);
  if(wait_cursor != Qnil)
  {
    VALUE waiting = rb_iv_get(self, str_waiting);
    if(waiting == Qtrue)
    {
      rb_funcall(wait_cursor, id_render_to, 1, dst);
    }
  }

  if(rb_iv_get(self, str_selecting) == Qtrue)
  {
    rb_funcall(rb_iv_get(self, str_choices), id_render_to, 1, dst);
    VALUE select_cursor = rb_iv_get(self, str_select_cursor);
    if(select_cursor != Qnil)
    {
      rb_funcall(select_cursor, id_render_to, 1, dst);
    }
  }
  return self;
}

void Init_miyako_no_katana()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  mAudio = rb_define_module_under(mMiyako, "Audio");
  mInput = rb_define_module_under(mMiyako, "Input");
  mSpriteBase = rb_define_module_under(mMiyako, "SpriteBase");
  mAnimation = rb_define_module_under(mMiyako, "Animation");
  mDiagram = rb_define_module_under(mMiyako, "Diagram");
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cGL  = rb_define_module_under(mSDL, "GL");
  cFont  = rb_define_class_under(mMiyako, "Font", rb_cObject);
  cThread = rb_define_class("Thread", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);
  cSpriteAnimation = rb_define_class_under(mMiyako, "SpriteAnimation", rb_cObject);
  cPlane = rb_define_class_under(mMiyako, "Plane", rb_cObject);
  cMap = rb_define_class_under(mMiyako, "Map", rb_cObject);
  cMapLayer = rb_define_class_under(cMap, "MapLayer", rb_cObject);
  cFixedMap = rb_define_class_under(mMiyako, "FixedMap", rb_cObject);
  cFixedMapLayer = rb_define_class_under(cFixedMap, "FixedMapLayer", rb_cObject);
  cTextbox = rb_define_class_under(mMiyako, "TextBox", rb_cObject);

  id_update     = rb_intern("update");
  id_kakko      = rb_intern("[]");
  id_kakko_eq   = rb_intern("[]=");
  id_render     = rb_intern("render");
  id_render_to  = rb_intern("render_to");
  id_to_a       = rb_intern("to_a");
  id_move       = rb_intern("move!");
  id_move_to    = rb_intern("move_to!");
  id_defined    = rb_intern("method_defined?");
  id_pos        = rb_intern("pos");
  id_start      = rb_intern("start");
  id_stop       = rb_intern("stop");
  id_reset      = rb_intern("reset");
  id_ua         = rb_intern("update_animation");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

#if 1
  rb_define_singleton_method(mMiyako, "main_loop", miyako_main_loop, -1);

  rb_define_singleton_method(mScreen, "update_tick", screen_update_tick, 0);
  rb_define_singleton_method(mScreen, "pre_render", screen_pre_render, 0);
  rb_define_singleton_method(mScreen, "render", screen_render, 0);
  rb_define_singleton_method(mScreen, "render_screen", screen_render_screen, 1);

  rb_define_singleton_method(mAnimation, "start", anim_m_start, 0);
  rb_define_singleton_method(mAnimation, "stop", anim_m_stop, 0);
  rb_define_singleton_method(mAnimation, "reset", anim_m_reset, 0);
  rb_define_singleton_method(mAnimation, "update", anim_m_update, 0);
  rb_define_singleton_method(mAnimation, "update_animation", anim_m_update, 0);
#else
  rb_define_module_function(mMiyako, "main_loop", miyako_main_loop, -1);

  rb_define_module_function(mScreen, "update_tick", screen_update_tick, 0);
  rb_define_module_function(mScreen, "pre_render", screen_pre_render, 0);
  rb_define_module_function(mScreen, "render", screen_render, 0);
  rb_define_module_function(mScreen, "render_screen", screen_render_screen, 1);

  rb_define_module_function(mAnimation, "start", anim_m_start, 0);
  rb_define_module_function(mAnimation, "stop", anim_m_stop, 0);
  rb_define_module_function(mAnimation, "reset", anim_m_reset, 0);
  rb_define_module_function(mAnimation, "update", anim_m_update, 0);
  rb_define_module_function(mAnimation, "update_animation", anim_m_update, 0);
#endif
  rb_define_method(cSpriteAnimation, "update_animation", sa_update, 0);
  rb_define_method(cSpriteAnimation, "update_frame", sa_update_frame, 0);
  rb_define_method(cSpriteAnimation, "update_wait_counter", sa_update_wait_counter, 0);
  rb_define_method(cSpriteAnimation, "set_pat", sa_set_pat, 0);
  rb_define_method(cSpriteAnimation, "render", sa_render, 0);
  rb_define_method(cSpriteAnimation, "render_to", sa_render_to_sprite, 1);

  rb_define_method(mSpriteBase, "render_xy", sprite_b_render_xy, 2);
  rb_define_method(mSpriteBase, "render_xy_to", sprite_b_render_xy_to_sprite, 3);
  rb_define_singleton_method(cSprite, "render_to", sprite_c_render_to_sprite, 2);
  rb_define_method(cSprite, "render", sprite_render, 0);
  rb_define_method(cSprite, "render_to", sprite_render_to_sprite, 1);
  rb_define_method(cSprite, "render_xy", sprite_render_xy, 2);
  rb_define_method(cSprite, "render_xy_to", sprite_render_xy_to_sprite, 3);

  rb_define_method(cPlane, "render", plane_render, 0);
  rb_define_method(cPlane, "render_to", plane_render_to_sprite, 1);

  rb_define_method(cMapLayer, "render", maplayer_render, 0);
  rb_define_method(cFixedMapLayer, "render", fixedmaplayer_render, 0);
  rb_define_method(cMap, "render", map_render, 0);
  rb_define_method(cFixedMap, "render", fixedmap_render, 0);
  rb_define_method(cMap, "render_to", map_render_to_sprite, 1);
  rb_define_method(cFixedMap, "render_to", fixedmap_render_to_sprite, 1);
  rb_define_method(cMapLayer, "render_to", maplayer_render_to_sprite, 1);
  rb_define_method(cFixedMapLayer, "render_to", fixedmaplayer_render_to_sprite, 1);

  rb_define_method(cTextbox, "render", textbox_render, 0);
  rb_define_method(cTextbox, "render_to", textbox_render_to, 1);

  use_opengl = rb_gv_get("$miyako_use_opengl");

  Init_miyako_bitmap();
  Init_miyako_transform();
  Init_miyako_hsv();
  Init_miyako_drawing();
  Init_miyako_layout();
  Init_miyako_collision();
  Init_miyako_basicdata();
  Init_miyako_sprite2();
  Init_miyako_font();
  Init_miyako_utility();
  Init_miyako_input_audio();
  Init_miyako_diagram();
  Init_miyako_yuki();
}
