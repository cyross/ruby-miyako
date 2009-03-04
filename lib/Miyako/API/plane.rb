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
  #==プレーン(画面いっぱいにタイル表示される画像)を表現するクラス
  class Plane
    extend Forwardable

    def resize #:nodoc:
      @size = Size.new(((Screen.w + @sprite.ow - 1) / @sprite.ow + 2),
                       ((Screen.h + @sprite.oh - 1) / @sprite.oh + 2))
    end

    #===インスタンスの作成
    #パラメータは、Sprite.newのパラメータと同じ。但し、追加のパラメータがある。
    #
    #:sprite => (インスタンス)　：　表示対象のスプライト（アニメーション）のインスタンス
    #
    #_param_:: プレーンの情報(:sprite(=>Sprite・SpriteAnimationクラスのインスタンス))
    #返却値:: 生成したインスタンス
    def initialize(param)
      if param.has_key?(:sprite)
        @sprite = param[:sprite]
      else
        @sprite = Sprite.new(param)
      end
      resize
      @pos = Point.new(0, 0)
      @visible = true
    end

    #===プレーン画像左上の x 座標の値を取得する
    #元画像の左上の位置がどこにあるのかを示す
    #返却値:: x 座標の値
    def x
      return @pos.x
    end

    #===プレーン画像左上の y 座標の値を取得する
    #元画像の左上の位置がどこにあるのかを示す
    #返却値:: y 座標の値
    def y
      return @pos.y
    end

    #===プレーンの表示位置を移動させる
    #画像スクロールと同じ効果を得る
    #_dx_:: 移動量(x 座標)
    #_dy_:: 移動量(y 座標)
    #返却値:: 自分自身を返す
    def move(dx, dy)
      @pos.move(dx, dy)
      @pos.x %= @sprite.ow if @pos.x >= @sprite.ow || @pos.x <= -@sprite.ow
      @pos.y %= @sprite.oh if @pos.y >= @sprite.oh || @pos.y <= -@sprite.oh
      return self
    end

    #===プレーンの表示位置を移動させる(移動位置指定)
    #画像スクロールと同じ効果を得る
    #_x_:: 移動先の位置(x 座標)
    #_y_:: 移動先の位置(y 座標)
    #返却値:: 自分自身を返す
    def move_to(x, y)
      @pos.move_to(x, y)
      @pos.x %= @screen.ow if @pos.x >= @sprite.ow || @pos.x <= -@sprite.ow
      @pos.y %= @screen.oh if @pos.y >= @sprite.oh || @pos.y <= -@sprite.oh
      return self
    end

    #===画像の表示矩形を取得する
    #Planeの大きさを矩形で取得する。値は、Screen.rectメソッドの値と同じ。
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def rect
      return Screen.rect
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #但し、Planeの場合は最大の大きさ=画面の大きさなので、rectと同じ値が得られる
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      return self.rect
    end

    #===プレーンのデータを解放する
    def dispose
      @sprite.dispose
    end
    
    #===画面に描画を指示する
    #現在表示できるプレーンを、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      @size.h.times{|y|
        @size.w.times{|x|
          u = @sprite.to_unit
          u.move_to(x * @sprite.ow + @pos.x, y * @sprite.oh + @pos.y)
          Screen.render_screen(u) if u.x >= 0 && u.y >= 0 && u.x + u.ow <= Screen.screen.w && u.y + u.oh <= Screen.screen.h
        }
      }
      return self
    end
    
    #===現在表示されているプレーンをSpriteクラスのインスタンスとして取得
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 取り込んだ画像を含むSpriteクラスのインスタンス
    def to_sprite
      sprite = Sprite.new(:size=>self.rect.to_a[2..3], :type=>:ac)
      self.render_to(sprite)
      yield sprite if block_given?
      return sprite
    end

    #===SpriteUnit構造体を生成する
    #いったんSpriteインスタンスを作成し、それをもとにSpriteUnit構造体を生成する。
    #返却値:: 生成したSpriteUnit構造体
    def to_unit
      return self.to_sprite.to_unit
    end

    def Plane::resize #:nodoc:
      @@planes.each{|p| p.resize }
      return nil
    end

    #===プレーンを画面に描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点にする。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、タイリングを行いながら貼り付ける。
    #visibleメソッドの値がfalseのときは描画されない。
    def render
    end

    #===プレーンを画像に描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点にする。
    #転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、タイリングを行いながら貼り付ける。
    #visibleメソッドの値がfalseのときは描画されない。
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    def render_to(dst)
    end

    def_delegators(:sprite)
  end
end
