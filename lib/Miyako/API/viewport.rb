# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.1
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
  # 描画時の表示範囲を変更する
  # 画面全体を基準(640x480の画面のときは(0,0)-(639,479)の範囲)として、範囲を設定する
  # 範囲の設定はいつでも行えるが、描画にはrenderメソッドを呼び出した時の値が反映される
  class Viewport
    include SpriteBase
    include Animation

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)

    #===ビューポートのインスタンスを生成する
    #_x_:: ビューポートの左上位置(x座標)
    #_y_:: ビューポートの左上位置(y座標)
    #_w_:: ビューポートの幅(共に1以上、0以下のときはエラーが出る)
    #_h_:: ビューポートの高さ(共に1以上、0以下のときはエラーが出る)
    def initialize(x, y, w, h)
      raise MiyakoValueError, "Illegal size! w:#{w} h:#{h}" if (w <= 0 || h <= 0)
      @rect = Rect.new(x, y, w, h)
      @sq = Rect.new(x, y, x+w-1, y+h-1)
      @visible = true
    end

    def initialize_copy(obj) #:nodoc:
      @rect = @rect.dup
      @sq = @sq.dup
    end

    #===ビューポートの内容を画面に反映する
    # ブロックが渡ってきたときは、範囲を変更して指定することが出来る(この変更は、本メソッドを呼ぶ時だけ有効)
    # ブロックの引数は、|Rect構造体|が渡される。
    #_block_:: 呼び出し時にブロック付き呼び出しが行われたときのブロック本体。
    #呼び先に渡すことが出来る。ブロックがなければnilが入る
    def render(&block)
      return unless @visible
      if block_given?
        rect = @rect.dup
        yield rect
        Screen.bitmap.set_clip_rect(*rect)
      else
        Screen.bitmap.set_clip_rect(*@rect)
      end
    end

    #===ビューポートの左上位置を変更する
    # 移動量を指定して、位置を変更する
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_dx_:: 移動量(x方向)
    #_dy_:: 移動量(y方向)
    #返却値:: 自分自身を返す
    def move!(dx,dy)
      orect = rect.to_a[0..1]
      osq = sq.to_a[0..1]
      @rect.move!(dx,dy)
      @sq.move!(dx, dy)
      if block_given?
        unless yield(self)
          @rect.move_to!(*orect)
          @sq.move_to!(*osq)
        end
      end
      return self
    end

    #===ビューポートの左上位置を変更する
    # 移動先を指定して、位置を変更する
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_x_:: 移動先位置(x方向)
    #_y_:: 移動先位置(y方向)
    #返却値:: 自分自身を返す
    def move_to!(x,y)
      orect = rect.to_a[0..1]
      osq = sq.to_a[0..1]
      @rect.move_to!(x,y)
      @sq.move_to!(x, y)
      if block_given?
        unless yield(self)
          @rect.move_to!(*orect)
          @sq.move_to!(*osq)
        end
      end
    end

    #===ビューポートの大きさを変更する
    # 変化量を指定して変更する
    #_dw_:: 幅
    #_dh_:: 高さ
    #返却値:: 自分自身を返す
    def resize!(dw,dh)
      raise MiyakoValueError, "Illegal size! w:#{w} h:#{h}" if ((@rect.w + dw) <= 0 || (@rect.h + dh) <= 0)
      @rect.resize!(dw, dh)
      @sq.resize!(dw, dh)
      return self
    end

    #===ビューポートの大きさを変更する
    # 幅と高さを指定して変更する
    #_w_:: 幅
    #_h_:: 高さ
    #返却値:: 自分自身を返す
    def resize_to!(w,h)
      raise MiyakoValueError, "Illegal size! w:#{w} h:#{h}" if (w <= 0 || h <= 0)
      @rect.resize_to!(w,h)
      @sq.resize_to!(w, h)
      return self
    end

    #===ビューポートの左上位置を変更したときの位置を求める
    #移動量を指定して、位置を変更する
    #ただし、自分自身の位置は変わらない
    #_dx_:: 移動量(x方向)
    #_dy_:: 移動量(y方向)
    #返却値:: 更新したインスタンス(Rect構造体)を返す
    def move(dx,dy)
      @rect.dup.move!(dx,dy)
    end

    #===ビューポートの左上位置を変更したときの位置を求める
    #移動先を指定して、位置を変更する
    #ただし、自分自身の位置は変わらない
    #_x_:: 移動先位置(x方向)
    #_y_:: 移動先位置(y方向)
    #返却値:: 更新したインスタンス(Rect構造体)を返す
    def move_to(x,y)
      @rect.dup.move_to!(x,y)
    end

    #===ビューポートの大きさを変更したときの値を求める
    #変化量を指定して変更する
    #ただし、自分自身の位置は変わらない
    #_dw_:: 幅
    #_dh_:: 高さ
    #返却値:: 更新したインスタンス(Rect構造体)を返す
    def resize(dw,dh)
      raise MiyakoValueError, "Illegal size! w:#{w} h:#{h}" if ((@rect.w + dw) <= 0 || (@rect.h + dh) <= 0)
      @rect.dup.resize!(dw,dh)
    end

    #===ビューポートの大きさを変更したときの値を求める
    #幅と高さを指定して変更する
    #ただし、自分自身の位置は変わらない
    #_w_:: 幅
    #_h_:: 高さ
    #返却値:: 更新したインスタンス(Rect構造体)を返す
    def resize_to(w,h)
      raise MiyakoValueError, "Illegal size! w:#{w} h:#{h}" if (w <= 0 || h <= 0)
      @rect.dup.resize_to!(w,h)
    end

    #===インスタンスを解放する
    def dispose
      @rect = nil
      @sq   = nil
    end

    #===ビューポートのインスタンスを複製する
    #返却値:: 自分自身の複製
    def viewport
      return self.dup
    end

    #===ビューポートのインスタンスを「左、右、上、下」の形式で取得する
    #返却値:: ビューポートの矩形(Square構造体インスタンス)の複製
    def square
      return @sq.dup
    end
  end
end