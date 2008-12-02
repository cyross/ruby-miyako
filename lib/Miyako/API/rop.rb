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

# ラスタオペレーション関連クラス群
module Miyako
  #==ラスタオペレーションモジュール
  module ROP
    #===位置を変更する(変化量を指定)
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move(dx, dy)
      self.x+=dx
      self.y+=dy
      return self
    end
  end

  #==ピクセル情報構造体
  Pixel = Struct.new(:r, :g, :b, :a)
end
