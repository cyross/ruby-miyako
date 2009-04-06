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
    def Utility.product_liner_inner(x1, y1, x2, y2, amount) #:nodoc:
      array = nil
      range_x = x1..x2
      range_y = y1..y2
      dx = x2 - x1
      dy = y2 - y1
      a = dy.to_f / dx.to_f
      b = y1.to_f - a * x1.to_f
      if a == 0.0
        array = range_x.step(amount[0]).to_a.map{|x| [x, b.to_i]}
      else
        array = (range_x.step(amount[0]).to_a.map{|x| [x, (a * x.to_f + b).to_i]} +
                 range_y.step(amount[1]).to_a.map{|y| [(y.to_f - b / a).to_i, y]}).
                 uniq.select{|pos| range_x === pos[0] && range_y === pos[1]}
      end
      return array
    end

    #===矩形内の対角線の座標リストを取得する
    #矩形内の対角線の座標リストを取得する
    #引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    #幅・高さはマイナスの値の設定が可能。
    #幅・高さのどちらかの値が0の場合は[]が返る
    #刻みの値は[x,y]の配列もしくはPoint/Rect/Square構造体を渡す。x,yどちらかが0以下の時は例外が発生する
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは[1,1]
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner(rect, amount = [1,1])
      raise MiyakoError, "Illegal amount! #{amount}" if (amount[0] <= 0 || amount[1] <= 0)
      return [] if rect[2] == 0 || rect[3] == 0
      x1 = rect[0]
      y1 = rect[1]
      x2 = x1 + rect[2] - 1
      y2 = y1 + rect[3] - 1
      x1, x2 = x2, x1 if x1 > x2 
      y1, y2 = y2, y1 if y1 > y2 
      return product_liner_inner(x1, y1, x2, y2, amount)
    end

    #===矩形内の対角線の座標リストを取得する
    #矩形内の対角線の座標リストを取得する
    #引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    #幅・高さはマイナスの値の設定が可能。
    #幅・高さのどちらかの値が0の場合は[]が返る
    #刻みの値は[x,y]の配列もしくはPoint/Rect/Square構造体を渡す。x,yどちらかが0以下の時は例外が発生する
    #_rect_:: 矩形情報
    #_amount_:: 配列を作成する座標の刻み。デフォルトは[1,1]
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_liner_by_square(square, amount = [1,1])
      raise MiyakoError, "Illegal amount! #{amount}" if (amount[0] <= 0 || amount[1] <= 0)
      return [] if (square[2] - square[0]) == 0 || (square[3] - square[1]) == 0
      x1, y1, x2, y2 = *square
      x1, x2 = x2, x1 if x1 > x2 
      y1, y2 = y2, y1 if y1 > y2 
      return product_liner_inner(x1, y1, x2, y2, amount)
    end

    def Utility.product_inner(x1, y1, x2, y2, size) #:nodoc:
      x_array = ((x1 / size[0])..(x2 / size[0])).to_a.map{|e| e * size[0]}
      y_array = ((y1 / size[1])..(y2 / size[1])).to_a.map{|e| e * size[1]}
      return x_array.product(y_array)
    end
    
    #===指定の矩形に掛かる、一定サイズの矩形の左上位置の組み合わせを返す
    #但し、引数には、Rect(x,y,w,h)形式のインスタンスを渡す
    #_rect_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position(rect, size)
      return product_inner(rect[0], rect[1], (rect[0]+rect[2]-1), (rect[1]+rect[3]-1), size)
    end

    #===指定の矩形に掛かる、一定サイズの矩形の左上位置の組み合わせを返す
    #但し、引数には、Square([x1,y1,x2,y2])形式のインスタンスを渡す
    #_square_:: 矩形情報
    #返却値:: 矩形左上位置の配列(指定の矩形に掛かる位置の組み合わせ)
    def Utility.product_position_by_square(square, size)
      return product_inner(*square.to_a, size)
    end
  end
end
