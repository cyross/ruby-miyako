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
  #==位置情報のための構造体クラス
  #位置変更メソッドを追加
  class PointStruct < Struct
    #===位置を変更する(変化量を指定)
    #ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move!(dx, dy)
    end

    #===位置を変更する(位置指定)
    #ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
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
      elsif other.methods.include?(:[])
        ret[0] += other[0]
        ret[1] += other[1]
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
      elsif other.methods.include?(:[])
        ret[0] -= other[0]
        ret[1] -= other[1]
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
      if other.kind_of?(Numeric)
        ret[0] *= other
        ret[1] *= other
      elsif other.methods.include?(:[])
        ret[0] *= other[0]
        ret[1] *= other[1]
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
      if other.kind_of?(Numeric)
        raise MiyakoValueError, "0 div!" if other == 0
        ret[0] /= other
        ret[1] /= other
      elsif other.methods.include?(:[])
        ret[0] /= other[0]
        ret[1] /= other[1]
      else
        raise MiyakoError, "this parameter cannot access!"
      end
      ret
    end

    def to_ary #:nodoc:
      [self[0], self[1]]
    end
  end

  #==座標などを構成するために使用する構造体
  #_x_:: X座標の値
  #_y_:: Y座標の値
  Point = PointStruct.new(:x, :y)
end
