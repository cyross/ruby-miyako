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
  #基本的なことは、Sprite.renderで行うことが出来るが、凝った処理を行う場合は、SpriteUnitを使う
  #--
  #SpriteUnit = Struct.new([:dp], :bitmap, :ox, :oy, :ow, :oh, :x, :y, [:effect], [:viewport], :angle, :xscale, :yscale, :cx, :cy)
  #++
  #([数字])は、配列として認識したときのインデックス番号に対応(Struct#[]メソッドを呼び出した時のインデックス)
  #:bitmap([0]) -> 画像データ(SDL::Surfaceクラスのインスタンス)
  #:ox([1])     -> 描画開始位置(x方向)
  #:oy([2])     -> 描画開始位置(y方向)
  #:ow([3])     -> 描画幅
  #:oh([4])     -> 描画高さ
  #:x([5])     -> 描画幅
  #:y([6])     -> 描画高さ
  #:angle([7])  -> 回転角度(ラジアン単位)
  #:xscale([8]) -> X方向拡大・縮小・鏡像の割合(実数。変換後の幅が32768を切る様にすること)
  #:yscale([9]) -> Y方向拡大・縮小・鏡像の割合(実数。変換後の幅が32768を切る様にすること)
  #:cx([10])     -> 回転・拡大・縮小・鏡像の中心座標(x方向)
  #:cy([11])     -> 回転・拡大・縮小・鏡像の中心座標(y方向)
  SpriteUnit = SpriteUnitBase.new(:bitmap, :ox, :oy, :ow, :oh, :x, :y, :angle, :xscale, :yscale, :cx, :cy)

  #==SpriteUnit生成ファクトリクラス
  #SpriteUnit構造体のインスタンスを生成するためのクラス
  class SpriteUnitFactory
    PARAMS = [:bitmap, :ox, :oy, :ow, :oh, :x, :y, :angle, :xscale, :yscale, :cx, :cy]
    #==SpriteUnitのインスタンスを生成する
    #params: 初期化するSpriteUnit構造体の値。ハッシュ引数。引数のキーは、SpriteUnitのアクセサ名と同一。省略可能
    def SpriteUnitFactory.create(params = nil)
      unit = SpriteUnit.new(nil, 0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0, 0)
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
