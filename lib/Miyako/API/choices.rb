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
  #==選択肢構造体
  # 選択肢を構成する要素の集合
  #
  # 複数のChoice構造体のインスタンスをまとめて、配列として構成されている
  # 選択肢を表示させるときは、body 自体の表示位置を変更させる必要がある
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
  #_attribute_:: 属性を示すハッシュ
  #_end_select_proc_:: この選択肢を選択したときに優先的に処理するブロック。
  #ブロックは1つの引数を取る(コマンド選択テキストボックス))。
  #デフォルトはnil(何もしない)
  Choice = Struct.new(:body, :body_selected, :condition, :selected, :result, :left, :right, :up, :down, :base, :attribute, :end_select_proc)

  #==選択肢を管理するクラス
  # 選択肢は、Shapeクラスから生成したスプライトもしくは画像で構成される
  class Choices
    include Layout
    include SpriteBase
    include Animation
    include Enumerable
    extend Forwardable

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)

    # インスタンスを生成する
    # 返却値:: 生成された Choices クラスのインスタンス
    def initialize
      init_layout
      @choices = []
      @now = nil
      @non_select = false
      @last_selected = nil
      @result = nil
      @visible = true
      set_layout_size(1, 1)
    end

    def update_layout_position #:nodoc:
      dx = @layout.pos[0] - rect[0]
      dy = @layout.pos[1] - rect[1]
      @choices.each{|ch|
        ch.each{|cc|
          cc.body.move(dx, dy)
          cc.body_selected.move(dx, dy) if cc.body_selected && cc.body != cc.body_selected
        }
      }
    end

    # 選択肢を作成する
    # Choice 構造体のインスタンスを作成する
    # 構造体には、引数bodyと、必ず true を返す条件ブロックが登録されている。残りは nil
    #_body_:: 選択肢を示す画像
    #_body_selected_:: 選択肢を示す画像(選択時)。デフォルトはnil
    #_selected_:: 生成時に選択されているときはtrue、そうでないときはfalseを設定する
    #返却値:: 生成された Choice構造体のインスタンス
    def Choices.create_choice(body, body_selected = nil, selected = false)
      choice = Choice.new(body, body_selected, Proc.new{ true }, selected,
                          nil, nil, nil, nil, nil, nil, {}, nil)
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
      @last_selected = @choices[0][0] if (@choices.length == 1 && @last_selcted == nil)
      rect = self.broad_rect
      set_layout_size(rect.w, rect.h)
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

    #===選択を開始しているかどうかを問い合わせる
    # start_choiceメソッドを呼び出して、コマンド選択が始まっているかどうかを問い合わせ、始まっているときはtrueを返す
    #返却値:: 選択を開始しているときはtrueを返す
    def choicing?
      return @now != nil
    end

    #===選択を開始する
    # 選択肢の初期位置を指定することができる
    # 第1引数にnilを渡すと、最後に選択した選択肢が最初に選択状態にある選択肢となる
    # (例)
    # choices.start_choice # [0][0]で示す位置の選択肢を選択する
    # choices.start_choice(5,1) # [5][1]で示す位置の選択肢を選択する
    # choices.start_choice(nil) # 最後に選択した選択肢を選択する(未選択だったときは全省略時の呼び出しと等価)
    #_x_:: 初期位置(x 座標)。規定値は 0。nilを渡すと、最後に選択した選択肢が選ばれる。
    #_y_:: 初期位置(y 座標)。規定値は 0
    def start_choice(x = 0, y = 0)
      raise MiyakoError, "Illegal choice position! [#{x}][#{y}]" if (x != nil && (x < 0 || x >= @choices.length || y < 0 || y >= @choices[x].length))
      @now = x ? @choices[x][y] : @last_selected
      @now.selected = true
      @last_selected = @now
      @non_select = false
      @result = nil
    end

    #===選択を終了する
    # 選択の終了処理を行う
    # 引数に選択に使用したテキストボックスを渡し、選択状態にあるしたChoice構造体に
    #end_select_procブロックを渡しているとき、そのブロックを評価する
    # (そのとき、引数とした渡ってきたテキストボックスをブロック引数に取る)。
    #
    #_command_box_:: 選択に使用したテキストボックス。デフォルトはnil
    def end_choice(command_box = nil)
      return unless @now
      return @now.end_select_proc.call(command_box) if (command_box != nil && @now.end_select_proc != nil)
      @result = @now.result
      @now.selected = false
      @last_selected = @now
      @now = nil
      @non_select = true
    end

    #===選択肢本体を取得する
    # 選択肢の表示対象となるインスタンスを取得する
    # Choice構造体にbody_selectedが設定されている時はbody_selected、そうでなければbodyを返す
    # まだ選択が開始されていなければnilが返る
    #返却値:: 選択肢本体(選択時)
    def body
      return nil unless @now
      return @now.body_selected ? @now.body_selected : @now.body
    end

    #===選択結果を取得する
    # 現在の選択肢が所持している結果インスタンスを返す
    # まだ選択が開始されていなければnilが返る
    #返却値:: 選択結果
    def result
      return @result unless @now
      return @now.result
    end

    #===現在選択している選択肢の属性をアクセスする
    # 属性を編集・参照できるハッシュを取得する
    # まだ選択が開始されていなければnilが返る
    #返却値:: 属性(対応するChoice#attributeメソッドの値)
    def attribute
      return nil unless @now
      return @now.attribute
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

    #===選択肢を非選択状態に変更する
    #現在の選択状態を、全部選択していない状態にする
    #返却値:: 自分自身を返す
    def non_select
      @now.base.each{|c| c.selected = false } if @now
      @non_select = true
      return self
    end

    #===選択肢が選択状態かを問い合わせる
    #現在、選択肢が選択状態か非選択状態(non_selectメソッド呼び出しなど)かを問い合わせる
    #返却値:: 選択状態ならtrue、非選択状態ならfalseを返す
    def any_select?
      return !@non_select
    end

    #===選択肢を変更する
    #指定の位置の現在の選択状態を、選択状態にする
    #_x_:: x方向位置
    #_y_:: y方向位置
    #返却値:: 自分自身を返す
    def select(x, y)
      raise MiyakoError, "Not select yet!" unless @now
      raise MiyakoError, "Illegal choice position! [#{x}][#{y}]" if (x < 0 || x >= @choices.length || y < 0 || y >= @choices[x].length)
      @non_select = false
      @last_selected = @now
      @now.selected = false
      obj = @choices[x][y]
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    #===画面上の座標から、該当する選択肢を変更する
    #マウスカーソル位置などの座標から、座標を含む選択肢を選択状態にする
    #該当する場所が無ければfalseを返す
    #まだ選択を開始していないときはfalseを返す
    #_x_:: x方向位置
    #_y_:: y方向位置
    #返却値:: 選択肢が見つかったときはtrue、見つからなかったときはfalseを返す
    def attach(x, y)
      return false unless @now
      obj = @now.base.detect{|ch| ch.selected ? ch.body_selected.broad_rect.in_range?(x, y) : ch.body.broad_rect.in_range?(x, y) }
      return false unless obj
      @non_select = false
      @last_selected = @now
      @now.selected = false
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return true
    end

    #===画面上の座標から、該当する選択肢があるかどうかを問い合わせる
    #マウスカーソル位置などの座標から、座標を含む選択肢があるときはtrue、無いときはfalseを返す
    #まだ選択を開始していないときはfalseを返す
    #_x_:: x方向位置
    #_y_:: y方向位置
    #返却値:: 選択肢が見つかったときはtrue、見つからなかったときはfalseを返す
    def attach?(x, y)
      return false unless @now
      obj = @now.base.detect{|ch| ch.selected ? ch.body_selected.broad_rect.in_range?(x, y) : ch.body.broad_rect.in_range?(x, y) }
      return obj ? true : false
    end

    #===選択肢を非選択状態に変更する
    #現在の選択状態を、全部選択していない状態にする
    #返却値:: 自分自身を返す
    def non_select
      @now.base.each{|c| c.selected = false } if @now
      @non_select = true
      return self
    end

    #===画面に描画を指示する
    #現在表示できる選択肢を、現在の状態で描画するよう指示する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る。
    #ブロックの引数は、|インスタンスのSpriteUnit, 画面のSpriteUnit|となる。
    #visibleメソッドの値がfalseのとき、選択が開始されていない時は描画されない。
    #返却値:: 自分自身を返す
    def render(&block)
      return unless @visible
      return self unless @now
      @now.base.each{|c|
        ((c.body_selected && c.selected) ?
          c.body_selected.render(&block) :
          c.body.render(&block)) if c.condition.call
      }
      return self
    end

    #===画像に描画を指示する
    #現在表示できる選択肢を、現在の状態で描画するよう指示する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る。
    #ブロックの引数は、|インスタンスのSpriteUnit, 画像のSpriteUnit|となる。
    #visibleメソッドの値がfalseのとき、選択が開始されていない時は描画されない。
    #_dst_:: 描画対象の画像インスタンス
    #返却値:: 自分自身を返す
    def render_to(dst, &block)
      return self unless @visible
      return self unless @now
      @now.base.each{|c|
        ((c.body_selected && c.selected) ?
          c.body_selected.render_to(dst, &block) :
          c.body.render_to(dst, &block)) if c.condition.call
      }
      return self
    end

    #===スプライトに変換した画像を表示する
    #すべてのパーツを貼り付けた、１枚のスプライトを返す
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #ただし、選択が開始されていなければnilを返す
    #返却値:: 生成したスプライト
    def to_sprite
      return nil unless @now
      rect = self.broad_rect
      sprite = Sprite.new(:size=>rect.to_a[2,2], :type=>:ac)
      Drawing.fill(sprite, [0,0,0])
      Bitmap.ck_to_ac!(sprite, [0,0,0])
      self.render_to(sprite){|sunit, dunit| sunit.x -= rect.x; sunit.y -= rect.y }
      yield sprite if block_given?
      return sprite
    end

    #===現在登録している選択肢の最大の大きさを矩形で取得する
    # 現在インスタンスが所持している選択肢全てから左上座標、右下座標を取得し、矩形の形式で返す
    # 但し、選択肢が一つも登録されていない時はRect(0,0,1,1)を返す
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      return Rect.new(0, 0, 1, 1) if @choices.length == 0
      xx = []
      yy = []
      @choices.each{|ch|
        ch.each{|cc|
          xx << cc.body.x
          yy << cc.body.y
          if cc.body_selected
            xx << cc.body_selected.x
            yy << cc.body_selected.y
          end
        }
      }
      min_x, max_x = xx.minmax
      min_y, max_y = yy.minmax
      return Rect.new(min_x, min_y, max_x-min_x+1, max_y-min_y+1)
    end

    #===現在登録している選択肢の大きさを矩形で取得する
    # 内容はbroad_rectメソッドの結果と同じ
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def rect
      return self.broad_rect
    end

    #===選択肢を左移動させる
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def left_choice
      return self unless @now
      @last_selected = @now
      @now.selected = false
      obj = @now.left
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    #===選択肢を右移動させる
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def right_choice
      return self unless @now
      @last_selected = @now
      @now.selected = false
      obj = @now.right
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    #===選択肢を上移動させる
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def up_choice
      return self unless @now
      @last_selected = @now
      @now.selected = false
      obj = @now.up
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    #===選択肢を下移動させる
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def down_choice
      return self unless @now
      @last_selected = @now
      @now.selected = false
      obj = @now.down
      update_choices(@now, obj)
      @now = obj
      @now.selected = true
      return self
    end

    #===選択肢のアニメーションを開始する
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def start
      return self unless @now
      @now.base.each{|c|
        if c.condition.call
          c.body.start
          c.body_selected.start if c.body != c.body_selected
        end
      }
      return self
    end

    #===選択肢のアニメーションを終了させる
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def stop
      return self unless @now
      @now.base.each{|c|
        if c.condition.call
          c.body.stop
          c.body_selected.stop if c.body != c.body_selected
        end
      }
      return self
    end

    #===選択肢のアニメーションの再生位置を最初に戻す
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def reset
      return self unless @now
      @now.base.each{|c|
        if c.condition.call
          c.body.reset
          c.body_selected.reset if c.body != c.body_selected
        end
      }
      return self
    end

    #===選択肢のアニメーションを更新させる
    # (手動で更新する必要があるときに呼び出す)
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def update_animation
      return self unless @now
      @now.base.each{|c|
        ((c.body_selected && c.selected) ?
         c.body_selected.update_animation :
         c.body.update_animation) if c.condition.call
      }
    end
  end
end
