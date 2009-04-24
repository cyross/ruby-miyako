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

module Miyako
  #==ユーティリティモジュール
  module Utility
    def Utility.get_step_array_f(v1, v2, amount, skip_even = false) #:nodoc:
      steps = []
      amount = amount.abs
      val = v1
      if v1 < v2
        loop do
          val = val + amount
          break if (skip_even && (v2-val).abs < Float::EPSILON)
          break if val > v2
          steps << val
        end
      else
        loop do
          val = val - amount
          break if (skip_even && (v2-val).abs < Float::EPSILON)
          break if val < v2
          steps << val
        end
      end
      return steps
    end

    def Utility.product_liner_inner_f(x1, y1, x2, y2, amount) #:nodoc:
      array = nil
      step_x = get_step_array_f(x1, x2, amount)
      step_y = get_step_array_f(y1, y2, amount)
      dx = x2 - x1
      dy = y2 - y1
      a = dx < Float::EPSILON ? dy.to_f : dy.to_f / dx.to_f
      b = y1.to_f - a * x1.to_f
      array = [[x1,y1] , [x2,y2]] + step_x.map{|x| [x, (a * x.to_f + b).to_i]}
      array += step_y.map{|y| [((y.to_f - b) / a).to_i, y]} if (a.abs >= Float::EPSILON)
      return array.uniq
    end

    #===矩形内の対角線の座標リストを実数で取得する
    # (互換性維持のために残している)
    # 矩形内の対角線の座標リストを取得する
    # 引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    # 幅・高さはマイナスの値の設定が可能。
    # 幅・高さのどちらかの値が0(Float::EPSILON未満)の場合は[]が返る
    # 刻みの値は1以上の整数を渡す。0(Float::EPSILON未満)以下の場合は例外が発生する。
    # 結果は[x,y]の配列となるが、正確さを優先したため、必ず刻みの値の間隔で並んでいない
    #(刻みの値より小さい)ことがある
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは1.0
    #返却値:: 矩形左上位置[x,y]の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner_f(rect, amount = 1.0)
      raise MiyakoError, "Illegal amount! #{amount}" if amount < Float::EPSILON
      return [] if rect[2] < Float::EPSILON || rect[3] < Float::EPSILON
      x1 = rect[0]
      y1 = rect[1]
      x2 = x1 + rect[2] - 1
      y2 = y1 + rect[3] - 1
      return product_liner_inner_f(x1, y1, x2, y2, amount)
    end

    #===矩形内の対角線の座標リストを実数で取得する
    # (互換性維持のために残している)
    # 矩形内の対角線の座標リストを取得する
    # 引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    # 幅・高さはマイナスの値の設定が可能。
    # 幅・高さのどちらかの値が0(Float::EPSILON未満)の場合は[]が返る
    # 刻みの値は1以上の整数を渡す。0(Float::EPSILON未満)以下の場合は例外が発生する。
    # 結果は[x,y]の配列となるが、正確さを優先したため、必ず刻みの値の間隔で並んでいない
    #(刻みの値より小さい)ことがある
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは1
    #返却値:: 矩形左上位置[x,y]の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner_by_square_f(square, amount = 1.0)
      raise MiyakoError, "Illegal amount! #{amount}" if amount < Float::EPSILON
      return [] if (square[2] - square[0]) < Float::EPSILON || (square[3] - square[1]) < Float::EPSILON
      return product_liner_inner_f(*square, amount)
    end

    def Utility.product_liner_inner(x1, y1, x2, y2, amount) #:nodoc:
      array = nil
      step_x = []
      step_y = []
      dx = x2 - x1
      dy = y2 - y1
      a  = 0.0
      if [x1, y1, x2, y2, amount].all?{|v| v.methods.include?(:step)}
        step_x = x1 < x2 ? x1.step(x2, amount).to_a : x1.step(x2, -amount).to_a
        step_y = y1 < y2 ? y1.step(y2, amount).to_a : y1.step(y2, -amount).to_a
        a = dx == 0 ? dy.to_f : dy.to_f / dx.to_f
      else
        step_x = get_step_array_f(x1, x2, amount)
        step_y = get_step_array_f(y1, y2, amount)
        a = dx < Float::EPSILON ? dy.to_f : dy.to_f / dx.to_f
      end
      b = y1.to_f - a * x1.to_f
      array = [[x1,y1] , [x2,y2]] + step_x.map{|x| [x, (a * x.to_f + b).to_i]}
      array += step_y.map{|y| [((y.to_f - b) / a).to_i, y]} if (a.abs >= Float::EPSILON)
      return array.uniq
    end

    #===矩形内の対角線の座標リストを取得する
    #矩形内の対角線の座標リストを取得する
    #引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    #幅・高さはマイナスの値の設定が可能。
    #幅・高さのどちらかの値が0の場合は[]が返る
    #刻みの値は1以上の整数を渡す。0以下の場合は例外が発生する。
    #結果は[x,y]の配列となるが、正確さを優先したため、必ず刻みの値の間隔で並んでいない
    #(刻みの値より小さいことがある)ことがある
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは1
    #返却値:: 矩形左上位置[x,y]の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner(rect, amount = 1)
      raise MiyakoError, "Illegal amount! #{amount}" if amount <= 0
      return [] if rect[2] == 0 || rect[3] == 0
      x1 = rect[0]
      y1 = rect[1]
      x2 = x1 + rect[2] - 1
      y2 = y1 + rect[3] - 1
      return product_liner_inner(x1, y1, x2, y2, amount)
    end

    #===矩形内の対角線の座標リストを取得する
    #矩形内の対角線の座標リストを取得する
    #引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    #幅・高さはマイナスの値の設定が可能。
    #幅・高さのどちらかの値が0の場合は[]が返る
    #刻みの値は1以上の整数を渡す。0以下の場合は例外が発生する。
    #結果は[x,y]の配列となるが、正確さを優先したため、必ず刻みの値の間隔で並んでいない
    #(刻みの値より小さいことがある)ことがある
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは1
    #返却値:: 矩形左上位置[x,y]の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner_by_square(square, amount = 1)
      raise MiyakoError, "Illegal amount! #{amount}" if amount <= 0
      return [] if (square[2] - square[0]) == 0 || (square[3] - square[1]) == 0
      return product_liner_inner(*square, amount)
    end

    def Utility.product_inner(x1, y1, x2, y2, size) #:nodoc:
      x_array = ((x1 / size[0])..(x2 / size[0])).to_a.map{|e| e * size[0]}
      y_array = ((y1 / size[1])..(y2 / size[1])).to_a.map{|e| e * size[1]}
      return x_array.product(y_array)
    end
    
    #===指定の矩形が格子状のどこに重なっているかを返す
    #position(Point([x,y])形式)を基準として、矩形rect(Rect([x,y,w,h])形式)が、格子状の並べた矩形
    #(基準を[0,0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
    #どの格子状の矩形が重なっているかを、矩形の左上座標の配列として渡す(x座標とy座標の組み合わせ)。
    #
    #_position_:: 基準位置
    #_rect_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position(position, rect, size)
      return product_inner(
               position[0] + rect[0],
               position[1] + rect[1],
               position[0] + rect[0] + rect[2] - 1,
               position[1] + rect[1] + rect[3] - 1,
               size
             )
    end

    #===指定の矩形が格子状のどこに重なっているかを返す
    #矩形square(Square([x1,y1,x2,y2])形式)が、格子状の並べた矩形
    #(基準を[0,0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
    #どの格子状の矩形が重なっているかを、矩形の左上座標の配列として渡す(x座標とy座標の組み合わせ)。
    #_square_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position_by_square(square, size)
      return product_inner(*square.to_a, size)
    end

    def Utility.product_inner_f(x1, y1, x2, y2, size, skip_even = false) #:nodoc:
      sz = size[0].to_f
      min = (x1.to_f/sz).floor.to_f * sz
      x_array = [min] + get_step_array_f(min, x2.to_f, sz, skip_even)
      sz = size[1].to_f
      min = (y1.to_f/sz).floor.to_f * sz
      y_array = [min] + get_step_array_f(min, y2.to_f, sz, skip_even)
      return x_array.uniq.product(y_array.uniq)
    end
    
    #===指定の矩形が格子状のどこに重なっているかを返す(実数で指定)
    #position(Point([x,y])形式)を基準として、矩形rect(Rect([x,y,w,h])形式)が、格子状の並べた矩形
    #(基準を[0.0,0.0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
    #どの格子状の矩形が重なっているかを、矩形の左上座標の配列として渡す(x座標とy座標の組み合わせ)。
    #
    #_position_:: 基準位置
    #_rect_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position_f(position, rect, size)
      return product_inner_f(
               position[0] + rect[0],
               position[1] + rect[1],
               position[0] + rect[0] + rect[2],
               position[1] + rect[1] + rect[3],
               size,
               true
             )
    end

    #===指定の矩形が格子状のどこに重なっているかを返す(実数で指定)
    #矩形square(Square([x1,y1,x2,y2])形式)が、格子状の並べた矩形
    #(基準を[0.0,0.0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
    #どの格子状の矩形が重なっているかを、矩形の左上座標の配列として渡す(x座標とy座標の組み合わせ)。
    #_square_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position_by_square_f(square, size)
      return product_inner_f(*square.to_a, size)
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別する
    #移動後の小線分が大線分の範囲内にあるかどうかをtrue/falseで取得する
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def Utility.in_bounds?(segment1, segment2, d, flag = true)
      nx = segment1[0] + d
      nx2 = segment1[1] + d
      nx, nx2 = nx2, nx if nx > nx2
      return flag ? (nx >= segment2[0] && nx2 <= segment2[1]) : (nx > segment2[0] && (nx2 - 1) < segment2[1])
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別して、その状態によって値を整数で返す
    #移動後の小線分の範囲が大線分の範囲内のときは0、
    #マイナス方向で範囲外に出るときは-1、
    #プラス方向で出るときは1を返す
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def Utility.in_bounds_ex?(segment1, segment2, d, flag = true)
      nx = segment1[0] + d
      nx2 = segment1[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return -1 if (nx < segment2[0]) || (flag && (nx == segment2[0]))
      return (nx2 > segment2[1]) || (flag && (nx2 == segment2[1])) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #移動後の小線分の範囲が大線分の範囲内のときは0、
    #マイナス方向で範囲外に出るときは1、
    #プラス方向で出るときは-1を返す
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def Utility.in_bounds_rev?(segment1, segment2, d, flag = true)
      nx = segment1[0] + d
      nx2 = segment1[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return 1 if (nx < segment2[0]) || (flag && (nx == segment2[0]))
      return (nx2 > segment2[1]) || (flag && (nx2 == segment2[1])) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #移動量が0のときは0、
    #移動後の小線分の範囲が大線分の範囲内のときは1、
    #範囲外に出るときは-1を返す
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def Utility.in_bounds_rev_ex?(segment1, segment2, d, flag = true)
      return 0 if d == 0
      dir = (d <=> 0)
      nx = segment1[0] + d
      nx2 = segment1[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return -dir if (nx < segment2[0]) || (flag && (nx == segment2[0]))
      return (nx2 > segment2[1]) || (flag && (nx2 == segment2[1])) ? -dir : dir
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別する
    #移動後の小線分が大線分の範囲内にあるかどうかをtrue/falseで取得する
    #_pos1_:: 小線分の開始点の位置
    #_size1_:: 小線分の幅。0以上の整数
    #_pos2_:: 大線分の開始点の位置
    #_size2_:: 大線分の幅。1以上の整数
    #_d_:: pos1の移動量。マイナス値の設定も可能
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def Utility.in_bounds_by_size?(pos1, size1, pos2, size2, d, flag = true)
      raise MiyakoError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return flag ? (min_x1 >= pos2 && min_x2 <= pos2+size2) : (minx_x1 > pos2 && min_x2 < pos2+size2)
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別して、その状態によって値を整数で返す
    #移動後の小線分の範囲が大線分の範囲内のときは0、
    #マイナス方向で範囲外に出るときは-1、
    #プラス方向で出るときは1を返す
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def Utility.in_bounds_ex_by_size?(pos1, size1, pos2, size2, d, flag = true)
      raise MiyakoError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return -1 if (min_x1 < pos2) || (flag && (min_x1 == pos2))
      return (min_x2 > pos2+size2) || (flag && (min_x2 == pos2+size2)) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #移動後の小線分の範囲が大線分の範囲内のときは0、
    #マイナス方向で範囲外に出るときは1、
    #プラス方向で出るときは-1を返す
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def Utility.in_bounds_rev_by_size?(pos1, size1, pos2, size2, d, flag = true)
      raise MiyakoError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return 1 if (min_x1 < pos2) || (flag && (min_x1 == pos2))
      return (min_x2 > pos2+size2) || (flag && (min_x2 == pos2+size2)) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #移動量が0のときは0、
    #移動後の小線分の範囲が大線分の範囲内のときは1、
    #範囲外に出るときは-1を返す
    #_segment1_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_segment2_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: segment1の移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def Utility.in_bounds_rev_ex_by_size?(pos1, size1, pos2, size2, d, flag = true)
      return 0 if d == 0
      raise MiyakoError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      dir = (d <=> 0)
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return -dir if (min_x1 < pos2) || (flag && (min_x1 == pos2))
      return (min_x2 > pos2+size2) || (flag && (min_x2 == pos2+size2)) ? -dir : dir
    end
  end
end
