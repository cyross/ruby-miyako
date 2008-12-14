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

# 線形描画モジュール
module Miyako
  #==線形描画モジュール
  module Drawing
      @@draw_list = {:line    => {:normal => {:solid         => lambda{|b, l| b.draw_line(*l)},
                                             :anti_aliasing => lambda{|b, l| b.draw_aa_line(*l)}},
                                 :fill   => {:solid         => lambda{|b, l| b.draw_line(*l)},
                                             :anti_aliasing => lambda{|b, l| b.draw_aa_line(*l)}}},
                    :rect    => {:normal => {:solid         => lambda{|b, l| b.draw_rect(*l)},
                                             :anti_aliasing => lambda{|b, l| b.draw_rect(*l)}},
                                 :fill   => {:solid         => lambda{|b, l| b.fill_rect(*l)},
                                             :anti_aliasing => lambda{|b, l| b.fill_rect(*l)}}},
                    :circle  => {:normal => {:solid         => lambda{|b, l| b.draw_circle(*l)},
                                             :anti_aliasing => lambda{|b, l| b.draw_aa_circle(*l)}},
                                 :fill   => {:solid         => lambda{|b, l| b.draw_filled_circle(*l)},
                                             :anti_aliasing => lambda{|b, l| b.draw_aa_filled_circle(*l)}}},
                    :ellipse => {:normal => {:solid         => lambda{|b, l| b.draw_ellipse(*l)},
                                             :anti_aliasing => lambda{|b, l| b.draw_aa_ellipse(*l)}},
                                 :fill   => {:solid         => lambda{|b, l| b.draw_filled_ellipse(*l)},
                                             :anti_aliasing => lambda{|b, l| b.drawAAFilledEllipse(*l)}}}}

    #===画像全体を指定の色で塗りつぶす
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_color_:: 塗りつぶす色。Color.to_rgbメソッドのパラメータでの指定が可能
    #返却値:: 自分自身を返す
    def Drawing.fill(sprite, color)
      sprite.bitmap.fill_rect(0,0,sprite.bitmap.w,sprite.bitmap.h, Color.to_rgb(color))
      return self
    end

    #===画像内に直線を引く
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normal固定。
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def Drawing.line(sprite, rect, color, attribute = :normal, aa = :solid)
      raise MiyakoError, "not have Drawing attribute! #{attribute}" unless @@draw_list[:line].has_key?(attribute)
      raise MiyakoError, "not have Drawing anti aliasing mode! #{aa}" unless @@draw_list[:line][attribute].has_key?(aa)
      @@draw_list[:line][attribute][aa].call(sprite.bitmap, rect.to_a << Color.to_rgb(color))
      return self
    end

    #===画像内に矩形を描画する
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normalで縁のみ描画、:fillで内部も塗りつぶす
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def Drawing.rect(sprite, rect, color, attribute = :normal, aa = :solid)
      raise MiyakoError, "not have Drawing attribute! #{attribute}" unless @@draw_list[:rect].has_key?(attribute)
      raise MiyakoError, "not have Drawing anti aliasing mode! #{aa}" unless @@draw_list[:rect][attribute].has_key?(aa)
      @@draw_list[:rect][attribute][aa].call(sprite.bitmap, rect.to_a << Color.to_rgb(color))
      return self
    end

    #===画像内に円を描画する
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_point_:: 中心の位置。2要素の整数の配列、もしくはPoint構造体を使用可能
    #_r_:: 円の半径。整数を使用可能。
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normalで縁のみ描画、:fillで内部も塗りつぶす
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def Drawing.circle(sprite, point, r, color, attribute = :normal, aa = :solid)
      raise MiyakoError, "not have Drawing attribute! #{attribute}" unless @@draw_list[:circle].has_key?(attribute)
      raise MiyakoError, "not have Drawing anti aliasing mode! #{aa}" unless @@draw_list[:circle][attribute].has_key?(aa)
      @@draw_list[:circle][attribute][aa].call(sprite.bitmap, point.to_a << r << Color.to_rgb(color))
      return self
    end

    #===画像内に楕円を描画する
    #_sprite_:: 描画対象のスプライト(SDL::Surfaceクラスインスタンスを返すbitmapメソッドを持つインスタンス)
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normalで縁のみ描画、:fillで内部も塗りつぶす
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def Drawing.ellipse(sprite, rect, color, attribute = :normal, aa = :solid)
      raise MiyakoError, "not have Drawing attribute! #{attribute}" unless @@draw_list[:ellipse].has_key?(attribute)
      raise MiyakoError, "not have Drawing anti aliasing mode! #{aa}" unless @@draw_list[:ellipse][attribute].has_key?(aa)
      @@draw_list[:ellipse][attribute][aa].call(sprite.bitmap, rect.to_a << Color.to_rgb(color))
    end
  end
end
