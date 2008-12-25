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

module Miyako
  #==ラムダ構造体
  ViewportExecStruct = Struct.new(:x, :y)
  #==ビューポートクラス
  #描画時の表示範囲を変更する
  #画面全体を基準(640x480の画面のときは(0,0)-(639,479)の範囲)として、範囲を設定する
  #範囲の設定はいつでも行えるが、描画にはrenderメソッドを呼び出した時の値が反映される
  class Viewport
      @@r_exec  = ViewportExecStruct.new
      @@r_exec.x = [lambda{|vp, rect, dx| self.move_to(rect[0] + dx, rect[1])},
                    lambda{|vp, rect, dx| self.move_to(vp[0] + vp[2] - rect[2], rect[1])},
                    lambda{|vp, rect, dx| self.move_to(vp[0], rect[1])}
                   ]
      @@r_exec.y = [lambda{|vp, rect, dy| self.move_to(rect[0],rect[1] + dy)},
                    lambda{|vp, rect, dy| self.move_to(rect[0],vp[1] + vp[3] - rect[3])},
                    lambda{|vp, rect, dy| self.move_to(rect[0],vp[1])}
                   ]

    #===ビューポートのインスタンスを生成する
    #_x_,_y_: ビューポートの左上位置
    #_w_,_h_: ビューポートの大きさ(共に0以上、マイナスのときはエラーが出る)
    def initialize(x, y, w, h)
      raise MiyakoError, "Illegal size! w:#{w} h:#{h}" if (w < 0 || h < 0)
      @rect = Rect.new(x, y, w, h)
      @sq = Rect.new(x, y, x+w-1, y+h-1)
    end

    #===ビューポートの内容を画面に反映する
    #ブロックが渡ってきたときは、範囲を変更して指定することが出来る(この変更は、本メソッドを呼ぶ時だけ有効)
    #ブロックの引数は、|Rect構造体|が渡される。
    #_block_:: 呼び出し時にブロック付き呼び出しが行われたときのブロック本体。呼び先に渡すことが出来る。ブロックがなければnilが入る
    def render(&block)
      if block_given?
        rect = @rect.dup
        yield rect
        Screen.screen.set_clip_rect(rect)
      else
        Screen.screen.set_clip_rect(@rect)
      end
    end

    #===ビューポートの左上位置を変更する
    #移動量を指定して、位置を変更する
    #ブロックを渡せば、その評価中のみ移動する
    #_dx_:: 移動量(x方向)
    #_dy_:: 移動量(y方向)
    #返却値:: 自分自身を返す
    def move(dx,dy)
      orect = rect.to_a[0..1]
      osq = sq.to_a[0..1]
      @rect.move(dx,dy)
      @sq.move(dx, dy)
      if block_given?
        yield
        @rect.move_to(*orect)
        @sq.move_to(*osq)
      end
      return self
    end

    #===ビューポートの左上位置を変更する
    #移動先を指定して、位置を変更する
    #ブロックを渡せば、その評価中のみ移動する
    #_x_:: 移動先位置(x方向)
    #_y_:: 移動先位置(y方向)
    #返却値:: 自分自身を返す
    def move_to(x,y)
      orect = rect.to_a[0..1]
      osq = sq.to_a[0..1]
      @rect.move_to(x,y)
      @sq.move_to(x, y)
      if block_given?
        yield
        @rect.move_to(*orect)
        @sq.move_to(*osq)
      end
    end

    #===ビューポートの大きさを変更する
    #幅と高さを指定して変更する
    #_w_:: 幅
    #_h_:: 高さ
    #返却値:: 自分自身を返す
    def resize(w,h)
      raise MiyakoError, "Illegal size! w:#{w} h:#{h}" if (w < 0 || h < 0)
      @rect.resize(w,h)
      @sq.resize(w, h)
      return self
    end
    
    #===インスタンスを解放する
    def dispose
      @rect = nil
      @sq   = nil
    end
    
    #===ビューポートのインスタンスを取得する
    #返却値:: ビューポートの矩形(Rect構造体インスタンス)の複製
    def viewport
      return @rect.dup
    end
    
    #===ビューポートのインスタンスを「左、右、上、下」の形式で取得する
    #返却値:: ビューポートの矩形(Square構造体インスタンス)の複製
    def square
      return @sq.dup
    end

    #===移動先がViewportの範囲内かどうかを判別する
    #
    #移動後の座標が表示範囲外に引っかかっているかをtrue/falseの配列[x,y]で取得する
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果（[x,y]の配列）
    def in_bounds?(rect, dx, dy, flag = true)
      bx, by = in_bounds_x?(rect, dx, flag), in_bounds_y?(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先がViewportの範囲内かどうかを判別する（ｘ座標のみ）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内に引っかかっているかをtrue/falseで取得する
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: あとで書く
    def in_bounds_x?(rect, dx, flag = true)
      nx = rect[0] + dx
      return flag ? (nx >= @rect[0] && ((nx + rect[2]) < @sq[2])) : (nx > @rect[0] && (nx + rect[2] - 1) < @sq[2])
    end

    #===移動先がViewportの範囲内かどうかを判別する（ｙ座標のみ）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内に引っかかっているかをtrue/falseで取得する
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: あとで書く
    def in_bounds_y?(rect, dy, flag = true)
      ny = rect[1] + dy
      return flag ? (ny >= @rect[1] && ((ny + rect[3]) < @sq[3])) : (ny > @rect[1] && (ny + rect[3] - 1) < @sq[3])
    end

    #===移動先がViewportの範囲内かどうかを判別して、その状態によって値を整数で返す
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは-1、プラス方向で出るときは1を返す
    #
    #返却値は上記値を[x,y]の配列で生成される。
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果([x,y]の配列)
    def in_bounds_ex?(rect, dx, dy, flag = true)
      bx, by = in_bounds_ex_x?(rect, dx, flag), in_bounds_ex_y?(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す(ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは-1、プラス方向で出るときは1を返す
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_ex_x?(rect, dx, flag = true)
      nx = rect[0] + dx
      return -1 if (nx < @rect[0]) || (flag && (nx == @rect[0]))
      return ((nx + rect[2] - 1) > @sq[2]) || (flag && ((nx + rect[2] - 1) == @sq[2])) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは-1、プラス方向で出るときは1を返す
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_ex_y?(rect, dy, flag = true)
      ny = rect[1] + dy
      return -1 if (ny < @rect[1]) || (flag && (ny == @rect[1]))
      return ((ny + rect[3] - 1) > @sq[3]) || (flag && ((ny + rect[3] - 1) == @sq[3])) ? 1 : 0
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_ex?の値と同じ
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果の配列([x,y])
    def round(rect, dx, dy, flag = true)
      bx, by = round_x(rect, dx, flag), round_y(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_ex_x?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_x(rect, dx, flag = true)
      return 0 if dx == 0
      fx = in_bounds_ex_x?(rect, dx, flag)
      @@r_exec.x[fx][@rect, rect, dx]
      return fx
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_ex_y?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_y(rect, dy, flag = true)
      return 0 if dy == 0
      fy = in_bounds_ex_y?(rect, dy, flag)
      @@r_exec.y[fy][@rect, rect, dy]
      return fy
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #
    #返却値は上記値を[x,y]の配列で生成される。
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果([x,y]の配列)
    def in_bounds_rev?(rect, dx, dy, flag = true)
      bx, by = in_bounds_rev_x?(rect, dx, flag), in_bounds_rev_y?(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev_x?(rect, dx, flag = true)
      nx = rect[0] + dx
      return 1 if (nx < @rect[0]) || (flag && (nx == @rect[0]))
      return ((nx + rect[1] - 1) > @sq[2]) || (flag && ((nx + rect[1] - 1) == @sq[2])) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev_y?(rect, dy, flag = true)
      ny = rect[1] + dy
      return 1 if (ny < @rect[1]) || (flag && (ny == @rect[1]))
      return ((ny + rect[3]) > @sq[3]) || (flag && ((ny + rect[3]) == @sq[3])) ? -1 : 0
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果の配列([x,y])
    def round_rev(rect, dx, dy, flag = true)
      bx, by = round_rev_x(rect, dx, flag), round_rev_y(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_x?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev_x(rect, dx, flag = true)
      return 0 if dx == 0
      fx = in_bounds_rev_x?(rect, dx, flag)
      @@r_exec.x[-fx][@rect, rect, dx]
      return fx
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_y?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dy_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev_y(rect, dy, flag = true)
      return 0 if dy == 0
      fy = in_bounds_rev_y?(rect, dy, flag)
      @@r_exec.y[-fy][@rect, rect, dy]
      return fy
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #
    #返却値は上記値を[x,y]の配列で生成される。
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果([x,y]の配列)
    def in_bounds_rev2?(rect, dx, dy, flag = true)
      bx, by = in_bounds_rev2_x?(rect, dx, flag), in_bounds_rev2_y?(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev2_x?(rect, dx, flag = true)
      return 0 if dx == 0
      dir = (dx <=> 0)
      nx = rect[0] + dx
      return -dir if (nx < @rect[0]) || (flag && (nx == @rect[0]))
      return ((nx + rect[2] - 1) > @sq[2]) || (flag && ((nx + rect[2] - 1) == @sq[2])) ? -dir : dir
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後に表示範囲外に出るときは符号を反転、範囲内の時は移動量をそのまま返す
    #移動後に表示範囲外に出るときは符号を反転、範囲内の時は移動量をそのまま返す
    #移動量が0のときは、0を返す
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev2_y?(rect, dy, flag = true)
      return 0 if dy == 0
      dir = (dy <=> 0)
      ny = rect[1] + dy
      return -dir if (ny < @rect[1]) || (flag && (ny == @rect[1]))
      return ((ny + rect[3] - 1) > @sq[3]) || (flag && ((ny + rect[3] - 1) == @sq[3])) ? -dir : dir
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める
    #表示範囲はビューポート(Layout#viewport メソッドで取得可能)の範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果の配列([x,y])
    def round_rev2(rect, dx, dy, flag = true)
      bx, by = round_rev2_x(rect, dx, flag), round_rev2_y(rect, dy, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_x?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev2_x(rect, dx, flag = true)
      return 0 if dx == 0
      fxx = (dx <=> 0)
      fx = in_bounds_rev2_x?(rect, dx, flag)
      fx2 = (fxx == 0 || fx * fxx > 0 ? 0 : -fx)
      @@r_exec.x[fx2][@rect, rect, dx]
      return fx
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_y?の値と同じ
    #_rect_:: 判別対象の矩形。Rect構造体のインスタンス([x,y,w,h]で構成された4要素の配列)
    #_dy_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev2_y(rect, dy, flag = true)
      return 0 if dy == 0
      fyy = (dy <=> 0)
      fy = in_bounds_rev2_y?(rect, dy, flag)
      fy2 = (fyy == 0 || fy * fyy > 0 ? 0 : -fy)
      @@r_exec.y[fy2][@rect, rect, dy]
      return fy
    end
  end
end