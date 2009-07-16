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
    
    def to_ary #:nodoc:
      [self[0], self[1]]
    end
  end

  #==サイズ情報のための構造体クラス
  #サイズ変更メソッドを追加
  class SizeStruct < Struct
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
    
    def to_ary #:nodoc:
      [self[0], self[1]]
    end
  end

  #==矩形情報のための構造体クラス
  #矩形変更メソッドを追加
  class RectStruct < Struct
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

    #===指定の座標が矩形の範囲内かを問い合わせる
    #_x_:: 指定のx座標
    #_y_:: 指定のy座標
    #返却値:: 座標が矩形の範囲内ならtrueを返す
    def in_range?(x, y)
      return (x >= self[0] && y >= self[1] && x < self[0] + self[2] && y < self[1] + self[3])
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
      return Size.new(self[2], self[3])
    end
    
    #===矩形情報を配列に変換する
    #[left, top, width, height]の配列を生成して返す。
    #返却値:: 生成した配列
    def to_ary
      [self[0], self[1], self[2], self[3]]
    end
    
    #===矩形情報をSquare構造体に変換する
    #返却値:: 生成したSquare構造体
    def to_square
      Square.new(self[0], self[1], self[2]+self[0]-1, self[3]+self[1]-1)
    end
  end

  #==Square構造体用クラス
  #位置変更メソッドを追加
  class SquareStruct < Struct
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

  #==線分の区間情報のための構造体クラス
  #位置変更メソッドを追加
  class SegmentStruct < Struct

    #===レシーバがotherの範囲内かどうかを求める
    #最小数・最大数ともにotherの範囲内かどうかを確認する
    #_other_:: 比較対象の線分
    #返却値:: 最小値・最大値ともにotherの範囲内ならばtrueを返す
    def between?(other)
      return self[0] >= other[0] && self[1] <= other[1]
    end

    #===otherがレシーバの範囲内かどうかを求める
    #最小数・最大数ともにotherの範囲外かどうかを確認する
    #_other_:: 比較対象の線分
    #返却値:: 最小値・最大値ともにotherの範囲外ならばtrueを返す
    def covers?(other)
      return self[0] <= other[0] && self[1] >= other[1]
    end

    #===レシーバがotherの範囲と重なっているかどうかを求める
    #最小数・最大数のどちらかがotherの範囲内かどうかを確認する
    #_other_:: 比較対象の線分
    #返却値:: 最小値・最大値のどちらかがotherの範囲内ならばtrueを返す
    def collision?(other)
      return (self[0] >= other[0] && self[0] <= other[1]) || (self[1] >= other[0] && self[1] <= other[1])
    end

    #===線分の大きさを求める
    #max - min + 1 の値を求めて返す
    #返却値:: 線分の大きさ
    def size
      self[1] - self[0] + 1
    end

    #===位置を変更する(変化量を指定)
    #_d_:: 移動量
    #返却値:: 自分自身を返す
    def move!(d)
      self[0] += d
      self[1] += d
      return self
    end

    #===位置を変更する(位置指定)
    #_v_:: 移動先位置。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to!(v)
      self[1] = self[1] - self[0] + v
      self[0] = v
      return self
    end

    #===位置を変更したインスタンスを返す(変化量を指定)
    #引数で指定したぶん移動させたときの位置を新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_d_:: 移動量
    #返却値:: 自分自身の複製を更新したインスタンス
    def move(d)
      return self.dup.move!(d)
    end

    #===位置を変更したインスタンスを返す(位置指定)
    #引数で指定したぶん移動させたときの位置を新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_v_:: 移動先位置。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def move_to(v)
      return self.dup.move_to!(v)
    end

    #===幅を変更する(変化量を指定)
    #_d_:: 変更量。単位はピクセル
    #返却値:: 自分自身を返す
    def resize!(d)
      self[1] += d
      return self
    end

    #===幅を変更する
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_v_:: 変更後の幅。単位はピクセル
    #返却値:: 自分自身を返す
    def resize_to!(v)
      self[1] = self[0] + v - 1
      return self
    end
    
    #===サイズを変更したインスタンスを返す(変化量を指定)
    #引数で指定したぶん変えたときの大きさを新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_d_:: 変更量。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def resize(d)
      self.dup.resize!(d)
    end

    #===サイズを変更したインスタンスを返す
    #引数で指定したぶん変えたときの大きさを新しくインスタンスを生成して返す
    #自分自身の値は変わらない
    #_v_:: 変更後の幅。単位はピクセル
    #返却値:: 自分自身の複製を更新したインスタンス
    def resize_to(v)
      self.dup.resize_to!(v)
    end

    #===線分情報を変更する
    #minとmaxを一緒に更新する
    #min>maxのときは、それぞれの値を入れ替える
    #_min_:: 線分の最小値
    #_max_:: 線分の最大値
    #返却値:: 自分自身
    def reset!(min, max) #:nodoc:
      self[0], self[1] = min, max
      self[0], self[1] = self[1], self[0] if self[0] > self[1]
      self
    end
    
    #===線分情報を配列に変換する
    #[min, max]の配列を生成して返す。
    #返却値:: 生成した配列
    def to_ary
      [self[0], self[1]]
    end

    #===値が線分の範囲内かどうかを判別する
    #値がminとmaxの値の範囲内にあるかどうかを判別する。範囲内にあればtrueを返す
    #値がminもしくはmaxに等しいときもtrueを返す
    #_v_:: 判別する値
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def in_range?(v)
      v >= self[0] && v <= self[1]
    end

    #===値が線分の範囲内かどうかを判別する
    #値がminとmaxの値の範囲内にあるかどうかを判別する。範囲内にあればtrueを返す
    #値がminもしくはmaxに等しいときもtrueを返す
    #_v_:: 判別する値
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def between?(v)
      in_range?(v)
    end

    #===値が線分の端かどうかを判別する
    #値がminもしくはmaxと等しければtrueを返す
    #_v_:: 判別する値
    #返却値:: vがminもしくはmaxと等しければtrue、それ以外の時はfalseを返す
    def in_edge?(v)
      v == self[0] || v == self[1]
    end

    #===値が最小値かどうかを判別する
    #値がminと等しければtrueを返す
    #_v_:: 判別する値
    #返却値:: vがminと等しければtrue、それ以外の時はfalseを返す
    def min?(v)
      v == self[0]
    end

    #===値が最大値かどうかを判別する
    #値がmaxと等しければtrueを返す
    #_v_:: 判別する値
    #返却値:: vがmaxと等しければtrue、それ以外の時はfalseを返す
    def max?(v)
      v == self[1]
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別する
    # 移動後の小線分が大線分の範囲内にあるかどうかをtrue/falseで取得する
    #_big_segment_:: 大線分の範囲。Segment構造体、もしくは[min,max]で構成された配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def in_bounds?(big_segment, d, flag = false)
      nx = self[0] + d
      nx2 = self[1] + d
      nx, nx2 = nx2, nx if nx > nx2
      return flag ?
             (nx >= big_segment[0] && nx2 <= big_segment[1]) :
             (nx > big_segment[0] && (nx2 - 1) < big_segment[1])
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは-1、
    # プラス方向で出るときは1を返す
    #_big_segment_:: 大線分の範囲。Segment構造体、もしくは[min,max]で構成された配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def in_bounds_ex?(big_segment, d, flag = false)
      nx = self[0] + d
      nx2 = self[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return -1 if (nx < big_segment[0]) || (flag && (nx == big_segment[0]))
      return (nx2 > big_segment[1]) || (flag && (nx2 == big_segment[1])) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは1、
    # プラス方向で出るときは-1を返す
    #_big_segment_:: 大線分の範囲。Segment構造体、もしくは[min,max]で構成された配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def in_bounds_rev?(big_segment, d, flag = false)
      nx = self[0] + d
      nx2 = self[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return 1 if (nx < big_segment[0]) || (flag && (nx == big_segment[0]))
      return (nx2 > big_segment[1]) || (flag && (nx2 == big_segment[1])) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動量が0のときは0、
    # 移動後の小線分の範囲が大線分の範囲内のときは1、
    # 範囲外に出るときは-1を返す
    #_big_segment_:: 大線分の範囲。Segment構造体、もしくは[min,max]で構成された配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def in_bounds_rev_ex?(big_segment, d, flag = false)
      return 0 if d == 0
      dir = (d <=> 0)
      nx = self[0] + d
      nx2 = self[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return -dir if (nx < big_segment[0]) || (flag && (nx == big_segment[0]))
      return (nx2 > big_segment[1]) || (flag && (nx2 == big_segment[1])) ? -dir : dir
    end
  end

  #==X方向・Y方向線分の区間情報を操作するクラス
  #本クラスでは、X方向・Y方向2つのSegmentを管理する。
  #位置変更メソッドを追加
  class Segments
  
    #===x座標の線分を返す
    #(例)segments = (x:[10,20],y:[100,200])
    #    segments.x => segment[10,20]
    #返却値:: Segment構造体
    attr_reader :x

    #===y座標の線分を返す
    #(例)segment = (x:[10,20],y:[100,200])
    #    segment.y => segment[100,200]
    #返却値:: Segment構造体
    attr_reader :y
    
    #===矩形情報からSegmentsインスタンスを生成する
    #入力した矩形情報(Rect構造体、[x,y,w,h]で表される配列)から、構造体インスタンスを生成する
    #(前バージョンまでの互換性のために残している)
    #_rect_:: 算出に使用する矩形情報
    #返却値:: 生成したインスタンスを返す
    def Segments.create(rect)
      return Segments.new(Segment.new(rect[0], rect[0] + rect[2] - 1),
                          Segment.new(rect[1], rect[1] + rect[3] - 1))
    end
    
    #===矩形情報からSegmentsインスタンスを生成する
    #入力した情報から、Segment構造体二つを持ったインスタンスを生成する
    #引数には、Rect構造体、Square構造体、[(x)[min,max],(y)[min,max]],[min_x,max_x,min_y,max_y]の形式を持つ
    #
    #引数を省略したときはすべて0のSegment構造体を持つ
    #また、引数が3つ、5つ以上の時はMiyakoValueError例外が発生する
    #_params_:: 情報を渡す引数(複数可)
    #返却値:: 生成したインスタンスを返す
    def initialize(*params)
      case params.length
        when 0
          @x = Segment.new(0,0)
          @y = Segment.new(0,0)
        when 1
          pm = params[0]
          if pm.is_a?(Rect)
            @x = Segment.new(pm[0], pm[0] + pm[2] - 1)
            @y = Segment.new(pm[1], pm[1] + pm[3] - 1)
          elsif pm.is_a?(Square) || (pm.is_a?(Array) && pm.length==4)
            @x = Segment.new(pm[0], pm[2])
            @y = Segment.new(pm[1], pm[3])
          else
            @x = Segment.new(pm[0][0],pm[0][1])
            @y = Segment.new(pm[1][0],pm[1][1])
          end
        when 2
          @x = Segment.new(params[0][0],params[0][1])
          @y = Segment.new(params[1][0],params[1][1])
        when 4
          @x = Segment.new(params[0],params[1])
          @y = Segment.new(params[2],params[3])
        else
          raise MiyakoValueError, "illegal params : params is 0,1,2,4! params = #{params.length}"
      end
    end
    
    #===インデックスから対象のSegment構造体を取得する
    #インデックスの値に対応した
    #上記以外のインデックスを渡したときはnilを返す
    #Segmentsは以前構造体だったため、互換性のために用意している
    #_idx_:: Segmentを指すインデックス
    #返却値:: インデックスに対応したSegment構造体(対応していないインデックスの時はnil)
    def [](idx)
      case idx
        when 0, :x
          return @x
        when 1, :y
          return @y
        else
          return nil
      end
    end

    #===位置を変更する(変化量を指定)
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move!(dx, dy)
      @x.move!(dx)
      @y.move!(dy)
      return self
    end

    #===位置を変更する(位置指定)
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to!(x, y)
      @x.move_to!(x)
      @y.move_to!(y)
      return self
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
      @x.resize!(dw)
      @y.resize!(dh)
      return self
    end

    #===サイズを変更する
    # ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_w_:: 幅変更。単位はピクセル
    #_h_:: 高さ変更。単位はピクセル
    #返却値:: 自分自身を返す
    def resize_to!(w, h)
      @x.resize_to!(w)
      @y.resize_to!(h)
      return self
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

    #===線分情報を変更する
    #x,yそれぞれのminとmaxを一緒に更新する
    #min>maxのときは、それぞれの値を入れ替える
    #_min_x_:: x方向の線分の最小値
    #_max_x_:: x方向の線分の最大値
    #_min_y_:: y方向の線分の最小値
    #_max_y_:: y方向の線分の最大値
    #返却値:: 自分自身
    def reset!(min_x, max_x, min_y, max_y) #:nodoc:
      @x.reset!(min_x, max_x)
      @y.reset!(min_y, max_y)
    end
   
    #===線分情報を配列に変換する
    #[[min, max],[min, max]]の配列を生成して返す。
    #返却値:: 生成した配列
    def to_ary
      [@x.to_ary, @y.to_ary]
    end

    #===値がともに線分の範囲内かどうかを判別する
    #x,yの値がともにminとmaxの値の範囲内にあるかどうかを判別する。範囲内にあればtrueを返す
    #値がminもしくはmaxに等しいときもtrueを返す
    #_x_:: x方向の値
    #_y_:: y方向の値
    #返却値:: x,yが範囲内のときはtrue、範囲外の時はfalseを返す
    def in_range?(x, y)
      @x.in_range?(x) && @y.in_range?(y)
    end

    #===値がともに線分の範囲内かどうかを判別する
    #x,yの値がともにminとmaxの値の範囲内にあるかどうかを判別する。範囲内にあればtrueを返す
    #値がminもしくはmaxに等しいときもtrueを返す
    #_x_:: x方向の値
    #_y_:: y方向の値
    #返却値:: x,yが範囲内のときはtrue、範囲外の時はfalseを返す
    def between?(x, y)
      in_range?(x, y)
    end

    #===値がともに線分の端かどうかを判別する
    #x,yの値がともにminもしくはmaxと等しければtrueを返す
    #_x_:: x方向の値
    #_y_:: y方向の値
    #返却値:: x,yがminもしくはmaxと等しければtrue、それ以外の時はfalseを返す
    def in_edge?(x, y)
      @x.in_edge?(x) && @y.in_edge?(y)
    end

    #===値がともに最小値かどうかを判別する
    #値がminと等しければtrueを返す
    #_x_:: x方向の値
    #_y_:: y方向の値
    #返却値:: x,yがminと等しければtrue、それ以外の時はfalseを返す
    def min?(x, y)
      @x.min?(x) && @y.min?(y)
    end

    #===値がともに最大値かどうかを判別する
    #値がmaxと等しければtrueを返す
    #_x_:: x方向の値
    #_y_:: y方向の値
    #返却値:: x,yがmaxと等しければtrue、それ以外の時はfalseを返す
    def max?(x, y)
      @x.max?(x) && @y.max?(y)
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別する
    # 移動後の小線分が大線分の範囲内にあるかどうかをtrue/falseで取得する
    #_idx_:: 判別する方向(xもしくはy)。:x, :y, 0, 1のどれかを渡す。それ以外を渡すと例外が発生する
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def in_bounds?(idx, big_segment, d, flag = false)
      raise MiyakoError, "illegal index : #{idx}" unless [0,1,:x,:y].include?(idx)
      return self[idx].in_bounds?(big_segment, d, flag)
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは-1、
    # プラス方向で出るときは1を返す
    #_idx_:: 判別する方向(xもしくはy)。:x, :y, 0, 1のどれかを渡す。それ以外を渡すと例外が発生する
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def in_bounds_ex?(idx, big_segment, d, flag = false)
      raise MiyakoError, "illegal index : #{idx}" unless [0,1,:x,:y].include?(idx)
      return self[idx].in_bounds_ex?(big_segment, d, flag)
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは1、
    # プラス方向で出るときは-1を返す
    #_idx_:: 判別する方向(xもしくはy)。:x, :y, 0, 1のどれかを渡す。それ以外を渡すと例外が発生する
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def in_bounds_rev?(idx, big_segment, d, flag = false)
      raise MiyakoError, "illegal index : #{idx}" unless [0,1,:x,:y].include?(idx)
      return self[idx].in_bounds_rev?(big_segment, d, flag)
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動量が0のときは0、
    # 移動後の小線分の範囲が大線分の範囲内のときは1、
    # 範囲外に出るときは-1を返す
    #_idx_:: 判別する方向(xもしくはy)。:x, :y, 0, 1のどれかを渡す。それ以外を渡すと例外が発生する
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: selfの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def in_bounds_rev_ex?(idx, big_segment, d, flag = false)
      raise MiyakoError, "illegal index : #{idx}" unless [0,1,:x,:y].include?(idx)
      return self[idx].in_bounds_rev_ex?(big_segment, d, flag)
    end
  end

  #==座標などを構成するために使用する構造体
  #_x_:: X座標の値
  #_y_:: Y座標の値
  Point = PointStruct.new(:x, :y)

  #==サイズなどを構成するために使用する構造体
  #_w_:: 横幅
  #_h_:: 高さ
  Size = SizeStruct.new(:w, :h)

  #==矩形などを構成するために使用する構造体
  #_x_:: X座標の値
  #_y_:: Y座標の値
  #_w_:: 横幅
  #_h_:: 高さ
  Rect = RectStruct.new(:x, :y, :w, :h)

  #==矩形などを構成するために使用する構造体
  #_left_:: 左上X座標の値
  #_top_:: 左上Y座標の値
  #_right_:: 右下X座標の値
  #_bottom_:: 右下Y座標の値
  Square = SquareStruct.new(:left, :top, :right, :bottom)

  #==線分を構成するために使用する構造体
  #min,maxは、逆に入っていてもコンストラクタで入れ替える
  #_min_:: 線分の小さい方の値
  #_max_:: 線分の大きい方の値
  Segment = SegmentStruct.new(:min, :max)

  class Segment
    def initialize(*params)
      super(*params)
      self.min, self.max = self.max, self.min if self.min > self.max
    end
  end

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
      c = (@@symbol2color[name.to_sym] or raise MiyakoError, "Illegal Color Name! : #{name}")
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

  #タイマーを管理するクラス
  class WaitCounter
    SECOND2TICK = 1000

    #WaitCounterインスタンス固有の名前
    #デフォルトはインスタンスIDを文字列化したもの
    attr_accessor :name
    
    def WaitCounter.get_second_to_tick(s) #:nodoc:
      return (SECOND2TICK * s).to_i
    end
    
    #===インスタンスを生成する
    #_seconds_:: タイマーとして設定する秒数(実数で指定可能)
    #_name_:: インスタンス固有の名称。デフォルトはnil
    #(nilを渡した場合、インスタンスIDを文字列化したものが名称になる)
    #返却値:: 生成されたインスタンス
    def initialize(seconds, name=nil)
      @seconds = seconds
      @name = name ? name : __id__.to_s
      @wait = WaitCounter.get_second_to_tick(@seconds)
      @st = 0
      @counting = false
    end

    #===設定されているウェイトの長さを求める
    #ウェイトの長さをミリセカンド単位で取得する
    #返却値:: ウェイトの長さ
    def length
      return @wait
    end
    
    #===残りウェイトの長さを求める
    #タイマー実行中のときウェイトの長さをミリセカンド単位で取得する
    #返却値:: 残りウェイトの長さ(実行していない時はウェイトの長さ)
    def remind
      return @wait unless @counting
      cnt = SDL.getTicks - @st
      return @wait < cnt ? 0 : @wait - cnt
    end
    
    #===タイマー処理を開始する
    #返却値:: 自分自身を返す
    def start
      @st = SDL.getTicks
      @counting = true
      return self
    end

    #===タイマー処理を停止する
    #一旦タイマーを停止すると、復帰できない(一時停止ではない)
    #返却値:: 自分自身を返す
    def stop
      @counting = false
      @st = 0
      return self
    end

    def wait_inner(f) #:nodoc:
      return !f unless @counting
      t = SDL.getTicks
      return f unless (t - @st) >= @wait
      @counting = false
      return !f
    end
    
    private :wait_inner

    #===タイマー処理中かを返す
    #タイマー処理中ならばtrue、停止中ならばfalseを返す
    #返却値:: タイマー処理中かどうかを示すフラグ
    def waiting?
      return wait_inner(true)
    end

    #===タイマー処理が終了したかを返す
    #タイマー処理が終了したらtrue、処理中ならfalseを返す
    #返却値:: タイマー処理が終わったかどうかを示すフラグ
    def finish?
      return wait_inner(false)
    end

    def wait #:nodoc:
      st = SDL.getTicks
      t = SDL.getTicks
      until (t - st) >= @wait do
        t = SDL.getTicks
      end
      return self
    end

    #===インスタンスないで所持している領域を開放する
    #(現段階ではダミー)
    def dispose
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

#=begin rdoc
#==１個のインスタンスでイテレータを実装できるモジュール
#=end
module SingleEnumerable
  include Enumerable

  #===ブロックの処理を実行する
  #返却値:: 自分自身を返す
  def each
    yield self
    return self
  end

  #===sizeメソッドと同様
  #返却値:: sizeメソッドと同様
  def length
    return 1
  end
end
