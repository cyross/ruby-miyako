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
  #==サイズ情報のための構造体クラス
  #サイズ変更メソッドを追加
  class SizeStruct < Struct
    def update!(obj)
      self[0] = obj[0]
      self[1] = obj[1]
      self
    end

    def update_by_point!(obj)
      self
    end

    def update_by_size!(obj)
      update!(obj)
    end

    def update_by_rect!(obj)
      self[0] = obj[2]
      self[1] = obj[3]
      self
    end

    def update_by_square!(obj)
      self[0] = obj[2]-obj[0]+1
      self[1] = obj[3]-obj[1]+1
      self
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
    #もう一方が整数のとき、w,hにotherを足したものを返す
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
    #もう一方が整数のとき、w,hからotherを引いたものを返す
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
    #もう一方が整数のとき、w,hにotherを掛けたものを返す
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
    #もう一方が整数のとき、w,hからotherを割ったものを返す
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
        raise MiyakoValueError, "0 div!" if (other[0] == 0 || other[1] == 0)
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

  #==サイズなどを構成するために使用する構造体
  #_w_:: 横幅
  #_h_:: 高さ
  Size = SizeStruct.new(:w, :h)
end
