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
  #==パーツ構成クラス
  #複数のスプライト・アニメーションをまとめて一つの部品として構成できるクラス
  #
  #最初に、基準となる「レイアウト空間(LayoutSpaceクラスのインスタンス)」を登録し、その上にパーツを加える
  #
  #すべてのパーツは、すべてレイアウト空間にスナップされる
  #(登録したパーツのレイアウト情報が変わることに注意)
  class Parts
    include Enumerable
    include Layout
    extend Forwardable

    #===Partsクラスインスタンスを生成
    #_size_:: パーツ全体の大きさ。Size構造体のインスタンスもしくは要素数が2の配列
    def initialize(size)
      @parts = {}
      @parts_list = []

      init_layout
      set_layout_size(size[0], size[1])
    end

    #===nameで示した補助パーツを返す
    #_name_:: 補助パーツに与えた名前(シンボル)
    #返却値:: 自分自身
    def [](name)
      return @parts[name]
    end

    #===補助パーツvalueをnameに割り当てる
    #_name_:: 補助パーツに与える名前(シンボル)
    #_value_:: 補助パーツのインスタンス(スプライト、テキストボックス、アニメーション、レイアウトボックスなど)
    #返却値:: 自分自身
    def []=(name, value)
      @parts_list.push(name)
      @parts[name] = value
      @parts[name].snap(self)
      return self
    end

    #===すべての補助パーツの一覧を配列で返す
    #返却値:: パーツ名の配列(登録順)
    def parts
      return @parts_list
    end

    #===指定の補助パーツを除外する
    #_name_:: 除外するパーツ名(シンボル)
    #返却値:: 自分自身
    def remove(name)
      self.delete_snap_child(@parts[name])
      @parts.delete(name)
      return self
    end

    #===メインパーツと補助パーツに対してブロックを評価する
    #返却値:: 自分自身
    def each
      @parts_list.each{|k| yield @parts[k] }
      return self
    end

    #===メインパーツと補助パーツのすべてのアニメーションを開始する
    #返却値:: 自分自身
    def start
      self.each{|parts| parts.start }
      return self
    end

    #===メインパーツと補助パーツのすべてのアニメーションを停止する
    #返却値:: 自分自身
    def stop
      self.each{|parts| parts.stop }
      return self
    end

    #===メインパーツと補助パーツのすべてのアニメーションを更新する
    #返却値:: 自分自身
    def update_animation
      self.each{|parts| parts.update_animation }
    end

    #===メインパーツと補助パーツのすべてのアニメーションを、最初のパターンに巻き戻す
    #返却値:: 自分自身
    def reset
      self.each{|parts| parts.reset }
      return self
    end

    def update #:nodoc:
      self.each{|parts| parts.update }
      return self
    end

    #===スプライトに変換した画像を表示する
    #すべてのパーツを貼り付けた、１枚のスプライトを返す
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 描画したスプライト
    def to_sprite
      rect = self.broad_rect
      sprite = Sprite.new(:size=>rect.to_a[2,2], :type=>:ac)
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
      return self.rect if @parts_list.length == 0
      rect_list = rect.zip(*(self.map{|parts| parts.broad_rect.to_a}))
      # width -> right
      rect_list[2] = rect_list[2].zip(rect_list[0]).map{|xw| xw[0] + xw[1]}
      # height -> bottom
      rect_list[3] = rect_list[3].zip(rect_list[1]).map{|xw| xw[0] + xw[1]}
      x, y = rect_list[0].min, rect_list[1].min
      return Rect.new(x, y, rect_list[2].max - x, rect_list[3].max - y)
    end

    #===パーツに登録しているインスタンスを解放する
    def dispose
      @parts_list.clear
      @parts_list = nil
      @parts.clear
      @parts = nil
    end
  end
end
