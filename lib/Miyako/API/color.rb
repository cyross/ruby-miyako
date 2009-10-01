# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.1
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

module Miyako
  #==色を管理するクラス
  #
  #色情報は、[r(赤),g(緑),b(青),a(透明度)]、[r,g,b,a(透明度)]の2種類の配列
  #
  #それぞれの要素の値は0〜255の範囲
  #
  #4要素必要な色情報に3要素の配列を渡すと、自動的に4要素目(値は255)が挿入される
  #
  #(注)本クラスで採用する透明度と、画像が持つ透明度とは別物
  class Color
    @@symbol2color = {:black       => [  0,  0,  0, 255],
                      :white       => [255,255,255, 255],
                      :blue        => [  0,  0,255, 255],
                      :green       => [  0,255,  0, 255],
                      :red         => [255,  0,  0, 255],
                      :cyan        => [  0,255,255, 255],
                      :purple      => [255,  0,255, 255],
                      :yellow      => [255,255,  0, 255],
                      :light_gray  => [200,200,200, 255],
                      :half_gray   => [128,128,128, 255],
                      :half_blue   => [  0,  0,128, 255],
                      :half_green  => [  0,128,  0, 255],
                      :half_red    => [128,  0,  0, 255],
                      :half_cyan   => [  0,128,128, 255],
                      :half_purple => [128,  0,128, 255],
                      :half_yellow => [128,128,  0, 255],
                      :dark_gray   => [ 80, 80, 80, 255],
                      :dark_blue   => [  0,  0, 80, 255],
                      :dark_green  => [  0, 80,  0, 255],
                      :dark_red    => [ 80,  0,  0, 255],
                      :dark_cyan   => [  0, 80, 80, 255],
                      :dark_purple => [ 80,  0, 80, 255],
                      :dark_yellow => [ 80, 80,  0, 255]}
    @@symbol2color.default = nil

    #===シンボルから色情報を取得する
    #_name_::色に対応したシンボル(以下の一覧参照)。存在しないシンボルを渡したときはエラーを返す
    #返却値::シンボルに対応した4要素の配列
    #
    #シンボル::     色配列([赤,緑,青,透明度])
    #:black::       [  0,  0,  0, 255]
    #:white::       [255,255,255, 255]
    #:blue::        [  0,  0,255, 255]
    #:green::       [  0,255,  0, 255]
    #:red::         [255,  0,  0, 255]
    #:cyan::        [  0,255,255, 255]
    #:purple::      [255,  0,255, 255]
    #:yellow::      [255,255,  0, 255]
    #:light_gray::  [200,200,200, 255]
    #:half_gray::   [128,128,128, 255]
    #:half_blue::   [  0,  0,128, 255]
    #:half_green::  [  0,128,  0, 255]
    #:half_red::    [128,  0,  0, 255]
    #:half_cyan::   [  0,128,128, 255]
    #:half_purple:: [128,  0,128, 255]
    #:half_yellow:: [128,128,  0, 255]
    #:dark_gray::   [ 80, 80, 80, 255]
    #:dark_blue::   [  0,  0, 80, 255]
    #:dark_green::  [  0, 80,  0, 255]
    #:dark_red::    [ 80,  0,  0, 255]
    #:dark_cyan::   [  0, 80, 80, 255]
    #:dark_purple:: [ 80,  0, 80, 255]
    #:dark_yellow:: [ 80, 80,  0, 255]
    def Color.[](name, alpha = nil)
      c = (@@symbol2color[name.to_sym].dup or raise MiyakoError, "Illegal Color Name! : #{name}")
      c[3] = alpha if alpha
      return c
    end

    #===Color.[]メソッドで使用できるシンボルと色情報との対を登録する
    #_name_:: 色に対応させるシンボル
    #_value_:: 色情報を示す3〜4要素の配列。3要素のときは4要素目を自動的に追加する
    def Color.[]=(name, value)
      @@symbol2color[name.to_sym] = value
      @@symbol2color[name.to_sym] << 255 if value.length == 3
    end

    #===様々な形式のデータを色情報に変換する
    #_v_::変換対象のインスタンス。変換可能な内容は以下の一覧参照
    #_alpha_::透明度。デフォルトはnil
    #
    #インスタンス:: 書式
    #配列:: 最低3要素の数値の配列
    #文字列:: ”＃RRGGBB"で示す16進数の文字列、もしくは"red"、"black"など。使える文字列はColor.[]で使えるシンボルに対応
    #数値:: 32bitの値を8bitずつ割り当て(aaaaaaaarrrrrrrrggggggggbbbbbbbb)
    #シンボル:: Color.[]と同じ
    def Color::to_rgb(v, alpha = nil)
      c = (v.to_miyako_color or raise MiyakoError, "Illegal parameter")
      c[3] = alpha if alpha
      return c
    end

    #===色情報をColor.[]メソッドで使用できるシンボルと色情報との対を登録する
    #_cc_:: 色情報(シンボル、文字列)
    #_value_:: 色情報を示す3〜4要素の配列。3要素のときは4要素目を自動的に追加する
    def Color::to_s(cc)
      c = to_rgb(cc)
      return "[#{c[0]},#{c[1]},#{c[2]},#{c[3]}]"
    end
  end
end

# for duck typing
class Object
  def to_miyako_color #:nodoc:
    raise Miyako::MiyakoError, "Illegal color parameter class!"
  end
end

class String
  def to_miyako_color #:nodoc:
    case self
    when /\A\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\,\s*(\d+)\s*\]\z/
      #4要素の配列形式
      return [$1.to_i, $2.to_i, $3.to_i, $4.to_i]
    when /\A\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\z/
      #4個の数列形式
      return [$1.to_i, $2.to_i, $3.to_i, $4.to_i]
    when /\A\#([\da-fA-F]{8})\z/
        #HTML形式(＃RRGGBBAA)
        return [$1[0,2].hex, $1[2,2].hex, $1[4,2].hex, $1[6,2].hex]
    when /\A\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]\z/
      #3要素の配列形式
      return [$1.to_i, $2.to_i, $3.to_i, 255]
    when /\A\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\z/
      #3個の数列方式
      [$1.to_i, $2.to_i, $3.to_i, 255]
    when /\A\#([\da-fA-F]{6})\z/
      #HTML形式(＃RRGGBB)
      return [$1[0,2].hex, $1[2,2].hex, $1[4,2].hex, 255]
    else return self.to_sym.to_miyako_color
    end
  end
end

class Symbol
  def to_miyako_color #:nodoc:
    return Miyako::Color[self]
  end
end

class Integer
  def to_miyako_color #:nodoc:
    return [(self >> 16) & 0xff, (self >> 8) & 0xff, self & 0xff, (self >> 24) & 0xff]
  end
end

class Array
  def to_miyako_color #:nodoc:
    raise Miyako::MiyakoError, "Color Array needs more than 3 elements : #{self.length} elements" if self.length < 3
    return (self[0,3] << 255) if self.length == 3
    return self[0,4]
  end
end
