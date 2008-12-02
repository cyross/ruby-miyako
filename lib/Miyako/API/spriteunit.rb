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

# スプライト関連クラス群
module Miyako
  #==SpriteUnitを生成するための構造体クラス
  #Structクラスからの継承
  #--
  #SpriteUnit = Struct.new([:dp], :bitmap, :ox, :oy, :ow, :oh, :x, :y, :dx, :dy, [:effect], [:viewport], :angle, :xscale, :yscale, :px, :py, :qx, :qy)
  #++
  class SpriteUnitBase < Struct
    #===位置を変更する(変化量を指定)
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move(dx, dy)
      self.x+=dx
      self.y+=dy
      return self
    end

    #===位置を変更する(位置指定)
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to(x, y)
      self.x=x
      self.y=y
      return self
    end

    #===自分自身を返す
    #SpriteUnit対応
    #ダックタイピング用のメソッド
    #返却値:: 自分自身(複製して返す)
    def to_unit
      return self.dup
    end
  end

  #==スプライト出力情報構造体
  #--
  #SpriteUnit = Struct.new([:dp], :bitmap, :ox, :oy, :ow, :oh, :x, :y, :dx, :dy, [:effect], [:viewport], :angle, :xscale, :yscale, :px, :py, :qx, :qy)
  #++
  SpriteUnit = SpriteUnitBase.new(:bitmap, :ox, :oy, :ow, :oh, :x, :y, :dx, :dy, :angle, :xscale, :yscale, :px, :py, :qx, :qy)

  #==SpriteUnit生成ファクトリクラス
  #SpriteUnit構造体のインスタンスを生成するためのクラス
  class SpriteUnitFactory
    PARAMS = [:bitmap, :ox, :oy, :ow, :oh, :x, :y, :dx, :dy, :angle, :xscale, :yscale, :px, :py, :qx, :qy]
    #==SpriteUnitのインスタンスを生成する
    #params: 初期化するSpriteUnit構造体の値。ハッシュ引数。引数のキーは、SpriteUnitのアクセサ名と同一。省略可能
    def SpriteUnitFactory.create(params = nil)
      unit = SpriteUnit.new(nil, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0, 0, 0, 0)
      return SpriteUnitFactory.apply(unit, params)
    end

    #==SpriteUnitの各アクセサに対応した値を設定する
    #unit: 設定対象のSpriteUnit構造体
    #params: 設定するSpriteUnit構造体の値。ハッシュ引数。引数のキーは、SpriteUnitのアクセサ名と同一
    def SpriteUnitFactory.apply(unit, params)
      PARAMS.each{|prm| unit[prm] = params[prm] if params.has_key?(prm) } if params
      return unit 
    end
  end
end
