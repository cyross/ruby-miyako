# -*- encoding: utf-8 -*-
# Miyako Extension Raster Scroll
=begin
Miyako Extention Library v2.0
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
=end

module Miyako
  #==あとで書く
  #返却値:: あとで書く
  class RasterScroll < Effect
    #===あとで書く
    #_sspr_:: あとで書く
    #_dspr_:: あとで書く
    #返却値:: あとで書く
    def initialize(sspr, dspr = nil)
    super
    @lines = 0
    @h = @src.h
    @size = 0
    @angle = 0
    @sangle = 0
    @dangle = 0
    @fade_out = false
    @fo_size = 0
  end
    
    #===あとで書く
    #_w_:: あとで書く
    #_param_:: あとで書く
    #返却値:: あとで書く
    def start(w, *param)
    super
    @lines = @param[0]
    @size = @param[1]
    @sangle = @param[2]
    @dangle = @param[3]
    @h = @h / @lines
    @fade_out = false
    @fo_size = 0
  end
  
    #===あとで書く
    #_screen_:: あとで書く
    #返却値:: あとで書く
    def update(screen)
    @angle = @sangle
    @h.times{|y|
      rsx = @size * Math.sin(@angle)
      SDL.blitSurface(@src.bitmap, @src.ox, @src.oy + y * @lines, @src.ow, @lines, screen, @src.x + rsx, @src.y + y * @lines)
      @angle = @angle + @dangle
    }
    if @cnt == 0
      if @fade_out
        @fo_cnt -= 1
        return if @fo_cnt != 0
        @size = @size - @fo_size
        @fo_cnt = @fo_wait
        @effecting = false if @size <= 0
      end
      @sangle = (@sangle + 1) % 360
      @cnt = @wait
    else
      @cnt = @cnt - 1
    end
  end
  
    #===あとで書く
    #_fs_:: あとで書く
    #_fw_:: あとで書く
    #返却値:: あとで書く
    def fade_out(fs, fw)
    @fo_size = fs
    @fo_wait = fw
    @fo_cnt = @fo_wait
    @fade_out = true
  end
  end
end
