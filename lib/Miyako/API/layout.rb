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
  LayoutStruct = Struct.new(:pos, :size, :base, :off, :snap, :zero, :margin, :lower, :middle, :upper, :loc)
  #==スナップ構造体
  LayoutSnapStruct = Struct.new(:sprite, :children)
  #==レイアウト表示位置ラムダ構造体
  LayoutSideStruct = Struct.new(:inside, :between, :outside)

  #==レイアウト管理モジュール
  #位置情報やスナップ、座標丸めなどを管理する
  #本モジュールはmixinすることで機能する。
  #また、mixinする場合は、以下の処理を施すこと
  #１．クラスのinitializeメソッドの最初にinit_layoutメソッドを呼び出す
  #２．update_layout_positionメソッドを実装する
  #なお、本モジュールをmixinした場合は、インスタンス変数 @layout が予約される。
  #@layoutへのユーザアクセスは参照のみ許される。
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

    def set_base_size(w, h) #:nodoc:
      @layout.base[2] = w
      @layout.base[3] = h
      calc_layout
      return self
    end

    def reset_base_size #:nodoc:
      @layout.base[2] = nil
      @layout.base[3] = nil
      calc_layout
      return self
    end

    def set_base_point(x, y) #:nodoc:
      @layout.base[0], @layout.base[1] = [x, y]
      calc_layout
      return self
    end

    def set_base(x, y, w, h) #:nodoc:
      @layout.base[0] = x
      @layout.base[1] = y
      @layout.base[2] = w
      @layout.base[3] = h
      calc_layout
      return self
    end

    def reset_base #:nodoc:
      @layout.base[0] = 0
      @layout.base[1] = 0
      @layout.base[2] = nil
      @layout.base[3] = nil
      calc_layout
      return self
    end
    
    def get_base #:nodoc:
      return @layout.base
    end

    #===インスタンスの位置・大きさを求める
    #インスタンスの位置・大きさをRect構造体で求める
    #返却値:: Rect構造体
    def rect
      return Rect.new(@layout.pos[0], @layout.pos[1], @layout.size[0], @layout.size[1])
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
      @layout.snap.children << spr unless @layout.snap.children.include?(spr)
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
    #ブロックを渡せば、ブロックの評価中のみ移動する
    #_x_:: x 座標の移動量
    #_y_:: y 座標の移動量
    #返却値:: 自分自身を返す
    def move(x, y)
      o = @layout.off.dup
      @layout.off[0] = @layout.off[0] + x
      @layout.off[1] = @layout.off[1] + y
      calc_layout
      if block_given?
        yield
        @layout.off[0], @layout.off[1] = o
        calc_layout
      end
      return self
    end

    #===インスタンスを指定の位置に移動させる
    #ブロックを渡せば、ブロックの評価中のみ移動する
    #_x_:: 移動後の x 座標の位置
    #_y_:: 移動後の y 座標の位置
    #返却値:: 自分自身を返す
    def move_to(x, y, &block)
      move(x - @layout.pos[0], y - @layout.pos[1], &block)
      return self
    end
  end

  #==レイアウト空間クラス
  #画像を持たず、レイアウト空間のみを持つインスタンス
  #画像同士が離れているレイアウト構成を構築する際に用いる
  class LayoutSpace
    include SpriteBase
    include Animation
    include Layout
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

    #===現在の画面の最大の大きさを矩形で取得する
    #但し、LayoutSpaceの場合は最大の大きさ=スプライトの大きさなので、rectと同じ値が得られる
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      return self.rect
    end

    #===インスタンスを解放させる
    def dispose
      layout_dispose
    end
  end
end
