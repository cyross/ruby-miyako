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
      init_layout
      set_layout_size(size[0], size[1])

      @parts = {}
      @parts_list = []
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

    #===メインパーツと補助パーツのすべてのアニメーションを更新する(自動実行)
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

    #===メインパーツと補助パーツのすべてのアニメーションを更新する(自動実行)
    #返却値:: 自分自身
    def update
      self.update_animation
      return self
    end

    #===スプライトに変換した画像を表示する(ただし、このオブジェクトでは自分自身を帰す)
    #返却値:: 自分自身
    def to_sprite
      return self
    end
    
    #===画面に描画を指示する
    #現在表示できる選択肢を、現在の状態で描画するよう指示する
    #
    #デフォルトでは、描画順は登録順となる。順番を変更したいときは、renderメソッドをオーバーライドする必要がある
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      self.each{|parts| parts.render }
      return self
    end
    
    #===パーツに登録しているインスタンスを解放する
    def dispose
      @parts_list.clear
      @parts_list = nil
      @parts.clear
      @parts = nil
    end
  end

  #==選択肢構造体
  #選択肢を構成する要素の集合
  #
  #複数のChoice構造体のインスタンスをまとめて、配列として構成されている
  #選択肢を表示させるときは、body 自体の表示位置を変更させる必要がある
  #
  #_body_:: 選択肢を示す画像
  #_body_selected_:: 選択肢を示す画像(選択時) 
  #_condition_:: 選択肢が選択できる条件を記述したブロック
  #_selected_:: 選択肢が選択されているときはtrue、選択されていないときはfalse
  #_result_:: 選択した結果を示すインスタンス
  #_left_:: 左方向を選択したときに参照するChoice構造体のインスタンス
  #_right_:: 右方向を選択したときに参照するChoice構造体のインスタンス
  #_up_:: 上方向を選択したときに参照するChoice構造体のインスタンス
  #_down_:: 下方向を選択したときに参照するChoice構造体のインスタンス
  #_base_:: 構造体が要素となっている配列
  Choice = Struct.new(:body, :body_selected, :condition, :selected, :result, :left, :right, :up, :down, :base)

  #==選択肢を管理するクラス
  #選択肢は、Shapeクラスから生成したスプライトもしくは画像で構成される
  class Choices
    include Layout
    include SpriteBase
    include Animation
    include Enumerable
    extend Forwardable

    # インスタンスを生成する
    # 返却値:: 生成された Choices クラスのインスタンス
    def initialize
      @choices = []
      @now = nil
    end

    # 選択肢を作成する
    # Choice 構造体のインスタンスを作成する
    # 
    # 構造体には、引数bodyと、必ず true を返す条件ブロックが登録されている。残りは nil
    #_body_:: 選択肢を示す画像
    #_body_selected_:: 選択肢を示す画像(選択時)。デフォルトはnil
    #_selected_:: 生成時に選択されているときはtrue、そうでないときはfalseを設定する
    #返却値:: 生成された Choice構造体のインスタンス
    def Choices.create_choice(body, body_selected = nil, selected = false)
      choice = Choice.new(body, body_selected, Proc.new{ true }, selected,
                          nil, nil, nil, nil, nil, nil)
      choice.left = choice
      choice.right = choice
      choice.up = choice
      choice.down = choice
      return choice
    end

    # 選択肢集合(Choice 構造体の配列)を選択肢リストに登録する
    def create_choices(choices)
      choices.each{|v| v.base = choices}
      @choices.push(choices)
      return self
    end

    # 選択肢データを解放する
    def dispose
      @choices.each{|c| c.clear }
      @choices.clear
      @choices = []
    end

    def each #:nodoc:
      @choices.each{|ch| yield ch }
    end

    def_delegators(:@choices, :push, :pop, :shift, :unshift, :[], :[]=, :clear, :length)

    #===選択を開始する
    #選択肢の初期位置を指定することができる
    #_x_:: 初期位置(x 座標)。規定値は 0
    #_y_:: 初期位置(y 座標)。規定値は 0
    def start_choice(x = 0, y = 0)
      @now = @choices[x][y]
      @now.selected = true
    end

    #===選択肢本体を取得する
    #選択肢の表示対象となる
    #返却値::
    def body
      return @now.body_selected ? @now.body_selected : @now.body
    end

    #===選択結果を取得する
    #現在の選択肢が所持している結果インスタンスを返す
    #返却値:: 選択結果
    def result
      return @now.result
    end

    def update_choices(org, nxt) #:nodoc:
      obase = org.base
      nbase = nxt.base
      unless obase.eql?(nbase)
        obase.each{|b|
          b.body.stop
          b.body_selected.stop if b.body_selected
        }
        nbase.each{|b|
          b.body.start
          b.body_selected.start if b.body_selected
        }
      end
    end

    private :update_choices

    #===画面に描画を指示する
    #現在表示できる選択肢を、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      @now.base.each{|c|
        ((c.body_selected && c.selected) ?
          c.body_selected.render :
          c.body.render) if c.condition.call
      }
      return self
    end
    
    # 選択肢を左移動させる
    # 返却値:: 自分自身を返す
    def left
      @now.selected = false
      obj = @now.left
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    # 選択肢を右移動させる
    # 返却値:: 自分自身を返す
    def right
      @now.selected = false
      obj = @now.right
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    # 選択肢を上移動させる
    # 返却値:: 自分自身を返す
    def up
      @now.selected = false
      obj = @now.up
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    # 選択肢を下移動させる
    # 返却値:: 自分自身を返す
    def down
      @now.selected = false
      obj = @now.down
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    # 選択肢のアニメーションを開始する
    # 返却値:: 自分自身を返す
    def start
      @now.base.each{|c| c.body.start if c.condition.call }
      return self
    end

    # 選択肢のアニメーションを終了させる
    # 返却値:: 自分自身を返す
    def stop
      @now.base.each{|c| c.body.stop if c.condition.call }
      return self
    end

    # 選択肢のアニメーションの再生位置を最初に戻す
    # 返却値:: 自分自身を返す
    def reset
      @now.base.each{|c| c.body.reset if c.condition.call }
      return self
    end

    # 選択肢のアニメーションを更新させる
    # (手動で更新する必要があるときに呼び出す)
    # 返却値:: 自分自身を返す
    def update_animation
      @now.base.each{|c|
        ((c.body_selected && c.selected) ?
         c.body_selected.update_animation :
         c.body.update_animation) if c.condition.call
      }
    end
  end
end
