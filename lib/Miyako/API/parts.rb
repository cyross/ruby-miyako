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
  #==パーツ構成クラス
  #複数のスプライト・アニメーションをまとめて一つの部品として構成できるクラス
  #
  #最初に、基準となる「メインパーツ」を登録し、更にパーツ(補助パーツ)を加える
  #
  #すべての補助パーツは、すべてメインパーツにスナップされる
  #(登録したパーツのレイアウト情報が変わることに注意)
  class Parts
    include Layout
    include Enumerable
    include MiyakoTap
    extend Forwardable

    #===dp値をソートする際に値を増やす間隔
    attr_accessor :dp_interval
    #===メインパーツのオブジェクトを返す
    attr_reader :main_parts

    #_dp_:: メインパーツのdp値を返す
    #_visible_:: パーツを表示・非表示のフラグを返す
    #_visible?_:: visibleと同様
    def_delegators(:@main_parts, :dp, :visible, :visible?)

    #===Partsクラスインスタンスを生成
    #_main_parts_:: メインパーツとなるインスタンス
    def initialize(main_parts)
      init_layout

      @main_parts = main_parts
      set_layout_size(@main_parts.w, @main_parts.h)

      @main_parts.snap(self)
      @main_parts.centering

      @parts = {}
      @parts_list = []
      @main_top = true
      @dp_interval = 100
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
    #          配列の時は、0番目の要素が補助パーツ、1番目の要素がスナップ先(補助パーツを示すシンボル)を示す
    #返却値:: 自分自身
    def []=(name, *value)
      value = value.flatten
      @parts_list.push(name)
      if value.length == 1
        @parts[name] = value[0]
        @parts[name].snap(@main_parts)
      else
        @parts[name] = value[0]
        @parts[name].snap(@parts[value[1]])
      end
      @parts[name].viewport = @main_parts.viewport
      return self
    end

    #===すべての補助パーツの一覧を配列で返す
    #返却値:: パーツ名の配列(登録順)
    def parts
      return @parts_list
    end

    #===メインパーツを一番前に表示する
    #パーツ表示のソーティングも同時に行う
    #返却値:: 自分自身
    def main_top
      @main_top = true
      sort_dp
      return self
    end
    
    #===メインパーツを一番後ろに表示する
    #パーツ表示のソーティングも同時に行う
    #返却値:: 自分自身
    def main_bottom
      @main_top = false
      sort_dp
      return self
    end

    #===dp値の最大値を返す
    def max_dp
      return ([@main_parts.dp] + @parts_list.map{|k| @parts.values.dp }).compact.max
    end

    #===dp値の最小値を返す 
    def min_dp
      return ([@main_parts.dp] + @parts_list.map{|k| @parts.values.dp }).compact.min
    end
    
    #===補助パーツの表示の順番を入れ替える
    #実際は、引数の順に、dp値を大きくしている(間隔はdp_intervalメソッドで与えた値)
    #_parts_:: 補助パーツ名(シンボル)の配列。省略したときは、登録した順に与える
    #返却値:: 自分自身
    def sort_dp(*parts)
      parts = parts.dup
      @parts_list.each{|pt| parts.push(pt) unless parts.include?(pt) }
      dp = 0
      if @main_top
        parts.each{|pt|
          if @parts[pt].dp
            @parts[pt].dp = dp
            dp += @dp_interval
          end
        }
        @main_parts.dp = dp if @main_parts.dp
      else
        @main_parts.dp = dp if @main_parts.dp
        parts.each{|pt|
          if @parts[pt].dp
            dp += @dp_interval
            @parts[pt].dp = dp
          end
        }
      end
      return self
    end
    
    #===指定の補助パーツを除外する
    #_name_:: 除外するパーツ名(シンボル)
    #返却値:: 自分自身
    def remove(name)
      @main_parts.delete_snap_child(@parts[name])
      @parts.delete(name)
      return self
    end

    #===メインパーツと補助パーツに対してブロックを評価する
    #返却値:: 自分自身
    def each
      yield @main_parts
      @parts_list.each{|k|
        yield @parts[k]
      }
      return self
    end

    #===メインパーツと補助パーツをすべて表示する
    #返却値:: 自分自身
    def show
      org_visible = @main_parts.visible
      self.each{|parts| parts.show ; parts.start }
      if block_given?
        res = Proc.new.call
        hide unless org_visible
        return res
      end
      return self
    end

    #===メインパーツと補助パーツをすべて隠蔽する
    #返却値:: 自分自身
    def hide
      self.each{|parts| parts.hide ; parts.stop }
      return self
    end

    #===メインパーツと補助パーツのすべてのアニメーションを開始する
    #返却値:: 自分自身
    def start
      self.each{|parts| parts.start ; parts.show }
      return self
    end

    #===メインパーツと補助パーツのすべてのアニメーションを停止する
    #返却値:: 自分自身
    def stop
      self.each{|parts| parts.stop ;  parts.hide }
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
    
    #===パーツのビューポートを取得する
    #返却値:: ビューポートを示すRectクラスのインスタンス
    def viewport
      return @main_parts.viewport
    end

    #===パーツ共通のビューポートを設定
    #_vp_:: ビューポートを示すRectクラスのインスタンス
    #返却値:: 自分自身
    def viewport=(vp)
      @layout.viewport = vp
      @main_parts.viewport = vp
      self.each{|parts| parts.viewport = vp }
      return self
    end
    
    #===パーツに登録しているインスタンスを解放する
    def dispose
      @main_parts = nil
      @parts_list.clear
      @parts.clear
    end
  end

  #==選択肢構造体
  #選択肢を構成する要素の集合
  #
  #複数のChoice構造体のインスタンスをまとめて、配列として構成されている
  #選択肢を表示させるときは、body 自体の表示位置を変更させる必要がある
  #
  #_body_:: 選択肢を示す画像
  #_condition_:: 選択肢が選択できる条件を記述したブロック
  #_result_:: 選択した結果を示すインスタンス
  #_left_:: 左方向を選択したときに参照するChoice構造体のインスタンス
  #_right_:: 右方向を選択したときに参照するChoice構造体のインスタンス
  #_up_:: 上方向を選択したときに参照するChoice構造体のインスタンス
  #_down_:: 下方向を選択したときに参照するChoice構造体のインスタンス
  #_base_:: 構造体が要素となっている配列
  Choice = Struct.new(:body, :condition, :result, :left, :right, :up, :down, :base)

  #==選択肢を管理するクラス
  #選択肢は、Shapeクラスから生成したスプライトもしくは画像で構成される
  class Choices
    include Layout
    include SpriteBase
    include Animation
    include Enumerable
    include MiyakoTap
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
    #返却値:: 生成された Choice構造体のインスタンス
    def Choices.create_choice(body)
      choice = Choice.new(body, Proc.new{ true }, nil, nil, nil, nil, nil, nil)
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
      @choices.each{|ch|
        yield ch
      }
    end

    def_delegators(:@choices, :push, :pop, :shift, :unshift, :[], :[]=, :clear, :size, :length)

    #===選択を開始する
    #選択肢の初期位置を指定することができる
    #_x_:: 初期位置(x 座標)。規定値は 0
    #_y_:: 初期位置(y 座標)。規定値は 0
    def start_choice(x = 0, y = 0)
      @now = @choices[x][y]
    end

    #===選択肢本体を取得する
    #選択肢の表示対象となる
    #返却値::
    def body
      return @now.body
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
        obase.each{|b| b.body.hide; b.body.stop }
        nbase.each{|b| b.body.show; b.body.start }
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
      @now.each{|ch| ch.render }
      return self
    end
    
    # 選択肢を左移動させる
    # 返却値:: 自分自身を返す
    def left
      obj = @now.left
      update_choices(@now, obj)
      @now = obj
      return self
    end

    # 選択肢を右移動させる
    # 返却値:: 自分自身を返す
    def right
      obj = @now.right
      update_choices(@now, obj)
      @now = obj
      return self
    end

    # 選択肢を上移動させる
    # 返却値:: 自分自身を返す
    def up
      obj = @now.up
      update_choices(@now, obj)
      @now = obj
      return self
    end

    # 選択肢を下移動させる
    # 返却値:: 自分自身を返す
    def down
      obj = @now.down
      update_choices(@now, obj)
      @now = obj
      return self
    end

    # 選択肢を表示させる
    # 返却値:: 自分自身を返す
    def show
      @now.base.each{|c| c.body.show if c.condition.call }
      return self
    end

    # 選択肢を隠す
    # 返却値:: 自分自身を返す
    def hide
      @now.base.each{|c| c.body.hide if c.condition.call }
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
      @now.base.each{|c| c.body.update_animation if c.condition.call }
    end

    # 選択肢の表示範囲を取得する
    # 返却値:: 表示範囲(4要素の配列)
    def viewport
      return @now.body.viewport
    end

    # 選択肢の表示範囲を設定する
    # 返却値:: 自分自身を返す
    def viewport=(vp)
      @layout.viewport = vp
      @choices.each{|cc| cc.each{|c| c.viewport = vp } }
      return self
    end
  end
end
