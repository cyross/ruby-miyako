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

class Numeric
  #===自身の値を割合として、値を算出する
  #_base_:: 算出元の値
  #返却値:: baseのself割りの値を返す
  #
  #(例)self=0.5、base=1000のとき、1000*0.5=500が出力される
  def ratio(base)
    return self * base
  end

  #===自身の値をパーセンテージとして、値を算出する
  #_base_:: 算出元の値
  #返却値:: baseのself%の値を返す
  #
  #(例)self=10、base=100のとき、100*10/100(%)=10が出力される
  def percent(base)
    return self * base / 100
  end

  #ピクセル値をそのまま返す
  #返却値:: 自分自身を返す
  def px
    return self
  end
end

module Miyako

  #==レイアウト情報を示す構造体
  LayoutStruct = Struct.new(:pos, :size, :base, :off, :snap, :r_exec, :zero, :margin, :lower, :middle, :upper, :loc, :viewport)
  #==スナップ構造体
  LayoutSnapStruct = Struct.new(:sprite, :children)
  #==ラムダ構造体
  LayoutRExecStruct = Struct.new(:x, :y)
  #==レイアウト表示位置ラムダ構造体
  LayoutSideStruct = Struct.new(:inside, :between, :outside)

  #==レイアウト管理モジュール
  #位置情報やスナップ、座標丸めなどを管理する
  #なお、本モジュールをmixinした場合は、インスタンス変数 @layout が予約される。
  #@kayoutへの参照のみ許される。
  module Layout
    #===現在の位置情報を別のインスタンス変数に反映させるためのテンプレートメソッド
    #move や centering などのメソッドを呼び出した際に@layout［:pos］の値を反映させるときに使う
    #(例)@sprite.move(*@layout［:pos］)
    def update_layout_position
    end

    #===レイアウト管理の初期化
    #mixin したクラスの initialize メソッド内で必ず呼び出しておくこと
    def init_layout
      @layout = LayoutStruct.new
      @layout.pos     = Point.new(0, 0)
      @layout.size    = Size.new(0, 0)
      @layout.base    = Rect.new(0, 0, nil, nil)
      @layout.off     = Point.new(0, 0)
      @layout.snap   = LayoutSnapStruct.new(nil, Array.new)
      @layout.r_exec  = LayoutRExecStruct.new
      @layout.r_exec.x = [lambda{|vp, dx| self.move_to(@layout.pos[0] + dx,             @layout.pos[1])},
                                        lambda{|vp, dx| self.move_to(vp[0] + vp[2] - @layout.size[0], @layout.pos[1])},
                                        lambda{|vp, dx| self.move_to(vp[0],                             @layout.pos[1])}
                                       ]
       @layout.r_exec.y = [lambda{|vp, dy| self.move_to(@layout.pos[0],                  @layout.pos[1] + dy)},
                                         lambda{|vp, dy| self.move_to(@layout.pos[0],                  vp[1] + vp[3] -  @layout.size[1])},
                                         lambda{|vp, dy| self.move_to(@layout.pos[0],                  vp[1])}
                                        ]
      @layout.zero   = lambda{|data| 0 }
      @layout.margin  = [@layout.zero,   @layout.zero]

      @layout.lower               = LayoutSideStruct.new
      @layout.lower.inside     = lambda{|pos, base_size| @layout.base[pos]                                       + @layout.margin[pos][base_size].to_i}
      @layout.lower.between = lambda{|pos, base_size| @layout.base[pos]               - @layout.size[pos]/2 + @layout.margin[pos][base_size].to_i}
      @layout.lower.outside   = lambda{|pos, base_size| @layout.base[pos]               - @layout.size[pos]   + @layout.margin[pos][base_size].to_i}
      @layout.middle              = LayoutSideStruct.new
      @layout.middle.inside    = lambda{|pos, base_size| @layout.base[pos] + base_size/2 - @layout.size[pos]   + @layout.margin[pos][base_size].to_i}
      @layout.middle.between= lambda{|pos, base_size| @layout.base[pos] + base_size/2 - @layout.size[pos]/2 + @layout.margin[pos][base_size].to_i}
      @layout.middle.outside =  lambda{|pos, base_size| @layout.base[pos] + base_size/2                         + @layout.margin[pos][base_size].to_i}
      @layout.upper               = LayoutSideStruct.new
      @layout.upper.inside    = lambda{|pos, base_size| @layout.base[pos] + base_size   - @layout.size[pos]   - @layout.margin[pos][base_size].to_i}
      @layout.upper.between = lambda{|pos, base_size| @layout.base[pos] + base_size   - @layout.size[pos]/2 - @layout.margin[pos][base_size].to_i}
      @layout.upper.outside = lambda{|pos, base_size| @layout.base[pos] + base_size                           + @layout.margin[pos][base_size].to_i}

      @layout.loc     = [@layout.lower.inside,   @layout.lower.inside]
    end

    #===mixinしたインスタンスの位置を左端(x軸)に移動させる
    #ブロックでは、数値を返却することで、左端からのマージンを設定できる
    #ブロック引数は、自分自身の幅
    #_side_:: 設置する側。:inside、:between、:outside の3種類ある。デフォルトは :inside
    #返却値:: 自分自身
    def left(side=:inside,   &margin)
      set_layout_inner(0, @layout.lower[side],  margin)
      return self
    end

    #===mixinしたインスタンスの位置を中間(ｘ軸)に移動させる
    #ブロックでは、数値を返却することで、真ん中からのマージンを設定できる
    #ブロック引数は、自分自身の幅
    #_side_:: 設置する側。但し機能するのは :between のみ。デフォルトは :between
    #返却値:: 自分自身
    def center(side=:between, &margin)
      set_layout_inner(0, @layout.middle[side], margin)
      return self
    end

    #===mixinしたインスタンスの位置を右端(ｘ軸)に移動させる
    #ブロックでは、数値を返却することで、右端からのマージンを設定できる
    #ブロック引数は、自分自身の幅
    #_side_:: 設置する側。:inside、:between、:outside の3種類ある。デフォルトは :inside
    #返却値:: 自分自身
    def right(side=:inside,  &margin)
      set_layout_inner(0, @layout.upper[side],  margin) 
      return self
    end

    #===mixinしたインスタンスの位置を上端(y軸)に移動させる
    #ブロックでは、数値を返却することで、上端からのマージンを設定できる
    #ブロック引数は、自分自身の幅
    #_side_:: 設置する側。:inside、:between、:outside の3種類ある。デフォルトは :inside
    #返却値:: 自分自身
    def top(side=:inside,    &margin)
      set_layout_inner(1, @layout.lower[side],  margin)
      return self
    end

    #===mixinしたインスタンスの位置を中間(y軸)に移動させる
    #ブロックでは、数値を返却することで、真ん中からのマージンを設定できる
    #ブロック引数は、自分自身の幅
    #_side_:: 設置する側。但し機能するのは :between のみ。デフォルトは :between
    #返却値:: 自分自身
    def middle(side=:between, &margin)
      set_layout_inner(1, @layout.middle[side], margin)
      return self
    end

    #===mixinしたインスタンスの位置を下端(y軸)に移動させる
    #ブロックでは、数値を返却することで、下端からのマージンを設定できる
    #ブロック引数は、自分自身の幅
    #_side_:: 設置する側。:inside、:between、:outside の3種類ある。デフォルトは :inside
    #返却値:: 自分自身
    def bottom(side=:inside, &margin)
      set_layout_inner(1, @layout.upper[side],  margin)
      return self
    end

    def set_layout_inner(pos, lambda, margin) #:nodoc:
      @layout.loc[pos] = lambda
      @layout.margin[pos] = margin || @layout.zero
      @layout.off.x = 0 if pos == 0
      @layout.off.y = 0 if pos == 1
      calc_layout
    end

    private :set_layout_inner
    
    #===レイアウトに関するインスタンスを解放する
    #インスタンス変数 @layout 内のインスタンスを解放する
    def layout_dispose
      @layout.snap.sprite.delete_snap_child(self) if @layout.snap.sprite
      @layout.snap.children.each{|sc| sc.reset_snap }
    end

    #=== mixin されたインスタンスの x 座標の値を取得する
    #返却値:: x 座標の値(@layout［:pos］［0］の値)
    def x
      return @layout.pos[0]
    end

    #=== mixin されたインスタンスの y 座標の値を取得する
    #返却値:: y 座標の値(@layout［:pos］［1］の値)
    def y
      return @layout.pos[1]
    end

    #=== mixin されたインスタンスの幅を取得する
    #返却値:: インスタンスの幅(@layout［:size］［0］の値)
    def w
      return @layout.size[0]
    end

    #=== mixin されたインスタンスの高さを取得する
    #返却値:: インスタンスの高さ(@layout［:size］［1］の値)
    def h
      return @layout.size[1]
    end

    #=== mixin されたインスタンスの位置情報(x,yの値)を取得する
    #返却値:: インスタンスの位置情報(@layout［:pos］の値)
    def pos
      return @layout.pos
    end
    
    #=== mixin されたインスタンスのサイズ情報(w,hの値)を取得する
    #返却値:: インスタンスのサイズ情報(@layout［:size］の値)
    def size
      return @layout.size
    end
    
    #=== mixin されたインスタンスの表示上の幅を取得する
    #返却値:: インスタンスの幅(@layout［:size］［0］の値)
    def ow
      return @layout.size[0]
    end
    
    #=== mixin されたインスタンスの表示上の高さを取得する
    #返却値:: インスタンスの高さ(@layout［:size］［0］の値)
    def oh
      return @layout.size[1]
    end

    #===インスタンスのサイズをレイアウト情報に反映させる
    #_w_:: インスタンスの幅(たとえば、Sprite#ow の値)
    #_h_:: インスタンスの幅(たとえば、Sprite#oh の値)
    #返却値:: 自分自身を返す
    def set_layout_size(w, h)
      @layout.size[0] = w
      @layout.size[1] = h
      calc_layout
      return self
    end

    def get_base_width #:nodoc:
      return @layout.base[2] || Screen.w
    end

    def get_base_height #:nodoc:
      return @layout.base[3] || Screen.h
    end

    private :get_base_width, :get_base_height

    #===レイアウト情報の値を更新する
    def calc_layout
      @layout.pos[0] = @layout.loc[0][0, get_base_width]  + @layout.off[0]
      @layout.pos[1] = @layout.loc[1][1, get_base_height] + @layout.off[1]
      update_layout_position
      @layout.snap.children.each{|sc|
        sc.snap
      }
    end

    #===あとで書く
    #_w_:: あとで書く
    #_h_:: あとで書く
    #返却値:: あとで書く
    def set_base_size(w, h)
      @layout.base[2] = w
      @layout.base[3] = h
      calc_layout
      return self
    end

    #===あとで書く
    #返却値:: あとで書く
    def reset_base_size
      @layout.base[2] = nil
      @layout.base[3] = nil
      calc_layout
      return self
    end

    #===あとで書く
    #_x_:: あとで書く
    #_y_:: あとで書く
    #返却値:: あとで書く
    def set_base_point(x, y)
      @layout.base[0], @layout.base[1] = [x, y]
      calc_layout
      return self
    end

    #===あとで書く
    #_x_:: あとで書く
    #_y_:: あとで書く
    #_w_:: あとで書く
    #_h_:: あとで書く
    #返却値:: あとで書く
    def set_base(x, y, w, h)
      @layout.base[0] = x
      @layout.base[1] = y
      @layout.base[2] = w
      @layout.base[3] = h
      calc_layout
      return self
    end

    #===あとで書く
    #返却値:: あとで書く
    def reset_base
      @layout.base[0] = 0
      @layout.base[1] = 0
      @layout.base[2] = nil
      @layout.base[3] = nil
      calc_layout
      return self
    end
    
    #===あとで書く
    #返却値:: あとで書く
    def get_base
      return @layout.base
    end

    #===あとで書く
    #返却値:: あとで書く
    def rect
      return Rect.new(*(@layout.pos.to_a + @layout.size.to_a))
    end

    #===インスタンスのレイアウトを指定の別のインスタンスに依存(スナップ)させる
    #引数 spr で指定したインスタンスのレイアウト情報は、レシーバのレイアウト情報に依存した位置情報を算出される
    #デフォルトでは、画面にスナップされている状態になっている
    #_spr_:: 位置情報を依存させるインスタンス。デフォルトは nil (画面が対象になる)
    #返却値:: 自分自身を返す
    def snap(spr = nil)
      if spr
        @layout.snap.sprite.delete_snap_child(self) if @layout.snap.sprite
        @layout.snap.sprite = spr
        spr.add_snap_child(self)
      end
      if @layout.snap.sprite
        rect = @layout.snap.sprite.rect
        @layout.base[0] = rect[0]
        @layout.base[1] = rect[1]
        @layout.base[2] = rect[2]
        @layout.base[3] = rect[3]
      end
      calc_layout
      return self
    end
    
    #===すべてのインスタンスとの依存関係を解消する
    #返却値:: 自分自身を返す
    def reset_snap
      @layout.snap.sprite =nil
      @layout.snap.children = Array.new
      calc_layout
      return self
    end
    
    def add_snap_child(spr) #:nodoc:
      @layout.snap.children.push(spr) unless @layout.snap.children.include?(spr)
      calc_layout
      return self
    end
    
    def delete_snap_child(spr) #:nodoc:
      spr.each{|s| @layout.snap.children.delete(s) }
      calc_layout
      return self
    end
    
    def get_snap_children #:nodoc:
      return @layout.snap.children
    end

    def set_snap_children(cs) #:nodoc:
      @layout.snap.children.each{|c| c.set_snap_sprite(nil) }
      @layout.snap.children = cs
      @layout.snap.children.each{|c|
        c.set_snap_sprite(self)
      }
      calc_layout
      return self
    end

    def get_snap_sprite #:nodoc:
      return @layout.snap.sprite
    end

    def set_snap_sprite(ss) #:nodoc:
      @layout.snap.sprite.delete_snap_child(self) if @layout.snap.sprite
      @layout.snap.sprite = ss
      @layout.snap.sprite.add_snap_child(self) if @layout.snap.sprite
      calc_layout
      return self
    end

    #===インスタンスを画面(スナップ先インスタンス)の中心に移動する
    #返却値:: 自分自身を返す
    def centering
      center
      middle
      return self
    end

    #===インスタンスを指定の移動量で移動させる
    #_x_:: x 座標の移動量
    #_y_:: y 座標の移動量
    #返却値:: 自分自身を返す
    def move(x, y)
      @layout.off[0] = @layout.off[0] + x
      @layout.off[1] = @layout.off[1] + y
      calc_layout
      return self
    end

    #===インスタンスを指定の位置に移動させる
    #_x_:: 移動後の x 座標の位置
    #_y_:: 移動後の y 座標の位置
    #返却値:: 自分自身を返す
    def move_to(x, y)
      move(x - @layout.pos[0], y - @layout.pos[1])
      return self
    end

    #===移動先が表示範囲内かどうかを判別する
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲外に引っかかっているかをtrue/falseの配列[x,y]で取得する
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果（[x,y]の配列）
    def in_bounds?(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = in_bounds_x?(dx, viewport, flag), in_bounds_y?(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別する（ｘ座標のみ）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲外に引っかかっているかをtrue/falseで取得する
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: あとで書く
    def in_bounds_x?(dx, viewport = nil, flag = true)
      vp = viewport or Screen.viewport
      nx = @layout.pos[0] + dx
      return flag ? (nx <= vp[0] || ((nx + @layout.size[0]) >= (vp[0] + vp[2]))) : (nx > vp[0] && (nx + @layout.size[0]) < (vp[0] + vp[2]))
    end

    #===移動先が表示範囲内かどうかを判別する（ｙ座標のみ）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲外に引っかかっているかをtrue/falseで取得する
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: あとで書く
    def in_bounds_y?(dy, viewport = nil, flag = true)
      vp = viewport or Screen.viewport
      ny = @layout.pos[1] + dy
      return flag ? (ny >= vp[1] || ((ny + @layout.size[1]) <= (vp[1] + vp[3]))) : (ny > vp[2] && (ny + @layout.size[1]) < (vp[0] + vp[3]))
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは-1、プラス方向で出るときは1を返す
    #
    #返却値は上記値を[x,y]の配列で生成される。
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果([x,y]の配列)
    def in_bounds_ex?(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = in_bounds_ex_x?(dx, viewport, flag), in_bounds_ex_y?(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す(ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは-1、プラス方向で出るときは1を返す
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_ex_x?(dx, viewport = nil, flag = true)
      vp = viewport or Screen.viewport
      nx = @layout.pos[0] + dx
      return -1 if (nx < vp[0]) || (flag && (nx == vp[0]))
      r = vp[0] + vp[2]
      return ((nx + @layout.size[0]) > r) || (flag && ((nx + @layout.size[0]) == r)) ? 1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは-1、プラス方向で出るときは1を返す
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_ex_y?(dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      ny = @layout.pos[1] + dy
      vp = @layout.viewport
      return -1 if (ny < vp[1]) || (flag && (ny == vp[1]))
      b = vp[1] + vp[3]
      return ((ny + @layout.size[1]) > b) || (flag && ((ny + @layout.size[1]) == b)) ? 1 : 0
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
    def round(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = round_x(dx, viewport, flag), round_y(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_ex_x?の値と同じ
    #_dx_:: x座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_x(dx, viewport = nil, flag = true)
      return 0 if dx == 0
      viewport ||= Screen.viewport
      fx = in_bounds_ex_x?(dx, viewport, flag)
      @layout.r_exec.x[fx][viewport, dx]
      return fx
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_ex_y?の値と同じ
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_y(dy, viewport = nil, flag = true)
      return 0 if dy == 0
      viewport ||= Screen.viewport
      fy = in_bounds_ex_y?(dy, viewport, flag)
      @layout.r_exec.y[fy][viewport, dy]
      return fy
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #
    #返却値は上記値を[x,y]の配列で生成される。
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果([x,y]の配列)
    def in_bounds_rev?(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = in_bounds_rev_x?(dx, viewport, flag), in_bounds_rev_y?(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev_x?(dx, viewport = nil, flag = true)
      vp = viewport or Screen.viewport
      nx = @layout.pos[0] + dx
      return 1 if (nx < vp[0]) || (flag && (nx == vp[0]))
      r = vp[0] + vp[2]
      return ((nx + @layout.size[0]) > r) || (flag && ((nx + @layout.size[0]) == r)) ? -1 : 0
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev_y?(dy, viewport = nil, flag = true)
      ny = @layout.pos[1] + dy
      vp = viewport or Screen.viewport
      return 1 if (ny < vp[1]) || (flag && (ny == vp[1]))
      b = vp[1] + vp[3]
      return ((ny + @layout.size[1]) > b) || (flag && ((ny + @layout.size[1]) == b)) ? -1 : 0
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev?の値と同じ
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果の配列([x,y])
    def round_rev(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = round_rev_x(dx, viewport, flag), round_rev_y(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_x?の値と同じ
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev_x(dx, viewport = nil, flag = true)
      return 0 if dx == 0
      viewport ||= Screen.viewport
      fx = in_bounds_rev_x?(dx, viewport, flag)
      @layout.r_exec.x[-fx][viewport, dx]
      return fx
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_y?の値と同じ
    #_dy_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev_y(dy, viewport = nil, flag = true)
      return 0 if dy == 0
      viewport ||= Screen.viewport
      fy = in_bounds_rev_y?(dy, viewport, flag)
      @layout.r_exec.y[-fy][viewport, dy]
      return fy
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #
    #返却値は上記値を[x,y]の配列で生成される。
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果([x,y]の配列)
    def in_bounds_rev2?(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = in_bounds_rev2_x?(dx, viewport, flag), in_bounds_rev2_y?(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後の座標が表示範囲内のときは0、マイナス方向で表示範囲外に出るときは1、プラス方向で出るときは-1を返す
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev2_x?(dx, viewport = nil, flag = true)
      return 0 if dx == 0
      vp = viewport or Screen.viewport
      dir = (dx <=> 0)
      nx = @layout.pos[0] + dx
      return -dir if (nx < vp[0]) || (flag && (nx == vp[0]))
      r = vp[0] + vp[2]
      return ((nx + @layout.size[0]) > r) || (flag && ((nx + @layout.size[0]) == r)) ? -dir : dir
    end

    #===移動先が表示範囲内かどうかを判別して、その状態によって値を整数で返す（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #移動後に表示範囲外に出るときは符号を反転、範囲内の時は移動量をそのまま返す
    #移動後に表示範囲外に出るときは符号を反転、範囲内の時は移動量をそのまま返す
    #移動量が0のときは、0を返す
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def in_bounds_rev2_y?(dy, viewport = nil, flag = true)
      return 0 if dy == 0
      vp = viewport or Screen.viewport
      dir = (dy <=> 0)
      ny = @layout.pos[1] + dy
      return -dir if (ny < vp[1]) || (flag && (ny == vp[1]))
      b = vp[1] + vp[3]
      return ((ny + @layout.size[1]) > b) || (flag && ((ny + @layout.size[1]) == b)) ? -dir : dir
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める
    #表示範囲はビューポート(Layout#viewport メソッドで取得可能)の範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev?の値と同じ
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果の配列([x,y])
    def round_rev2(dx, dy, viewport = nil, flag = true)
      viewport ||= Screen.viewport
      bx, by = round_rev2_x(dx, viewport, flag), round_rev2_y(dy, viewport, flag)
      yield bx, by if block_given?
      return [bx, by]
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｘ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_x?の値と同じ
    #_dx_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev2_x(dx, flag = true)
      return 0 if dx == 0
      viewport ||= Screen.viewport
      fxx = (dx <=> 0)
      fx = in_bounds_rev2_x?(dx, viewport, flag)
      fx2 = (fxx == 0 || fx * fxx > 0 ? 0 : -fx)
      @layout.r_exec.x[fx2][viewport, dx]
      return fx
    end

    #===移動先が表示範囲外に引っかかるときは、移動範囲内に丸める（ｙ座標）
    #表示範囲はビューポートの範囲。デフォルトは画面の範囲内と同じ
    #
    #返却値はLayout#in_bounds_rev_y?の値と同じ
    #_dy_:: x座標の移動量
    #_viewport_:: 移動範囲。デフォルトはnil(Screen.viewportが設定される)
    #_flag_:: 画面の端いっぱいも表示範囲外に含めるときはtrueを設定する。デフォルトはtrue
    #返却値:: 判別の結果
    def round_rev2_y(dy, viewport = nil, flag = true)
      return 0 if dy == 0
      viewport ||= Screen.viewport
      fyy = (dy <=> 0)
      fy = in_bounds_rev2_y?(dy, viewport, flag)
      fy2 = (fyy == 0 || fy * fyy > 0 ? 0 : -fy)
      @layout.r_exec.y[fy2][viewport, dy]
      return fy
    end
  end

  #==レイアウト空間クラス
  #画像を持たず、レイアウト空間のみを持つインスタンス
  #画像同士が離れているレイアウト構成を構築する際に用いる
  class LayoutSpace
    include Layout
    include SpriteBase
    include Animation
    include SingleEnumerable
    extend Forwardable

    attr_accessor :dp, :visible

    #===インスタンスを生成する
    #_size_:: インスタンスの大きさ［w,h］で指定する
    #返却値:: 生成されたインスタンスを返す
    def initialize(size)
      init_layout
      set_layout_size(*(size.to_a))
    end

    #===インスタンスを解放させる
    def dispose
      layout_dispose
    end
  end
end
