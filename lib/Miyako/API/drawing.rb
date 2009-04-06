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
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_color_:: 塗りつぶす色。Color.to_rgbメソッドのパラメータでの指定が可能
    #返却値:: 自分自身を返す
    def Drawing.fill(sprite, color)
      color = Color.to_rgb(color)
      sprite.bitmap.draw_rect(0,0, sprite.bitmap.w, sprite.bitmap.h, color, true, color[3]==255 ? nil : color[3])
      return self
    end

    #===画像内に直線を引く
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.line(sprite, rect, color, aa = false)
      color = Color.to_rgb(color)
      sprite.bitmap.draw_line(*rect.to_a[0..3], color, aa, color[3]==255 ? nil : color[3])
      return self
    end

    #===画像内に矩形を描画する
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.rect(sprite, rect, color, fill = false)
      color = Color.to_rgb(color)
      sprite.bitmap.draw_rect(*rect.to_a[0..3], color, fill, color[3]==255 ? nil : color[3])
      return self
    end

    #===画像内に円を描画する
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_point_:: 中心の位置。2要素の整数の配列、もしくはPoint構造体を使用可能
    #_r_:: 円の半径。整数を使用可能。
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.circle(sprite, point, r, color, fill = false, aa = false)
      color = Color.to_rgb(color)
      sprite.bitmap.draw_circle(*point.to_a[0..1], r, color, fill, aa, color[3]==255 ? nil : color[3])
      return self
    end

    #===画像内に楕円を描画する
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_fill_:: 描画の属性。falseで縁のみ描画、trueで内部も塗りつぶす。デフォルトはfalse
    #_aa_:: アンチエイリアスの指定。trueでオン。デフォルトはfalse
    #返却値:: 自分自身を返す
    def Drawing.ellipse(sprite, rect, color, fill = false, aa = false)
      color = Color.to_rgb(color)
      sprite.bitmap.draw_ellipse(*rect.to_a[0..3], color, fill, aa, color[3]==255 ? nil : color[3])
    end
  end
end
