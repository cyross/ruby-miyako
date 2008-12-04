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
    
    def Plane::resize #:nodoc:
      @@planes.each{|p| p.resize }
      return nil
    end

    def_delegators(:sprite)
  end
end
