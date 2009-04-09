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
