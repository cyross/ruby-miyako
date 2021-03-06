﻿# -*- encoding: utf-8 -*-
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

    def Utility.product_liner_xy_f(x1, y1, x2, y2, amount)
      distance = Utility.interval2(x1,y1,x2,y2)
      degree = Utility.radian2(x1,y1,x2,y2,distance)
      cos, sin = Math.cos(degree), Math.sin(degree)
      (0..distance).step(amount).with_object([]){|n, arr| arr << [x1 + n * cos, y1 + n * sin]} << [x2,y2]
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
      raise MiyakoValueError, "Illegal amount! #{amount}" if amount < Float::EPSILON
      return [] if rect[2] < Float::EPSILON || rect[3] < Float::EPSILON
      x1 = rect[0]
      y1 = rect[1]
      x2 = x1 + rect[2] - 1
      y2 = y1 + rect[3] - 1
      return product_liner_xy_f(x1, y1, x2, y2, amount)
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
      raise MiyakoValueError, "Illegal amount! #{amount}" if amount < Float::EPSILON
      return [] if (square[2] - square[0]) < Float::EPSILON || (square[3] - square[1]) < Float::EPSILON
      return product_liner_xy_f(*square, amount)
    end

    # ToDo: 線形補完を使う
    # -> 使った(2010.06.20)
    def Utility.product_liner_xy(x1, y1, x2, y2, amount) #:nodoc:
      distance = Utility.interval2(x1,y1,x2,y2)
      degree = Utility.radian2(x1,y1,x2,y2,distance)
      cos, sin = Math.cos(degree), Math.sin(degree)
      (0..distance).step(amount).with_object([]){|n, arr| arr << [x1+(n*cos).to_i, y1+(n*sin).to_i]} << [x2,y2]
    end

    #===矩形内の対角線の座標リストを取得する
    # 矩形内の対角線の座標リストを取得する
    # 引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    # 幅・高さはマイナスの値の設定が可能。
    # 幅・高さのどちらかの値が0の場合は[]が返る
    # 刻みの値は1以上の整数を渡す。0以下の場合は例外が発生する。
    # 結果は[x,y]の配列となるが、正確さを優先したため、必ず刻みの値の間隔で並んでいない
    #(刻みの値より小さいことがある)ことがある
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは1
    #返却値:: 矩形左上位置[x,y]の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner(rect, amount = 1)
      raise MiyakoValueError, "Illegal amount! #{amount}" if amount <= 0
      return [] if rect[2] == 0 || rect[3] == 0
      x1 = rect[0]
      y1 = rect[1]
      x2 = x1 + rect[2] - 1
      y2 = y1 + rect[3] - 1
      return product_liner_xy(x1, y1, x2, y2, amount)
    end

    #===矩形内の対角線の座標リストを取得する
    # 矩形内の対角線の座標リストを取得する
    # 引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    # 幅・高さはマイナスの値の設定が可能。
    # 幅・高さのどちらかの値が0の場合は[]が返る
    # 刻みの値は1以上の整数を渡す。0以下の場合は例外が発生する。
    # 結果は[x,y]の配列となるが、正確さを優先したため、必ず刻みの値の間隔で並んでいない
    #(刻みの値より小さいことがある)ことがある
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは1
    #返却値:: 矩形左上位置[x,y]の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner_by_square(square, amount = 1)
      raise MiyakoValueError, "Illegal amount! #{amount}" if amount <= 0
      return [] if (square[2] - square[0]) == 0 || (square[3] - square[1]) == 0
      return product_liner_xy(*square, amount)
    end

    def Utility.product_inner(x1, y1, x2, y2, size) #:nodoc:
      x_array = ((x1 / size[0])..(x2 / size[0])).to_a.map{|e| e * size[0]}
      y_array = ((y1 / size[1])..(y2 / size[1])).to_a.map{|e| e * size[1]}
      return x_array.product(y_array)
    end

    #===指定の矩形が格子状のどこに重なっているかを返す
    # position(Point([x,y])形式)を基準として、矩形rect(Rect([x,y,w,h])形式)が、格子状の並べた矩形
    # (基準を[0,0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
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
    # 矩形square(Square([x1,y1,x2,y2])形式)が、格子状の並べた矩形
    # (基準を[0,0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
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
    # 矩形square(Square([x1,y1,x2,y2])形式)が、格子状の並べた矩形
    # (基準を[0.0,0.0]とした、大きさ[size,size]の矩形をタイル状に並べた物)にある場合、
    #どの格子状の矩形が重なっているかを、矩形の左上座標の配列として渡す(x座標とy座標の組み合わせ)。
    #_square_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position_by_square_f(square, size)
      return product_inner_f(*square.to_a, size)
    end

    #===２点間の距離を算出する
    # ２点(点１、点２)がどの程度離れているかを算出する。
    # 返ってくる値は、正の実数で返ってくる
    #_point1_:: 点１の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_point2_:: 点２の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 2点間の距離
    def Utility.interval(point1, point2)
      #2点間の距離を求める
      d = Math.sqrt(((point1[0].to_f - point2[0].to_f) ** 2) +
                    ((point1[1].to_f - point2[1].to_f) ** 2))
      return d < Float::EPSILON ? 0.0 : d
    end

    #===２点間の距離を算出する
    # ２点(点１、点２)がどの程度離れているかを算出する。
    # 返ってくる値は、正の実数で返ってくる
    #_x1_:: 点１の位置(x)
    #_y1_:: 点１の位置(y)
    #_x2_:: 点２の位置(x)
    #_y2_:: 点２の位置(y)
    #返却値:: 2点間の距離
    def Utility.interval2(x1, y1, x2, y2)
      #2点間の距離を求める
      d = Math.sqrt(((x1.to_f - x2.to_f) ** 2) +
                    ((y1.to_f - y2.to_f) ** 2))
      return d < Float::EPSILON ? 0.0 : d
    end

    #===２点間の傾きを角度で算出する
    # ２点(点１、点２)がどの程度傾いているか算出する。傾きの中心は点１とする。
    # 角度の単位は度(0.0<=θ<360.0)
    # 返ってくる値は、正の実数で返ってくる
    #_point1_:: 点１の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_point2_:: 点２の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 2点間の傾き
    def Utility.theta(point1, point2, distance = nil)
      theta = (Utility.radian(point1,point2,distance) / (2 * Math::PI)) * 360.0
      return theta < Float::EPSILON ? 0.0 : theta
    end

    #===２点間の傾きを角度で算出する
    # ２点(点１、点２)がどの程度傾いているか算出する。傾きの中心は点１とする。
    # 角度の単位は度(0.0<=θ<360.0)
    # 返ってくる値は、正の実数で返ってくる
    #_x1_:: 点１の位置(x)
    #_y1_:: 点１の位置(y)
    #_x2_:: 点２の位置(x)
    #_y2_:: 点２の位置(y)
    #返却値:: 2点間の傾き
    def Utility.theta2(x1, y1, x2, y2, distance = nil)
      theta = (Utility.radian2(x1,y1,x2,y2,distance) / (2 * Math::PI)) * 360.0
      return theta < Float::EPSILON ? 0.0 : theta
    end

    #===２点間の傾きをラジアンで算出する
    # ２点(点１、点２)がどの程度傾いているか算出する。傾きの中心は点１とする。
    # 角度の単位は度(0.0<=θ<360.0)
    # 返ってくる値は、正の実数で返ってくる
    #_point1_:: 点１の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_point2_:: 点２の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 2点間の傾き
    def Utility.radian(point1, point2, distance = nil)
      #2点間の距離を求める
      d = distance || Math.sqrt(((point1[0].to_f - point2[0].to_f) ** 2) +
                                ((point1[1].to_f - point2[1].to_f) ** 2))
      x = point2[0].to_f - point1[0].to_f
      # 傾き・幅が０のときは傾きは０度
      return 0.0 if (x.abs < Float::EPSILON or d < Float::EPSILON)
      theta = Math.acos(x / d)
      return theta < Float::EPSILON ? 0.0 : (point2[1]-point1[1]<0 ? 2*Math::PI-theta : theta)
    end

    #===２点間の傾きをラジアンで算出する
    # ２点(点１、点２)がどの程度傾いているか算出する。傾きの中心は点１とする。
    # 角度の単位は度(0.0<=θ<360.0)
    # 返ってくる値は、正の実数で返ってくる
    #_x1_:: 点１の位置(x)
    #_y1_:: 点１の位置(y)
    #_x2_:: 点２の位置(x)
    #_y2_:: 点２の位置(y)
    #返却値:: 2点間の傾き
    def Utility.radian2(x1, y1, x2, y2, distance = nil)
      #2点間の距離を求める
      d = distance || Math.sqrt(((x1.to_f - x2.to_f) ** 2) +
                                ((y1.to_f - y2.to_f) ** 2))
      x = x2.to_f - x1.to_f
      # 傾き・幅が０のときは傾きは０度
      return 0.0 if (x.abs < Float::EPSILON or d < Float::EPSILON)
      theta = Math.acos(x / d)
      return theta < Float::EPSILON ? 0.0 : (y2-y1<0 ? 2*Math::PI-theta : theta)
    end

    #===２点間の傾きを角度で算出する
    # ２点(点１、点２)がどの程度傾いているか算出する。傾きの中心は点１とする。
    # 角度の単位は度(0.0<=θ<360.0)
    # 返ってくる値は、正の実数で返ってくる
    #_point1_:: 点１の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_point2_:: 点２の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 2点間の傾き
    def Utility.degree(point1, point2)
      return 0.0 if (point2[0].to_f-point1[0].to_f < Float::EPSILON)
      degree = (point2[1]-point1[1]).to_f/(point2[0]-point1[0]).to_f
      return degree < Float::EPSILON ? 0.0 : degree
    end

    #===２点間の傾きを角度で算出する
    # ２点(点１、点２)がどの程度傾いているか算出する。傾きの中心は点１とする。
    # 角度の単位は度(0.0<=θ<360.0)
    # 返ってくる値は、正の実数で返ってくる
    #_x1_:: 点１の位置(x)
    #_y1_:: 点１の位置(y)
    #_x2_:: 点２の位置(x)
    #_y2_:: 点２の位置(y)
    #返却値:: 2点間の傾き
    def Utility.degree2(x1, y1, x2, y2)
      return 0.0 if (x2.to_f-x1[0].to_f < Float::EPSILON)
      degree = (y2-y1).to_f/(x2-x1).to_f
      return degree < Float::EPSILON ? 0.0 : degree
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別する
    # 移動後の小線分が大線分の範囲内にあるかどうかをtrue/falseで取得する
    #_mini_segment_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def Utility.in_bounds?(mini_segment, big_segment, d, flag = false)
      nx = mini_segment[0] + d
      nx2 = mini_segment[1] + d
      nx, nx2 = nx2, nx if nx > nx2
      return flag ? (nx >= big_segment[0] && nx2 <= big_segment[1]) : (nx > big_segment[0] && (nx2 - 1) < big_segment[1])
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは-1、
    # プラス方向で出るときは1を返す
    #_mini_segment_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def Utility.in_bounds_ex?(mini_segment, big_segment, d, flag = false)
      nx = mini_segment[0] + d
      nx2 = mini_segment[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return -1 if (nx < big_segment[0]) || (flag && (nx == big_segment[0]))
      return (nx2 > big_segment[1]) || (flag && (nx2 == big_segment[1])) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは1、
    # プラス方向で出るときは-1を返す
    #_mini_segment_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def Utility.in_bounds_rev?(mini_segment, big_segment, d, flag = false)
      nx = mini_segment[0] + d
      nx2 = mini_segment[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return 1 if (nx < big_segment[0]) || (flag && (nx == big_segment[0]))
      return (nx2 > big_segment[1]) || (flag && (nx2 == big_segment[1])) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動量が0のときは0、
    # 移動後の小線分の範囲が大線分の範囲内のときは1、
    # 範囲外に出るときは-1を返す
    #_mini_segment_:: 小線分の範囲。[min,max]で構成された2要素の配列
    #_big_segment_:: 大線分の範囲。[min,max]で構成された2要素の配列
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def Utility.in_bounds_rev_ex?(mini_segment, big_segment, d, flag = false)
      return 0 if d == 0
      dir = (d <=> 0)
      nx = mini_segment[0] + d
      nx2 = mini_segment[1] + d - 1
      nx, nx2 = nx2, nx if nx > nx2
      return -dir if (nx < big_segment[0]) || (flag && (nx == big_segment[0]))
      return (nx2 > big_segment[1]) || (flag && (nx2 == big_segment[1])) ? -dir : dir
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別する
    # 移動後の小線分が大線分の範囲内にあるかどうかをtrue/falseで取得する
    #_mini_pos_:: 小線分の開始点の位置
    #_mini_size_:: 小線分の幅。0以上の整数
    #_big_pos_:: 大線分の開始点の位置
    #_big_size_:: 大線分の幅。1以上の整数
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 範囲内のときはtrue、範囲外の時はfalseを返す
    def Utility.in_bounds_by_size?(pos1, size1, pos2, size2, d, flag = false)
      raise MiyakoValueError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoValueError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoValueError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return flag ? (min_x1 >= pos2 && min_x2 <= pos2+size2) : (minx_x1 > pos2 && min_x2 < pos2+size2)
    end

    #===小線分を移動させたとき、大線分が範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは-1、
    # プラス方向で出るときは1を返す
    #_mini_pos_:: 小線分の開始点の位置
    #_mini_size_:: 小線分の幅。0以上の整数
    #_big_pos_:: 大線分の開始点の位置
    #_big_size_:: 大線分の幅。1以上の整数
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def Utility.in_bounds_ex_by_size?(pos1, size1, pos2, size2, d, flag = false)
      raise MiyakoValueError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoValueError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoValueError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return -1 if (min_x1 < pos2) || (flag && (min_x1 == pos2))
      return (min_x2 > pos2+size2) || (flag && (min_x2 == pos2+size2)) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動後の小線分の範囲が大線分の範囲内のときは0、
    # マイナス方向で範囲外に出るときは1、
    # プラス方向で出るときは-1を返す
    #_mini_pos_:: 小線分の開始点の位置
    #_mini_size_:: 小線分の幅。0以上の整数
    #_big_pos_:: 大線分の開始点の位置
    #_big_size_:: 大線分の幅。1以上の整数
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def Utility.in_bounds_rev_by_size?(pos1, size1, pos2, size2, d, flag = false)
      raise MiyakoValueError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoValueError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoValueError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return 1 if (min_x1 < pos2) || (flag && (min_x1 == pos2))
      return (min_x2 > pos2+size2) || (flag && (min_x2 == pos2+size2)) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    # 移動量が0のときは0、
    # 移動後の小線分の範囲が大線分の範囲内のときは1、
    # 範囲外に出るときは-1を返す
    #_mini_pos_:: 小線分の開始点の位置
    #_mini_size_:: 小線分の幅。0以上の整数
    #_big_pos_:: 大線分の開始点の位置
    #_big_size_:: 大線分の幅。1以上の整数
    #_d_:: mini_segmentの移動量
    #_flag_:: 大線分の端いっぱいも範囲外に含めるときはtrueを設定する。デフォルトはfalse
    #返却値:: 判別の結果
    def Utility.in_bounds_rev_ex_by_size?(pos1, size1, pos2, size2, d, flag = false)
      return 0 if d == 0
      raise MiyakoValueError, "illegal size1! #{size1}" if size1 < 0
      raise MiyakoValueError, "illegal size2! #{size2}" if size2 <= 0
      raise MiyakoValueError, "size1 is more than size2! #{size1}, #{size2}" if size1 > size2
      dir = (d <=> 0)
      min_x1 = pos1 + d
      min_x2 = pos1 + size1 + d
      min_x1, min_x2 = min_x2, min_x1 if min_x1 > min_x2
      return -dir if (min_x1 < pos2) || (flag && (min_x1 == pos2))
      return (min_x2 > pos2+size2) || (flag && (min_x2 == pos2+size2)) ? -dir : dir
    end
  end
end
