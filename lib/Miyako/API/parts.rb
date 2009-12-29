# -*- encoding: utf-8 -*-
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
  #==パーツ構成クラス
  #複数のスプライト・アニメーションをまとめて一つの部品として構成できるクラス
  #
  #最初に、基準となる「レイアウト空間(LayoutSpaceクラスのインスタンス)」を登録し、その上にパーツを加える
  #
  #すべてのパーツは、すべてレイアウト空間にスナップされる
  #(登録したパーツのレイアウト情報が変わることに注意)
  class Parts < Delegator
    include SpriteBase
    include Animation
    include Layout
    include Enumerable

    #===Partsクラスインスタンスを生成
    #_size_:: パーツ全体の大きさ。Size構造体のインスタンスもしくは要素数が2の配列
    def initialize(size)
      @list = SpriteList.new

      init_layout
      set_layout_size(size[0], size[1])
    end

    def __getobj__
      @list
    end

    def __setobj__(obj)
    end

    def initialize_copy(obj) #:nodoc:
      copy_layout
      @list = SpriteList.new
      obj.sprite_list.each{|pair|
        @list[pair.name] = pair.body.deep_dup
        @list[pair.name].snap(self)
      }
      self
    end

    #===補助パーツvalueをnameに割り当てる
    #_name_:: 補助パーツに与える名前(シンボル)
    #_value_:: 補助パーツのインスタンス(スプライト、テキストボックス、アニメーション、レイアウトボックスなど)
    #返却値:: 自分自身
    def []=(name, value)
      @list[name] = value
      @list[name].snap(self)
      self
    end

    #===名前・スプライトの対を登録する
    #リストに名前・スプライトをリストの後ろに追加する
    #効果はSpriteList#addと同じだが、複数の対を登録できることが特徴
    #(例)push([name1,sprite1])
    #    push([name1,sprite1],[name2,sprite2])
    #_pairs_:: 名前とスプライトの対を配列にしたもの。対は、[name,sprite]として渡す。
    #返却値:: 追加した自分自身を渡す
    def push(*pairs)
      pairs.each{|pair|
        @list.push(pair)
        @list[pair[0]].snap(self)
      }
      return self
    end

    #===指定した数の要素を先頭から取り除く
    #SpriteListの先頭からn個の要素を取り除いて、新しいSpriteListとする。
    #nがマイナスの時は、後ろからn個の要素を取り除く。
    #nが0の時は、空のSpriteListを返す。
    #自分自身に何も登録されていなければnilを返す
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.delete(:b)
    #      =>a=SpriteList(pair(:a),pair(:c))
    #        b=SpriteList(pair(:b))
    #    b=a.delete(:d)
    #      =>a=SpriteList(pair(:a),pair(:b),pair(:c))
    #        b=nil
    #_n_:: 取り除く要素数。省略時は1
    #返却値:: 取り除いたスプライト
    def delete(name)
      ret = @list.delete
      ret.body.reset_snap
      ret.body
    end

    def sprite_list #:nodoc:
      return @list
    end

    #===すべての補助パーツの一覧を配列で返す
    #返却値:: パーツ名の配列(登録順)
    def parts
      return @list.names
    end

    #===指定の補助パーツを除外する
    #_name_:: 除外するパーツ名(シンボル)
    #返却値:: 自分自身
    def remove(name)
      @list.delete(name)
      return self
    end

    #===スプライトに変換した画像を表示する
    #すべてのパーツを貼り付けた、１枚のスプライトを返す
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 描画したスプライト
    def to_sprite
      rect = self.broad_rect
      sprite = Sprite.new(:size=>rect.to_a[2,2], :type=>:ac)
      Drawing.fill(sprite, [0,0,0])
      Bitmap.ck_to_ac!(sprite, [0,0,0])
      self.render_to(sprite){|sunit, dunit| sunit.x -= rect.x; sunit.y -= rect.y }
      yield sprite if block_given?
      return sprite
    end

    #===SpriteUnit構造体を生成する
    #いったんSpriteインスタンスを作成し、それをもとにSpriteUnit構造体を生成する。
    #返却値:: 生成したSpriteUnit構造体
    def to_unit
      return self.to_sprite.to_unit
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #各パーツの位置により、取得できる矩形の大きさが変わる
    #但し、パーツ未登録の時は、インスタンス生成時の大きさから矩形を生成する
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      rect = self.rect.to_a
      return self.rect if @list.length == 0
      rect_list = rect.zip(*(self.map{|pair| pair[1].broad_rect.to_a}))
      # width -> right
      rect_list[2] = rect_list[2].zip(rect_list[0]).map{|xw| xw[0] + xw[1]}
      # height -> bottom
      rect_list[3] = rect_list[3].zip(rect_list[1]).map{|xw| xw[0] + xw[1]}
      x, y = rect_list[0].min, rect_list[1].min
      return Rect.new(x, y, rect_list[2].max - x, rect_list[3].max - y)
    end

    #===パーツに登録しているインスタンスを解放する
    def dispose
      @list.dispose
    end

    def render
      @list.render
    end

    def render_to(dst)
      @list.render_to(dst)
    end

    def visible
      @list.visible
    end

    def visible=(f)
      @list.visible=f
    end

    def show
      @list.show
    end

    def hide
      @list.hide
    end

    def start
      @list.start
    end

    def stop
      @list.stop
    end

    def reset
      @list.reset
    end

    def update_animation
      @list.update_animation
    end

    def each
      @list.each
    end

    def move!(dx, dy, &block)
      @list.move!(dx, dy, &block)
    end

    def move_to!(x, y, &block)
      @list.move_to!(x, y, &block)
    end
  end
end
