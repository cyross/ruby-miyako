# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.0
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
++
=end

module Miyako
  #==ビューポートクラス
  #描画時の表示範囲を変更する
  #画面全体を基準(640x480の画面のときは(0,0)-(639,479)の範囲)として、範囲を設定する
  #範囲の設定はいつでも行えるが、描画にはrenderメソッドを呼び出した時の値が反映される
  class Viewport
    def initialize(x, y, w, h)
      @rect = Rect.new(x, y, w, h)
    end

    def render(params = nil)
      Screen.screen.set_clip_rect(@rect)
    end

    def move(dx,dy)
      @rect.move(dx,dy)
    end

    def move_to(x,y)
      @rect.move(x,y)
    end
    
    def dispose
      @rect = nil
      @unit = nil
    end
    
    def viewport
      return @rect
    end
  end
end