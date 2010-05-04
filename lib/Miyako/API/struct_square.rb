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
  #==Square構造体用クラス
  #位置変更メソッドを追加
  class SquareStruct < Struct
    def update!(obj)
      self[0] = obj[0]
      self[1] = obj[1]
      self[2] = obj[2]
      self[3] = obj[3]
      self
    end

    def update_by_point!(obj)
      w = self[2]-self[0]
      h = self[3]-self[1]
      self[0] = obj[0]
      self[1] = obj[1]
      self[2] = self[0] + w
      self[3] = self[1] + h
      self
    end

    def update_by_size!(obj)
      self[2] = self[0] + obj[0] - 1
      self[3] = self[1] + obj[1] - 1
      self
    end

    def update_by_rect!(obj)
      self[0] = obj[0]
      self[1] = obj[1]
      self[2] = self[0] + obj[2] - 1
      self[3] = self[1] + obj[3] - 1
      self
    end

    def update_by_square!(obj)
      update!(obj)
    end

    #===位置を変更する(変化量を指定)
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move!(dx, dy)
    end

    #===位置を変更する(位置指定)
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to!(x, y)
    end

    #===位置を変更したインスタンスを返す(変化量を指定)
    #引数で指定したぶん移動させたときの位置を新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def move(dx, dy)
      self.dup.move!(dx, dy)
    end

    #===位置を変更したインスタンスを返す(位置指定)
    #引数で指定したぶん移動させたときの位置を新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def move_to(x, y)
      self.dup.move_to!(x, y)
    end

    #===サイズを変更する(変化量を指定)
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_dw_:: 幅変更。単位はピクセル
    #_dh_:: 高さ変更。単位はピクセル
    #返却値:: 自分自身を返す
    def resize!(dw, dh)
    end

    #===サイズを変更する
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_w_:: 幅変更。単位はピクセル
    #_h_:: 高さ変更。単位はピクセル
    #返却値:: 自分自身を返す
    def resize_to!(w, h)
    end

    #===サイズを変更したインスタンスを返す(変化量を指定)
    #引数で指定したぶん変えたときの大きさを新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_dw_:: 幅変更。単位はピクセル
    #_dh_:: 高さ変更。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def resize(dw, dh)
      self.dup.resize!(dw,dh)
    end

    #===サイズを変更したインスタンスを返す
    #引数で指定したぶん変えたときの大きさを新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_w_:: 幅変更。単位はピクセル
    #_h_:: 高さ変更。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def resize_to(w, h)
      self.dup.resize_to!(w,h)
    end

    #===インスタンスの足し算
    #もう一方が整数のとき、x,yにotherを足したものを返す
    #Point構造体や配列など、[]メソッドがつかえるもののとき、x,y同士を足したものを返す
    #それ以外の時は例外が発生する
    #自分自身の値は変わらない
    #_other_:: 整数もしくはPoint構造体
    #返却値:: Point構造体
    def +(other)
      ret = self.dup
      if other.kind_of?(Numeric)
        ret[0] += other
        ret[1] += other
        ret[2] += other
        ret[3] += other
      elsif other.methods.include?(:[])
        ret[0] += other[0]
        ret[1] += other[1]
        ret[2] += other[0]
        ret[3] += other[1]
      else
        raise MiyakoError, "this parameter cannot access!"
      end
      ret
    end

    #===インスタンスの引き算
    #もう一方が整数のとき、x,yからotherを引いたものを返す
    #Point構造体や配列など、[]メソッドがつかえるもののとき、x,y同士を引いたものを返す
    #それ以外の時は例外が発生する
    #自分自身の値は変わらない
    #_other_:: 整数もしくはPoint構造体
    #返却値:: Point構造体
    def -(other)
      ret = self.dup
      if other.kind_of?(Numeric)
        ret[0] -= other
        ret[1] -= other
        ret[2] -= other
        ret[3] -= other
      elsif other.methods.include?(:[])
        ret[0] -= other[0]
        ret[1] -= other[1]
        ret[2] -= other[0]
        ret[3] -= other[1]
      else
        raise MiyakoError, "this parameter cannot access!"
      end
      ret
    end

    #===インスタンスのかけ算
    #もう一方が整数のとき、x,yにotherを掛けたものを返す
    #Point構造体や配列など、[]メソッドがつかえるもののとき、x,y同士を掛けたものを返す
    #それ以外の時は例外が発生する
    #自分自身の値は変わらない
    #_other_:: 整数もしくはPoint構造体
    #返却値:: Point構造体
    def *(other)
      ret = self.dup
      w = ret[2] - ret[0]
      h = ret[3] - ret[1]
      if other.kind_of?(Numeric)
        ret[0] *= other
        ret[1] *= other
        ret[2] = ret[0] + w
        ret[3] = ret[1] + h
      elsif other.methods.include?(:[])
        ret[0] *= other[0]
        ret[1] *= other[1]
        ret[2] = ret[0] + w
        ret[3] = ret[1] + h
      else
        raise MiyakoError, "this parameter cannot access!"
      end
      ret
    end

    #===インスタンスの割り算
    #もう一方が整数のとき、x,yからotherを割ったものを返す
    #Point構造体や配列など、[]メソッドがつかえるもののとき、x,y同士を割ったものを返す
    #それ以外の時は例外が発生する
    #自分自身の値は変わらない
    #_other_:: 整数もしくはPoint構造体
    #返却値:: Point構造体
    def /(other)
      ret = self.dup
      w = ret[2] - ret[0]
      h = ret[3] - ret[1]
      if other.kind_of?(Numeric)
        raise MiyakoValueError, "0 div!" if other == 0
        ret[0] /= other
        ret[1] /= other
        ret[2] = ret[0] + w
        ret[3] = ret[1] + h
      elsif other.methods.include?(:[])
        raise MiyakoValueError, "0 div!" if (other[0] == 0 || other[1] == 0)
        ret[0] /= other[0]
        ret[1] /= other[1]
        ret[2] = ret[0] + w
        ret[3] = ret[1] + h
      else
        raise MiyakoError, "this parameter cannot access!"
      end
      ret
    end

    #===指定の座標が矩形の範囲内かを問い合わせる
    #_x_:: 指定のx座標
    #_y_:: 指定のy座標
    #返却値:: 座標が矩形の範囲内ならtrueを返す
    def in_range?(x, y)
      return (x >= self[0] && y >= self[1] && x <= self[2] && y <= self[3])
    end

    #===指定の座標が矩形の範囲内かを問い合わせる
    #_x_:: 指定のx座標
    #_y_:: 指定のy座標
    #返却値:: 座標が矩形の範囲内ならtrueを返す
    def between?(x, y)
      return in_range?(x, y)
    end

    #===矩形の左上位置部分のみ返す
    #返却値:: Position構造体のインスタンス
    def pos
      return Point.new(self[0], self[1])
    end

    #===矩形の大きさのみ返す
    #返却値:: Size構造体のインスタンス
    def size
      return Size.new(self[2]-self[0]+1, self[3]-self[1]+1)
    end

    #===矩形情報を配列に変換する
    #[left, top, right, bottom]の配列を生成して返す。
    #返却値:: 生成した配列
    def to_ary
      [self[0], self[1], self[2], self[3]]
    end

    #===矩形情報をRect構造体に変換する
    #返却値:: 生成したRect構造体
    def to_rect
      Rect.new(self[0], self[1], self[2]-self[0]+1, self[3]-self[1]+1)
    end
  end

  #==矩形などを構成するために使用する構造体
  #_left_:: 左上X座標の値
  #_top_:: 左上Y座標の値
  #_right_:: 右下X座標の値
  #_bottom_:: 右下Y座標の値
  Square = SquareStruct.new(:left, :top, :right, :bottom)
end
