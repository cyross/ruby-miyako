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

extern void _miyako_setup_unit(VALUE unit, SDL_Surface *screen, MiyakoBitmap *mb, VALUE x, VALUE y, int use_yield);
extern void _miyako_setup_unit_2(VALUE unit_s, VALUE unit_d,
                                SDL_Surface *screen,
                                MiyakoBitmap *mb_s, MiyakoBitmap *mb_d,
                                VALUE x, VALUE y, int use_yield);
extern int _miyako_init_rect(MiyakoBitmap *src, MiyakoBitmap *dst, MiyakoSize *size);
extern void _miyako_yield_unit_1(MiyakoBitmap *src);
extern void _miyako_yield_unit_2(MiyakoBitmap *src, MiyakoBitmap *dst);
extern void _miyako_animation_update();
extern void _miyako_audio_update();
extern void _miyako_input_update();
extern void _miyako_counter_update();
extern void _miyako_counter_post_update();
extern void _miyako_screen_render();
extern void _miyako_screen_pre_render();
extern void _miyako_screen_render_screen();
extern void _miyako_screen_update_tick();
extern void _miyako_sprite_list_render(VALUE splist);
extern void _miyako_sprite_list_render_to(VALUE splist, VALUE dst);
extern void _miyako_sprite_list_update_animation(VALUE splist);
extern void _miyako_screen_clear();
extern VALUE _miyako_layout_pos(VALUE self);
extern VALUE _miyako_layout_size(VALUE self);
extern VALUE _miyako_layout_x(VALUE self);
extern VALUE _miyako_layout_y(VALUE self);
extern VALUE _miyako_layout_move(VALUE self, VALUE dx, VALUE dy);
extern VALUE _miyako_layout_move_to(VALUE self, VALUE x, VALUE y);
extern VALUE _miyako_sprite_render(VALUE sprite);
extern VALUE _miyako_sprite_render_xy(VALUE sprite, VALUE x, VALUE y);
