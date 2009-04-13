# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.0
Copyright (C) 2007-2009  Cyross Makoto

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

# 線形描画モジュール
module Miyako
  #==線形描画モジュール
  module Drawing
    #===画像全体を指定の色で塗りつぶす
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_color_:: 塗りつぶす色。Color.to_rgbメソッドのパラメータでの指定が可能
    #返却値:: 自分自身を返す
    def Drawing.fill(sprite, color)
      color = Color.to_rgb(color)
      methods = sprite.methods
      raise MiyakoError, 
            "this method needs sprite have to_method or bitmap method!" if !methods.include?(:to_unit) && !methods.include?(:bitmap)
      bitmap = methods.include?(:to_unit) ? sprite.to_unit.bitmap : methods.include?(:bitmap) ? sprite.bitmap : sprite
      bitmap.draw_rect(0,0, bitmap.w, bitmap.h, color, true, color[3]==255 ? nil : color[3])
      return self
    end

    #===画像内に点を描画する
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.pset(sprite, point, color)
      methods = sprite.methods
      raise MiyakoError, 
            "this method needs sprite have to_method or bitmap method!" if !methods.include?(:to_unit) && !methods.include?(:bitmap)
      bitmap = sprite.methods.include?(:to_unit) ? sprite.to_unit.bitmap : sprite.bitmap
      bitmap[point[0], point[1]] = Color.to_rgb(color)
      return self
    end

    #===画像内に直線を引く
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.line(sprite, rect, color, aa = false)
      color = Color.to_rgb(color)
      methods = sprite.methods
      raise MiyakoError, 
            "this method needs sprite have to_method or bitmap method!" if !methods.include?(:to_unit) && !methods.include?(:bitmap)
      bitmap = sprite.methods.include?(:to_unit) ? sprite.to_unit.bitmap : sprite.bitmap
      bitmap.draw_line(
        rect[0], rect[1], rect[0]+rect[2]-1, rect[1]+rect[3]-1,
        color, aa, color[3]==255 ? nil : color[3]
      )
      return self
    end

    #===画像内に矩形を描画する
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.rect(sprite, rect, color, fill = false)
      color = Color.to_rgb(color)
      methods = sprite.methods
      raise MiyakoError, 
            "this method needs sprite have to_method or bitmap method!" if !methods.include?(:to_unit) && !methods.include?(:bitmap)
      bitmap = sprite.methods.include?(:to_unit) ? sprite.to_unit.bitmap : sprite.bitmap
      bitmap.draw_rect(
        rect[0], rect[1], rect[2]-1, rect[3]-1,
        color, fill, color[3]==255 ? nil : color[3]
      )
      return self
    end

    #===画像内に円を描画する
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_point_:: 中心の位置。2要素の整数の配列、もしくはPoint構造体を使用可能
    #_r_:: 円の半径。整数を使用可能。
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.circle(sprite, point, r, color, fill = false, aa = false)
      color = Color.to_rgb(color)
      methods = sprite.methods
      raise MiyakoError, 
            "this method needs sprite have to_method or bitmap method!" if !methods.include?(:to_unit) && !methods.include?(:bitmap)
      bitmap = sprite.methods.include?(:to_unit) ? sprite.to_unit.bitmap : sprite.bitmap
      bitmap.draw_circle(*point.to_a[0..1], r, color, fill, aa, color[3]==255 ? nil : color[3])
      return self
    end

    #===画像内に楕円を描画する
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_point_:: 楕円の中心位置。2要素の整数の配列かPoint構造体を使用
    #_rx_:: x方向半径。1以上の整数
    #_ry_:: y方向半径。1以上の整数
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.ellipse(sprite, point, rx, ry, color, fill = false, aa = false)
      color = Color.to_rgb(color)
      methods = sprite.methods
      raise MiyakoError, 
            "this method needs sprite have to_method or bitmap method!" if !methods.include?(:to_unit) && !methods.include?(:bitmap)
      bitmap = sprite.methods.include?(:to_unit) ? sprite.to_unit.bitmap : sprite.bitmap
      bitmap.draw_ellipse(
        point[0], point[1], rx, ry,
        color, fill, aa, color[3]==255 ? nil : color[3]
      )
    end

    #===画像内に多角形を描画する
    #多角形を描画するとき、頂点のリストは、[x,y]で示した配列のリスト(配列)を渡す。
    #引数spriteにto_unitもしくはbitmapメソッドが定義されていない場合は例外が発生する。
    #_sprite_:: 描画対象のスプライト(to_unitもしくはbitmapメソッドを持つインスタンス)
    #_points_:: 座標の配列。2要素の整数の配列かPoint構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.polygon(sprite, points, color, fill = false, aa = false)
    end
  end
end
