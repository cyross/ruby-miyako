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
#include "extern.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE mScreen = Qnil;
static VALUE mAudio = Qnil;
static VALUE mInput = Qnil;
static VALUE mSpriteBase = Qnil;
static VALUE mAnimation = Qnil;
static VALUE mDiagram = Qnil;
static VALUE eMiyakoError = Qnil;
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
  VALUE gc = Qnil;
  int is_clear = 0;
  int use_gc = 0;
  if(argc == 0){ is_clear = 1; }
  rb_scan_args(argc, argv, "02", &clear, &gc);
  if(clear != Qnil && clear != Qfalse){ is_clear = 1; }
  if(gc != Qnil && gc != Qfalse){ use_gc = 1; }
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
    if(use_gc){ rb_gc_start(); }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE sprite_get_rect(VALUE src, int *dst)
{
  int i;
  VALUE *tmp;
  switch(TYPE(src))
  {
  case T_ARRAY:
    if(RARRAY_LEN(src) < 4)
      rb_raise(eMiyakoError, "rect needs 4 or much elements!");
    tmp = RARRAY_PTR(src);
    for(i=0; i<4; i++){ *dst++ = NUM2INT(*tmp++); }
    break;
  case T_STRUCT:
    if(RSTRUCT_LEN(src) < 4)
      rb_raise(eMiyakoError, "rect needs 4 or much members!");
    tmp = RSTRUCT_PTR(src);
    for(i=0; i<4; i++){ *dst++ = NUM2INT(*tmp++); }
    break;
  default:
    *(dst+0) = NUM2INT(rb_funcall(src, rb_intern("x"), 0));
    *(dst+1) = NUM2INT(rb_funcall(src, rb_intern("y"), 0));
    *(dst+2) = NUM2INT(rb_funcall(src, rb_intern("w"), 0));
    *(dst+3) = NUM2INT(rb_funcall(src, rb_intern("h"), 0));
    break;
  }
  return Qnil;
}

/*
*/
static void render_to_inner(MiyakoBitmap *sb, MiyakoBitmap *db)
{
  int x, y, a1, a2;
  MiyakoSize size;
  Uint32 src_y, dst_y, src_x, dst_x, *psrc, *pdst;
  if(sb->ptr == db->ptr){ return; }

  if(_miyako_init_rect(sb, db, &size) == 0) return;

  SDL_LockSurface(sb->surface);
  SDL_LockSurface(db->surface);

  for(y = 0; y < size.h; y++)
  {
    src_y = (sb->rect.y         + y);
    dst_y = (db->rect.y + sb->y + y);
    src_x = sb->rect.x;
    dst_x = db->rect.x + sb->x;

    if(src_y < 0 || dst_y < 0){ continue; }
    if(src_y >= sb->surface->h || dst_y >= db->surface->h){ break; }

    psrc = sb->ptr + src_y * sb->surface->w + src_x;
    pdst = db->ptr + dst_y * db->surface->w + dst_x;
    for(x = 0; x < size.w; x++)
    {
      if(src_x < 0 || dst_x < 0){  psrc++; pdst++; src_x++; dst_x++; continue; }
      if(src_x >= sb->surface->w || dst_x >= db->surface->w){ break; }
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
      sb->color.a = (*psrc >> 24) & 0xff | sb->a255;
      if(sb->color.a == 0){ psrc++; pdst++; src_x++; dst_x++; continue; }
      db->color.a = (*pdst >> 24) & 0xff | db->a255;
      if(db->color.a == 0 || sb->color.a == 255){
        *pdst = *psrc | (sb->a255 << 24);
        psrc++;
        pdst++;
        src_x++;
        dst_x++;
        continue;
      }
      a1 = sb->color.a + 1;
      a2 = 256 - sb->color.a;
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
      if(sb->color.a == 0){ psrc++; pdst++; src_x++; dst_x++; continue; }
      db->color.a = (*pdst & db->fmt->Amask) | db->a255;
      if(db->color.a == 0 || sb->color.a == 255){
        *pdst = *psrc | sb->a255;
        psrc++;
        pdst++;
        src_x++;
        dst_x++;
        continue;
      }
      a1 = sb->color.a + 1;
      a2 = 256 - sb->color.a;
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
      src_x++;
      dst_x++;
    }
  }

  SDL_UnlockSurface(sb->surface);
  SDL_UnlockSurface(db->surface);
}

/*
*/
static void render_inner(MiyakoBitmap *sb, MiyakoBitmap *db)
{
  db->rect.x += sb->x;
  db->rect.y += sb->y;
  SDL_BlitSurface(sb->surface, &(sb->rect), db->surface, &(db->rect));
}

/*
*/
static VALUE sprite_b_render_xy(VALUE self, VALUE vx, VALUE vy)
{
  VALUE cls, *p_pos, x, y;
  if(rb_iv_get(self, str_visible) == Qfalse) return self;
  cls = rb_obj_class(self);
  if(rb_funcall(cls, id_defined, ID2SYM(id_move_to)) == Qfalse ||
      rb_funcall(cls, id_defined, ID2SYM(id_pos)) == Qfalse ){
    rb_funcall(self, id_render, 0);
    return self;
  }
  p_pos = RSTRUCT_PTR(_miyako_layout_pos(self));
  x = *(p_pos + 0);
  y = *(p_pos + 1);
  _miyako_layout_move_to(self, vx, vy);
  rb_funcall(self, id_render, 0);
  _miyako_layout_move_to(self, x, y);
  return self;
}

/*
*/
static VALUE sprite_b_render_xy_to_sprite(VALUE self, VALUE vdst, VALUE vx, VALUE vy)
{
  VALUE cls, *p_pos, x, y;
  if(rb_iv_get(self, str_visible) == Qfalse) return self;
  cls = rb_obj_class(self);
  if(rb_funcall(cls, id_defined, ID2SYM(id_move_to)) == Qfalse ||
      rb_funcall(cls, id_defined, ID2SYM(id_pos)) == Qfalse ){
    rb_funcall(self, id_render_to, 1, vdst);
    return self;
  }
  p_pos = RSTRUCT_PTR(_miyako_layout_pos(self));
  x = *(p_pos + 0);
  y = *(p_pos + 1);
  _miyako_layout_move_to(self, vx, vy);
  rb_funcall(self, id_render_to, 1, vdst);
  _miyako_layout_move_to(self, x, y);
  return self;
}

/*
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
*/
static VALUE sprite_render(VALUE self)
{
  VALUE src_unit, dst_unit, *s_p, *d_p;
  SDL_Surface *src, *dst;
  SDL_Rect srect, drect;

  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  src_unit = rb_iv_get(self, "@unit");
  dst_unit = rb_iv_get(mScreen, "@@unit");

  src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  s_p = RSTRUCT_PTR(src_unit);
  srect.x = NUM2INT(*(s_p + 1));
  srect.y = NUM2INT(*(s_p + 2));
  srect.w = NUM2INT(*(s_p + 3));
  srect.h = NUM2INT(*(s_p + 4));

  d_p = RSTRUCT_PTR(dst_unit);
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
*/
static VALUE sprite_render_to_sprite(VALUE self, VALUE vdst)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;
  if(rb_iv_get(self, str_visible) == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  render_to_inner(&src, &dst);
  return self;
}

/*
*/
static VALUE sprite_render_xy(VALUE self, VALUE vx, VALUE vy)
{
  VALUE src_unit, dst_unit, *s_p, *d_p;
  SDL_Surface *src, *dst;
  SDL_Rect srect, drect;

  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  src_unit = rb_iv_get(self, "@unit");
  dst_unit = rb_iv_get(mScreen, "@@unit");

  src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  s_p = RSTRUCT_PTR(src_unit);
  srect.x = NUM2INT(*(s_p + 1));
  srect.y = NUM2INT(*(s_p + 2));
  srect.w = NUM2INT(*(s_p + 3));
  srect.h = NUM2INT(*(s_p + 4));

  d_p = RSTRUCT_PTR(dst_unit);
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
*/
static VALUE sprite_render_xy_to_sprite(VALUE self, VALUE vdst, VALUE vx, VALUE vy)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  src.x = NUM2INT(vx);
  src.y = NUM2INT(vy);
  render_to_inner(&src, &dst);
  return self;
}

/*
*/
static VALUE sprite_render_rect(VALUE self, VALUE vrect)
{
  VALUE src_unit, dst_unit, *s_p, *d_p;
  SDL_Surface *src, *dst;
  SDL_Rect srect, drect;
  int rect[4];

  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  sprite_get_rect(vrect, &(rect[0]));

  src_unit = rb_iv_get(self, "@unit");
  dst_unit = rb_iv_get(mScreen, "@@unit");

  src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  s_p = RSTRUCT_PTR(src_unit);
  srect.x = NUM2INT(*(s_p + 1)) + rect[0];
  srect.y = NUM2INT(*(s_p + 2)) + rect[1];
  srect.w = rect[2];
  srect.h = rect[3];

  d_p = RSTRUCT_PTR(dst_unit);
  drect.x = NUM2INT(*(d_p + 1));
  drect.y = NUM2INT(*(d_p + 2));
  drect.w = NUM2INT(*(d_p + 3));
  drect.h = NUM2INT(*(d_p + 4));

  SDL_BlitSurface(src, &srect, dst, &drect);
  return self;
}

/*
*/
static VALUE sprite_render_rect_to_sprite(VALUE self, VALUE vdst, VALUE vrect)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;
  int rect[4];

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  sprite_get_rect(vrect, &(rect[0]));
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  src.rect.x += rect[0];
  src.rect.y += rect[1];
  src.rect.w = rect[2];
  src.rect.h = rect[3];
  render_to_inner(&src, &dst);
  return self;
}

/*
*/
static VALUE sprite_render_rect2(VALUE self, VALUE vrect)
{
  VALUE src_unit, dst_unit, *d_p;
  SDL_Surface *src, *dst;
  SDL_Rect srect, drect;
  int rect[4];

  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  sprite_get_rect(vrect, &(rect[0]));

  src_unit = rb_iv_get(self, "@unit");
  dst_unit = rb_iv_get(mScreen, "@@unit");

  src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  srect.x = rect[0];
  srect.y = rect[1];
  srect.w = rect[2];
  srect.h = rect[3];

  d_p = RSTRUCT_PTR(dst_unit);
  drect.x = NUM2INT(*(d_p + 1));
  drect.y = NUM2INT(*(d_p + 2));
  drect.w = NUM2INT(*(d_p + 3));
  drect.h = NUM2INT(*(d_p + 4));

  SDL_BlitSurface(src, &srect, dst, &drect);
  return self;
}

/*
*/
static VALUE sprite_render_rect2_to_sprite(VALUE self, VALUE vdst, VALUE vrect)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;
  int rect[4];

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  sprite_get_rect(vrect, &(rect[0]));
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  src.rect.x = rect[0];
  src.rect.y = rect[1];
  src.rect.w = rect[2];
  src.rect.h = rect[3];
  render_to_inner(&src, &dst);
  return self;
}

/*
*/
static VALUE sprite_render_rect_xy(VALUE self, VALUE vrect, VALUE vx, VALUE vy)
{
  VALUE src_unit, dst_unit, *s_p, *d_p;
  SDL_Surface *src, *dst;
  SDL_Rect srect, drect;
  int rect[4];

  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  sprite_get_rect(vrect, &(rect[0]));

  src_unit = rb_iv_get(self, "@unit");
  dst_unit = rb_iv_get(mScreen, "@@unit");

  src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  s_p = RSTRUCT_PTR(src_unit);
  srect.x = NUM2INT(*(s_p + 1)) + rect[0];
  srect.y = NUM2INT(*(s_p + 2)) + rect[1];
  srect.w = rect[2];
  srect.h = rect[3];

  d_p = RSTRUCT_PTR(dst_unit);
  drect.x = NUM2INT(*(d_p + 1)) + NUM2INT(vx);
  drect.y = NUM2INT(*(d_p + 2)) + NUM2INT(vy);
  drect.w = NUM2INT(*(d_p + 3));
  drect.h = NUM2INT(*(d_p + 4));

  SDL_BlitSurface(src, &srect, dst, &drect);
  return self;
}

/*
*/
static VALUE sprite_render_rect_xy_to_sprite(VALUE self, VALUE vdst, VALUE vrect, VALUE vx, VALUE vy)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;
  int rect[4];
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  sprite_get_rect(vrect, &(rect[0]));
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  src.rect.x += rect[0];
  src.rect.y += rect[1];
  src.rect.w = rect[2];
  src.rect.h = rect[3];
  src.x = NUM2INT(vx);
  src.y = NUM2INT(vy);
  render_to_inner(&src, &dst);
  return self;
}

/*
*/
static VALUE sprite_render_rect2_xy(VALUE self, VALUE vrect, VALUE vx, VALUE vy)
{
  VALUE src_unit, dst_unit, *d_p;
  SDL_Surface *src, *dst;
  SDL_Rect srect, drect;
  int rect[4];

  if(rb_iv_get(self, str_visible) == Qfalse) return self;

  sprite_get_rect(vrect, &(rect[0]));

  src_unit = rb_iv_get(self, "@unit");
  dst_unit = rb_iv_get(mScreen, "@@unit");

  src = GetSurface(*(RSTRUCT_PTR(src_unit)+0))->surface;
  dst = GetSurface(*(RSTRUCT_PTR(dst_unit)+0))->surface;

  srect.x = rect[0];
  srect.y = rect[1];
  srect.w = rect[2];
  srect.h = rect[3];

  d_p = RSTRUCT_PTR(dst_unit);
  drect.x = NUM2INT(*(d_p + 1)) + NUM2INT(vx);
  drect.y = NUM2INT(*(d_p + 2)) + NUM2INT(vy);
  drect.w = NUM2INT(*(d_p + 3));
  drect.h = NUM2INT(*(d_p + 4));

  SDL_BlitSurface(src, &srect, dst, &drect);
  return self;
}

/*
*/
static VALUE sprite_render_rect2_xy_to_sprite(VALUE self, VALUE vdst, VALUE vrect, VALUE vx, VALUE vy)
{
  MiyakoBitmap src, dst;
  SDL_Surface *scr;
  int rect[4];

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  sprite_get_rect(vrect, &(rect[0]));
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(self, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  src.rect.x = rect[0];
  src.rect.y = rect[1];
  src.rect.w = rect[2];
  src.rect.h = rect[3];
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
    VALUE fps_str;

    if(interval == 0){ interval = 1; }

    sprintf(str, "%d fps", fps_max / interval);
    fps_str = rb_str_new2((const char *)str);

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


void _miyako_animation_update(){
  anim_m_update(mAnimation);
}

/*
*/
static void maplayer_render_inner(VALUE self, MiyakoBitmap *dst)
{
  int dx, mx, dy, my, bx, by, code;
  int x, y, idx1, idx2;
  MiyakoBitmap src;
  SDL_Surface *scr;
  VALUE mapdat2;

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

  dx = pos_x / mc_chip_size_w;
  mx = pos_x % mc_chip_size_w;
  dy = pos_y / mc_chip_size_h;
  my = pos_y % mc_chip_size_h;

  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  bx = dst->rect.x;
  by = dst->rect.y;

  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
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
*/
static void fixedmaplayer_render_inner(VALUE self, MiyakoBitmap *dst)
{
  int code;
  VALUE mapdat2;

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
    mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
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
*/
static void maplayer_render_to_inner(VALUE self, MiyakoBitmap *dst)
{
  int dx, mx, dy, my, bx, by, code;
  int x, y, idx1, idx2;
  MiyakoBitmap src;
  SDL_Surface *scr;
  VALUE mapdat2;

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

  dx = pos_x / mc_chip_size_w;
  mx = pos_x % mc_chip_size_w;
  dy = pos_y / mc_chip_size_h;
  my = pos_y % mc_chip_size_h;

  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;

  bx = dst->rect.x;
  by = dst->rect.y;

  for(y = 0; y < ch; y++){
    idx1 = (y + dy) % size_h;
    mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = (x + dx) % size_w;
      code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
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
*/
static void fixedmaplayer_render_to_inner(VALUE self, MiyakoBitmap *dst)
{
  int code;
  VALUE mapdat2;

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
    mapdat2 = *(RARRAY_PTR(mapdat) + idx1);
    for(x = 0; x < cw; x++){
      idx2 = x % size_w;
      code = NUM2INT(*(RARRAY_PTR(mapdat2) + idx2));
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
*/
static VALUE maplayer_render(VALUE self)
{
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  maplayer_render_inner(self, &dst);
  return self;
}

/*
*/
static VALUE fixedmaplayer_render(VALUE self)
{
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  fixedmaplayer_render_inner(self, &dst);
  return self;
}

/*
*/
static VALUE maplayer_render_to_sprite(VALUE self, VALUE vdst)
{
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);
  maplayer_render_to_inner(self, &dst);
  return self;
}

/*
*/
static VALUE fixedmaplayer_render_to_sprite(VALUE self, VALUE vdst)
{
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);
  maplayer_render_inner(self, &dst);
  return self;
}

/*
*/
static VALUE map_render(VALUE self)
{
  int i;
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE map_layers;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  map_layers = rb_iv_get(self, "@map_layers");
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }

  return self;
}

/*
*/
static VALUE fixedmap_render(VALUE self)
{
  int i;
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE map_layers;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(mScreen, scr, &dst, Qnil, Qnil, 1);
  map_layers = rb_iv_get(self, "@map_layers");
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    fixedmaplayer_render_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }

  return self;
}

/*
*/
static VALUE map_render_to_sprite(VALUE self, VALUE vdst)
{
  int i;
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE map_layers;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  map_layers = rb_iv_get(self, "@map_layers");
  for(i=0; i<RARRAY_LEN(map_layers); i++){
    maplayer_render_to_inner(*(RARRAY_PTR(map_layers) + i), &dst);
  }

  return self;
}

/*
*/
static VALUE fixedmap_render_to_sprite(VALUE self, VALUE vdst)
{
  int i;
  MiyakoBitmap dst;
  SDL_Surface *scr;
  VALUE map_layers;
  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit(vdst, scr, &dst, Qnil, Qnil, 1);

  map_layers = rb_iv_get(self, "@map_layers");
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
  VALUE units = rb_iv_get(self, "@slist");
  rb_iv_set(self, "@now", *(RARRAY_PTR(units) + NUM2INT(*(RARRAY_PTR(plist) + NUM2INT(num)))));
  return self;
}

/*
:nodoc:
*/
static VALUE sa_update_frame(VALUE self)
{
  VALUE num, loop, plist, waits;
  int pnum, pats;
  int cnt = NUM2INT(rb_iv_get(self, "@cnt"));

  if(cnt > 0){
    cnt--;
    rb_iv_set(self, "@cnt", INT2NUM(cnt));
    return Qfalse;
  }

  num = rb_iv_get(self, "@pnum");
  loop = rb_iv_get(self, "@loop");

  pnum = NUM2INT(num);
  pats = NUM2INT(rb_iv_get(self, "@pats"));
  pnum = (pnum + 1) % pats;

  rb_iv_set(self, "@pnum", INT2NUM(pnum));

  if(loop == Qfalse && pnum == 0){
    rb_funcall(self, rb_intern("stop"), 0);
    return Qfalse;
  }

  sa_set_pat(self);
  plist = rb_iv_get(self, "@plist");
  waits = rb_iv_get(self, "@waits");
  rb_iv_set(self, "@cnt", *(RARRAY_PTR(waits) + NUM2INT(*(RARRAY_PTR(plist) + pnum))));

  return Qtrue;
}

/*
:nodoc:
*/
static VALUE sa_update_wait_counter(VALUE self)
{
  VALUE num, loop, plist, waits;
  int pnum, pats;
  VALUE cnt = rb_iv_get(self, "@cnt");
  VALUE waiting = rb_funcall(cnt, rb_intern("waiting?"), 0);

  if(waiting == Qtrue) return Qfalse;

  num = rb_iv_get(self, "@pnum");
  loop = rb_iv_get(self, "@loop");

  pnum = NUM2INT(num);
  pats = NUM2INT(rb_iv_get(self, "@pats"));
  pnum = (pnum + 1) % pats;

  rb_iv_set(self, "@pnum", INT2NUM(pnum));

  if(loop == Qfalse && pnum == 0){
    rb_funcall(self, rb_intern("stop"), 0);
    return Qfalse;
  }

  sa_set_pat(self);
  plist = rb_iv_get(self, "@plist");
  waits = rb_iv_get(self, "@waits");
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
*/
static VALUE sa_render(VALUE self)
{
  VALUE vsrc, *runit, polist, dir, *move_off, tmp_oxy, tmp_x, tmp_y;
  int num, pos_off, didx;
  MiyakoBitmap src, dst;
  SDL_Surface *scr;

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  vsrc = rb_iv_get(self, "@now");
  runit = RSTRUCT_PTR(vsrc);
  polist = rb_iv_get(self, "@pos_offset");
  dir = rb_iv_get(self, "@dir");

  num = NUM2INT(rb_iv_get(self, "@pnum"));

  move_off = RARRAY_PTR(rb_funcall(*(RARRAY_PTR(rb_iv_get(self, "@move_offset")) + num), id_to_a, 0));

  pos_off = NUM2INT(*(RARRAY_PTR(polist) + num));

  didx = (rb_to_id(dir) == rb_intern("h") ? 2 : 1);

  tmp_oxy = *(runit +  didx);
  tmp_x = *(runit + 5);
  tmp_y = *(runit + 6);

  *(runit + didx) = INT2NUM(NUM2INT(tmp_oxy) - pos_off);
  *(runit + 5) = INT2NUM(NUM2INT(tmp_x) + NUM2INT(*(move_off+0)));
  *(runit + 6) = INT2NUM(NUM2INT(tmp_y) + NUM2INT(*(move_off+1)));

  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(vsrc, mScreen, scr, &src, &dst, Qnil, Qnil, 1);
  render_inner(&src, &dst);

  *(runit + 5) = tmp_x;
  *(runit + 6) = tmp_y;
  *(runit + didx) = tmp_oxy;

  return Qnil;
}

/*
*/
static VALUE sa_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE vsrc, *runit, polist, dir, molist, move_off, tmp_oxy, tmp_x, tmp_y;
  int num, pos_off, didx;
  MiyakoBitmap src, dst;
  SDL_Surface *scr;

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  vsrc = rb_iv_get(self, "@now");
  runit = RSTRUCT_PTR(vsrc);
  polist = rb_iv_get(self, "@pos_offset");
  dir = rb_iv_get(self, "@dir");

  num = NUM2INT(rb_iv_get(self, "@pnum"));

  pos_off = NUM2INT(*(RARRAY_PTR(polist) + num));

  molist = rb_iv_get(self, "@move_offset");
  move_off = *(RARRAY_PTR(molist) + num);

  didx = (rb_to_id(dir) == rb_intern("h") ? 3 : 2);

  tmp_oxy = *(runit +  didx);
  tmp_x = *(runit + 5);
  tmp_y = *(runit + 6);

  *(runit + didx) = INT2NUM(NUM2INT(tmp_oxy) - pos_off);
  *(runit + 5) = INT2NUM(NUM2INT(tmp_x) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nZero)));
  *(runit + 6) = INT2NUM(NUM2INT(tmp_y) + NUM2INT(rb_funcall(move_off, id_kakko, 1, nOne )));

  scr = GetSurface(rb_iv_get(mScreen, "@@screen"))->surface;
  _miyako_setup_unit_2(vsrc, vdst, scr, &src, &dst, Qnil, Qnil, 1);
  render_to_inner(&src, &dst);

  *(runit + 5) = tmp_x;
  *(runit + 6) = tmp_y;
  *(runit + didx) = tmp_oxy;

  return Qnil;
}

/*
*/
static VALUE plane_render(VALUE self)
{
  VALUE sprite, pos, size, osize, vx, vy;
  int x, y, w, h, pos_x, pos_y, ow, oh;

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  sprite = rb_iv_get(self, "@sprite");

  pos = rb_iv_get(self, "@pos");
  size = rb_iv_get(self, "@size");
  osize = rb_funcall(sprite, rb_intern("layout_size"), 0);
  w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));
  ow = NUM2INT(*(RSTRUCT_PTR(osize) + 0));
  oh = NUM2INT(*(RSTRUCT_PTR(osize) + 1));

  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      if(pos_x > 0) pos_x -= ow;
      if(pos_y > 0) pos_y -= oh;
      vx = INT2NUM(pos_x + x * ow);
      vy = INT2NUM(pos_y + y * oh);
      rb_funcall(sprite, rb_intern("render_xy"), 2, vx, vy);
    }
  }

  return Qnil;
}

/*
*/
static VALUE plane_render_to_sprite(VALUE self, VALUE vdst)
{
  VALUE sprite, pos, size, osize, vx, vy;
  int x, y, w, h, pos_x, pos_y, ow, oh;

  VALUE visible = rb_iv_get(self, str_visible);
  if(visible == Qfalse) return self;
  sprite = rb_iv_get(self, "@sprite");

  pos = rb_iv_get(self, "@pos");
  size = rb_iv_get(self, "@size");
  osize = rb_funcall(sprite, rb_intern("layout_size"), 0);
  w = NUM2INT(*(RSTRUCT_PTR(size) + 0));
  h = NUM2INT(*(RSTRUCT_PTR(size) + 1));
  pos_x = NUM2INT(*(RSTRUCT_PTR(pos) + 0));
  pos_y = NUM2INT(*(RSTRUCT_PTR(pos) + 1));
  ow = NUM2INT(*(RSTRUCT_PTR(osize) + 0));
  oh = NUM2INT(*(RSTRUCT_PTR(osize) + 1));

  for(y = 0; y < h; y++){
    for(x = 0; x < w; x++){
      if(pos_x > 0) pos_x -= ow;
      if(pos_y > 0) pos_y -= oh;
      vx = INT2NUM(pos_x + x * ow);
      vy = INT2NUM(pos_y + y * oh);
      rb_funcall(sprite, rb_intern("render_xy_to"), 3, vdst, vx, vy);
    }
  }

  return Qnil;
}

/*
:nodoc:
*/
static VALUE textbox_render(VALUE self)
{
  VALUE wait_cursor, waiting, select_cursor;

  if(rb_iv_get(self, str_visible) == Qfalse){ return self; }
  sprite_render(rb_iv_get(self, str_textarea));
  wait_cursor = rb_iv_get(self, str_wait_cursor);
  if(wait_cursor != Qnil)
  {
    waiting = rb_iv_get(self, str_waiting);
    if(waiting == Qtrue)
    {
      rb_funcall(wait_cursor, id_render, 0);
    }
  }

  if(rb_iv_get(self, str_selecting) == Qtrue)
  {
    rb_funcall(rb_iv_get(self, str_choices), id_render, 0);
    select_cursor = rb_iv_get(self, str_select_cursor);
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
  VALUE wait_cursor, waiting, select_cursor;

  if(rb_iv_get(self, str_visible) == Qfalse){ return self; }
  sprite_render_to_sprite(rb_iv_get(self, str_textarea), dst);
  wait_cursor = rb_iv_get(self, str_wait_cursor);
  if(wait_cursor != Qnil)
  {
    waiting = rb_iv_get(self, str_waiting);
    if(waiting == Qtrue)
    {
      rb_funcall(wait_cursor, id_render_to, 1, dst);
    }
  }

  if(rb_iv_get(self, str_selecting) == Qtrue)
  {
    rb_funcall(rb_iv_get(self, str_choices), id_render_to, 1, dst);
    select_cursor = rb_iv_get(self, str_select_cursor);
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
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
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
#if 0
  rb_define_method(cSpriteAnimation, "render", sa_render, 0);
  rb_define_method(cSpriteAnimation, "render_to", sa_render_to_sprite, 1);
#endif

  rb_define_method(mSpriteBase, "render_xy", sprite_b_render_xy, 2);
  rb_define_method(mSpriteBase, "render_xy_to", sprite_b_render_xy_to_sprite, 3);
  rb_define_singleton_method(cSprite, "render_to", sprite_c_render_to_sprite, 2);
  rb_define_method(cSprite, "render", sprite_render, 0);
  rb_define_method(cSprite, "render_to", sprite_render_to_sprite, 1);
  rb_define_method(cSprite, "render_xy", sprite_render_xy, 2);
  rb_define_method(cSprite, "render_xy_to", sprite_render_xy_to_sprite, 3);
  rb_define_method(cSprite, "render_rect", sprite_render_rect, 1);
  rb_define_method(cSprite, "render_rect_to", sprite_render_rect_to_sprite, 2);
  rb_define_method(cSprite, "render_rect2", sprite_render_rect2, 1);
  rb_define_method(cSprite, "render_rect2_to", sprite_render_rect2_to_sprite, 2);
  rb_define_method(cSprite, "render_rect_xy", sprite_render_rect_xy, 3);
  rb_define_method(cSprite, "render_rect_xy_to", sprite_render_rect_xy_to_sprite, 4);
  rb_define_method(cSprite, "render_rect2_xy", sprite_render_rect2_xy, 3);
  rb_define_method(cSprite, "render_rect2_xy_to", sprite_render_rect2_xy_to_sprite, 4);

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
