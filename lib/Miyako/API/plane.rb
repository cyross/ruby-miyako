# Miyako plane class
=begin
--
Miyako v1.5
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
    include MiyakoTap
    extend Forwardable
    @@planes = Array.new

    attr_reader :visible
    
    def resize #:nodoc:
      @size = Size.new(((Screen.w + @sprite.w - 1) / @sprite.w + 2),
                       ((Screen.h + @sprite.h - 1) / @sprite.h + 2))
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
        @sprite.dp = -1
      end
      @visible = false
      resize
      @pos = Point.new(0, 0)
      @@planes.push(self)
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

    #===プレーンを表示する
    #返却値:: 自分自身を返す
    def show
      @visible = true
      return self
    end
    
    #===プレーンを表示する
    #返却値:: 自分自身を返す
    def hide
      @visible = false
      return self
    end
    
    #===プレーンの表示位置を移動させる
    #画像スクロールと同じ効果を得る
    #_dx_:: 移動量(x 座標)
    #_dy_:: 移動量(y 座標)
    #返却値:: 自分自身を返す
    def move(dx, dy)
      @pos.x += dx
      @pos.y += dy
      @pos.x %= @sprite.w if @pos.x >= @sprite.w || @pos.x <= -@sprite.w
      @pos.y %= @sprite.h if @pos.y >= @sprite.h || @pos.y <= -@sprite.h
      return self
    end

    #===プレーンの表示位置を移動させる(移動位置指定)
    #画像スクロールと同じ効果を得る
    #_x_:: 移動先の位置(x 座標)
    #_y_:: 移動先の位置(y 座標)
    #返却値:: 自分自身を返す
    def move_to(x, y)
      @pos.x = x
      @pos.y = y
      @pos.x %= @screen.w if @pos.x >= @sprite.w || @pos.x <= -@sprite.w
      @pos.y %= @screen.h if @pos.y >= @sprite.h || @pos.y <= -@sprite.h
      return self
    end

    #===プレーンのデータを解放する
    def dispose
      @sprite.dispose
      @@planes.delete(self)
    end

    def Plane::get_list #:nodoc:
      return @@planes
    end

    def update #:nodoc:
      return nil unless @visible
      render_inner
      return nil
    end

    def Plane::update #:nodoc:
      @@planes.each{|p| p.update }
      return nil
    end

    def render_inner #:nodoc:
      @size.h.times{|y|
        @size.w.times{|x|
          u = @sprite.to_unit
          u.x = x * @sprite.w + @pos.x
          u.y = y * @sprite.h + @pos.y
          Screen.sprite_list.push(u)
        }
      }
    end
    
    private :render_inner
    
    #===画面に描画を指示する
    #現在表示できるプレーンを、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      render_inner
      return self
    end
    
    def Plane::resize #:nodoc:
      @@planes.each{|p| p.resize }
      return nil
    end

    def_delegators(:@sprite, :dp, :dp=, :viewport, :viewport=, :type)
  end
end
