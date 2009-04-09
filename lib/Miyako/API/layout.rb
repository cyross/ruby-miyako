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
  LayoutStruct = Struct.new(:pos, :size, :base, :snap, :on_move)
  #==スナップ構造体
  LayoutSnapStruct = Struct.new(:sprite, :children)

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
      @layout.pos  = Point.new(0, 0)
      @layout.size = Size.new(0, 0)
      @layout.base = Screen
      @layout.snap = LayoutSnapStruct.new(nil, Array.new)
      @layout.on_move = []
    end

    #===位置移動時に呼び出すブロックを管理する配列にアクセする
    #moveやleftメソッドを呼び出した時に評価したいブロックを渡すことで、付随処理を自律して行うことが出来る。
    #引数は、|self, x, y, dx, dy|の5つ。
    #各引数は、「レシーバ, 移動後x座標位置, 移動後y座標位置, x座標移動量, y座標移動量」の機能がある。
    #評価が行われるのは、left,outside_left,center,right,outside_right,top,outside_top,middle,bottom,outside_bottom
    #move,move_toの各メソッド。
    #返却値:: ブロック管理配列
    def on_move
			return @layout.on_move
    end

    #===mixinしたインスタンスの位置を左端(x軸)に移動させる
		#設置するとき、基準となる空間の内側に設置される
    #ブロックでは、数値を返却することで、左端からのマージンを設定できる(正の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def left(&margin)
			base = @layout.base.rect
			t = @layout.pos[0]
			@layout.pos[0] = base[0] + (margin ? margin[base[2]].to_i : 0)
      @layout.snap.children.each{|c| c.left(&margin) }
      update_layout(@layout.pos[0]-t, 0)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], @layout.pos[0]-t, 0)}
			return self
    end

    #===mixinしたインスタンスの位置を左端(x軸)に移動させる
		#設置するとき、基準となる空間の外側に設置される
    #ブロックでは、数値を返却することで、左端からのマージンを設定できる(負の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def outside_left(&margin)
			base = @layout.base.rect
			t = @layout.pos[0]
			@layout.pos[0] = base[0] - @layout.size[0] - (margin ? margin[base[2]].to_i : 0)
      update_layout(@layout.pos[0]-t, 0)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], @layout.pos[0]-t, 0)}
			return self
    end

    #===mixinしたインスタンスの位置を中間(ｘ軸)に移動させる
    #返却値:: 自分自身
    def center
			base = @layout.base.rect
			t = @layout.pos[0]
			@layout.pos[0] = base[0] + (base[2] >> 1) - (@layout.size[0] >> 1)
      update_layout(@layout.pos[0]-t, 0)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], @layout.pos[0]-t, 0)}
			return self
    end

    #===mixinしたインスタンスの位置を右端(ｘ軸)に移動させる
		#設置するとき、基準となる空間の内側に設置される
    #ブロックでは、数値を返却することで、右端からのマージンを設定できる(負の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def right(&margin)
			base = @layout.base.rect
			t = @layout.pos[0]
			@layout.pos[0] = base[0] + base[2] - @layout.size[0] - (margin ? margin[base[2]].to_i : 0)
      update_layout(@layout.pos[0]-t, 0)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], @layout.pos[0]-t, 0)}
			return self
    end

    #===mixinしたインスタンスの位置を右端(ｘ軸)に移動させる
		#設置するとき、基準となる空間の外側に設置される
    #ブロックでは、数値を返却することで、右端からのマージンを設定できる(正の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def outside_right(&margin)
			base = @layout.base.rect
			t = @layout.pos[0]
			@layout.pos[0] = base[0] + base[2] + (margin ? margin[base[2]].to_i : 0)
      update_layout(@layout.pos[0]-t, 0)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], @layout.pos[0]-t, 0)}
			return self
    end

    #===mixinしたインスタンスの位置を上端(y軸)に移動させる
		#設置するとき、基準となる空間の内側に設置される
    #ブロックでは、数値を返却することで、上端からのマージンを設定できる(正の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def top(&margin)
			base = @layout.base.rect
			t = @layout.pos[1]
			@layout.pos[1] = base[1] + (margin ? margin[base[3]].to_i : 0)
      update_layout(0, @layout.pos[1]-t)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], 0, @layout.pos[1]-t)}
			return self
    end

    #===mixinしたインスタンスの位置を上端(y軸)に移動させる
		#設置するとき、基準となる空間の内側に設置される
    #ブロックでは、数値を返却することで、上端からのマージンを設定できる(負の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def outside_top(&margin)
			base = @layout.base.rect
			t = @layout.pos[1]
			@layout.pos[1] = base[1] - @layout.size[1] - (margin ? margin[base[3]].to_i : 0)
      update_layout(0, @layout.pos[1]-t)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], 0, @layout.pos[1]-t)}
			return self
    end

    #===mixinしたインスタンスの位置を中間(y軸)に移動させる
    #返却値:: 自分自身
    def middle
			base = @layout.base.rect
			t = @layout.pos[1]
			@layout.pos[1] = base[1] + (base[3] >> 1) - (@layout.size[1] >> 1)
      update_layout(0, @layout.pos[1]-t)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], 0, @layout.pos[1]-t)}
			return self
    end

    #===mixinしたインスタンスの位置を下端(y軸)に移動させる
		#設置するとき、基準となる空間の内側に設置される
    #ブロックでは、数値を返却することで、下端からのマージンを設定できる(負の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def bottom(&margin)
			base = @layout.base.rect
			t = @layout.pos[1]
			@layout.pos[1] = base[1] + base[3] - @layout.size[1] - (margin ? margin[base[3]].to_i : 0)
      update_layout(0, @layout.pos[1]-t)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], 0, @layout.pos[1]-t)}
			return self
    end

    #===mixinしたインスタンスの位置を下端(y軸)に移動させる
		#設置するとき、基準となる空間の外側に設置される
    #ブロックでは、数値を返却することで、下端からのマージンを設定できる(正の方向へ移動)
    #ブロック引数は、自分自身の幅
    #返却値:: 自分自身
    def outside_bottom(&margin)
			base = @layout.base.rect
			t = @layout.pos[1]
			@layout.pos[1] = base[1] + base[3] + (margin ? margin[base[3]].to_i : 0)
      update_layout(0, @layout.pos[1]-t)
      @layout.on_move.each{|block| block.call(self, @layout.pos[0], @layout.pos[1], 0, @layout.pos[1]-t)}
			return self
    end
    
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
		#このメソッドが呼び出されると、スナップ先のインスタンスの位置情報がリセットされることに注意
    #_w_:: インスタンスの幅(たとえば、Sprite#ow の値)
    #_h_:: インスタンスの幅(たとえば、Sprite#oh の値)
    #返却値:: 自分自身を返す
    def set_layout_size(w, h)
      @layout.size[0] = w
      @layout.size[1] = h
      return self
    end

    #===レイアウト情報の値を更新する
    #_dx_:: 位置の変化量(x方向)
    #_dx_:: 位置の変化量(y方向)
    def update_layout(dx, dy)
      update_layout_position
      @layout.snap.children.each{|sc| sc.update_layout(dx, dy) }
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
      @layout.base = @layout.snap.sprite || Screen
      return self
    end
    
    #===すべてのインスタンスとの依存関係を解消する
		#このメソッドが呼び出されると、スナップ先のインスタンスの位置情報がリセットされることに注意
    #返却値:: 自分自身を返す
    def reset_snap
      @layout.snap.sprite =nil
      @layout.base = Screen
      @layout.snap.children = Array.new
      return self
    end
    
    def add_snap_child(spr) #:nodoc:
      @layout.snap.children << spr unless @layout.snap.children.include?(spr)
      return self
    end
    
    def delete_snap_child(spr) #:nodoc:
      spr.each{|s| @layout.snap.children.delete(s) }
      return self
    end
    
    def get_snap_children #:nodoc:
      return @layout.snap.children
    end

    def set_snap_children(cs) #:nodoc:
      @layout.snap.children.each{|c| c.set_snap_sprite(nil) }
      @layout.snap.children = cs
      @layout.snap.children.each{|c| c.set_snap_sprite(self) }
      return self
    end

    def get_snap_sprite #:nodoc:
      return @layout.snap.sprite
    end

    def set_snap_sprite(ss) #:nodoc:
      @layout.snap.sprite.delete_snap_child(self) if @layout.snap.sprite
      @layout.snap.sprite = ss
      @layout.snap.sprite.add_snap_child(self) if @layout.snap.sprite
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
    #ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_x_:: x 座標の移動量
    #_y_:: y 座標の移動量
    #返却値:: 自分自身を返す
    def move(x, y)
    end

    #===インスタンスを指定の位置に移動させる
    #ブロックを渡したとき、ブロックの評価した結果、偽になったときは移動させた値を元に戻す
    #_x_:: 移動後の x 座標の位置
    #_y_:: 移動後の y 座標の位置
    #返却値:: 自分自身を返す
    def move_to(x, y, &block)
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
