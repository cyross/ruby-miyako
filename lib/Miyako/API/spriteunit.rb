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
  #SpriteUnit = Struct.new(:bitmap, :ox, :oy, :ow, :oh, :x, :y, :cx, :cy)
  #++
  class SpriteUnitBase < Struct
    #===位置を変更する(変化量を指定)
    #位置を右方向へdxピクセル、下方向へdyピクセル移動する
    #ブロックを渡すと、ブロック評価中の位置を変更する
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move(dx, dy)
      o = [self.x, self.y]
      self.x+=dx
      self.y+=dy
      if block_given?
        yield
        self.x, self.y = o
      end
      return self
    end

    #===位置を変更する(位置指定)
    #左上を(0.0)として、位置を右xピクセル、下yピクセルの位置移動する
    #ブロックを渡すと、ブロック評価中の位置を変更する
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to(x, y)
      o = [self.x, self.y]
      self.x=x
      self.y=y
      if block_given?
        yield
        self.x, self.y = o
      end
      return self
    end
    #また、ブロックを渡せば、複製したインスタンスに補正を欠けることが出来る(画像変換も可能)

    #===自分自身を返す
    #SpriteUnit対応
    #ダックタイピング用のメソッド
    #得られるインスタンスは複写していないので、インスタンスの値を調整するには、dupメソッドで複製する必要がある
    #返却値:: 自分自身
    def to_unit
      return self
    end

    #===スプライトを生成して返す
    #ダックタイピング用のメソッド
    #所持しているSpriteUnitから、Spriteクラスのインスタンスを生成する
    #但し、bitmapの設定は:type=>:alpha_channelのみ
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 生成したスプライト
    def to_sprite
      sprite = Sprite.new(:unit=>self, :type=>:ac)
      yield sprite if block_given?
      return sprite
    end

    #===画像の表示矩形を取得する
    #画像が表示されているときの矩形を取得する。矩形は、[x,y,ow,oh]で取得する。
    #返却値:: 生成された矩形
    def rect
      return Rect.new(self.x, self.y, self.ow, self.oh)
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #但し、SpriteUnitの場合は最大の大きさ=画像の大きさなので、rectと同じ値が得られる
    #返却値:: 画像の大きさ(Rect構造体のインスタンス)
    def broad_rect
      return self.rect
    end
  end

  #==スプライト出力情報構造体
  #基本的なことは、Sprite.renderで行うことが出来るが、凝った処理を行う場合は、SpriteUnitを使う
  #--
  #SpriteUnit = Struct.new([:dp], :bitmap, :ox, :oy, :ow, :oh, :x, :y, :cx, :cy)
  #++
  #([数字])は、配列として認識したときのインデックス番号に対応(Struct#[]メソッドを呼び出した時のインデックス)
  #:bitmap([0]) -> 画像データ(SDL::Surfaceクラスのインスタンス)
  #:ox([1])     -> 描画開始位置(x方向)
  #:oy([2])     -> 描画開始位置(y方向)
  #:ow([3])     -> 描画幅
  #:oh([4])     -> 描画高さ
  #:x([5])     -> 描画幅
  #:y([6])     -> 描画高さ
  #:cx([7])     -> 回転・拡大・縮小・鏡像の中心座標(x方向)
  #:cy([8])     -> 回転・拡大・縮小・鏡像の中心座標(y方向)
  SpriteUnit = SpriteUnitBase.new(:bitmap, :ox, :oy, :ow, :oh, :x, :y, :cx, :cy)

  #==SpriteUnit生成ファクトリクラス
  #SpriteUnit構造体のインスタンスを生成するためのクラス
  class SpriteUnitFactory
    PARAMS = [:bitmap, :ox, :oy, :ow, :oh, :x, :y, :cx, :cy]
    #==SpriteUnitのインスタンスを生成する
    #params: 初期化するSpriteUnit構造体の値。ハッシュ引数。引数のキーは、SpriteUnitのアクセサ名と同一。省略可能
    def SpriteUnitFactory.create(params = nil)
      unit = SpriteUnit.new(nil, 0, 0, 0, 0, 0, 0, 0, 0)
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
