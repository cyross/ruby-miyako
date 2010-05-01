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
  class ChoiceStruct < Struct
    include SpriteBase
    include Animation
    include Layout

    DIRECTION_LIST = [:up, :down, :left, :right, :base]

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)

    def initialize(*params)
      super(*params)
      init_layout
      @visible = true
      tsize = self.broad_rect.size
      set_layout_size(*tsize)
    end

    def update_layout_position #:nodoc:
      self[0].move_to!(*@layout.pos)
      self[1].move_to!(*@layout.pos) if self[1] && self[0] != self[1]
      self[2].move_to!(*@layout.pos) if self[2]
    end

    def process_sprites #:nodoc:
      yield(self[0])
      yield(self[1]) if self[1] && self[0] != self[1]
      yield(self[2]) if self[2]
    end

    def start
      return unless self[3].call
      process_sprites{|spr| spr.start }
    end

    def stop
      return unless self[3].call
      process_sprites{|spr| spr.stop }
    end

    def reset
      return unless self[3].call
      process_sprites{|spr| spr.reset }
    end

    def update_animation
      return unless self[3].call
      process_sprites{|spr| spr.update_animation }
    end

    def render_src #:nodoc:
      sprite = self[0]
      if self[4]
        sprite = self[1] if (self[5] && self[1])
      elsif self[2]
        sprite = self[2]
      end
      return sprite
    end

    def render
      return unless @visible
      return unless self[3].call
      render_src.render
    end

    def render_to(dst)
      return unless @visible
      return unless self[3].call
      render_src..render_to(dst)
    end

    #===レイアウト空間の大きさを更新する
    # 新たにスプライトを登録したときに、全体の大きさをレイアウト空間の大きさとして更新する
    #返却値:: 自分自身を返す
    def update_layout_size
      trect = self.broad_rect
      set_layout_size(*trect.size)
      self
    end

    #===選択肢の最大の大きさを矩形で取得する
    # 現在登録しているスプライトから最大の矩形(broad_rect)を求める
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      return self[0].rect if (self[1].nil? && self[2].nil?)
      list = [self[0]]
      list << self[1] if (self[1] && self[0] != self[1])
      list << self[2] if self[2]
      xx = []
      yy = []
      list.each{|ch|
        r = ch.rect
        xx << r.x
        yy << r.y
        xx << r.x + r.w
        yy << r.y + r.h
      }
      min_x, max_x = xx.minmax
      min_y, max_y = yy.minmax
      return Rect.new(min_x, min_y, max_x-min_x, max_y-min_y)
    end

    #===方向と移動先とを関連づける
    # _hash_:: (方向)=>(移動先)の関係を持つハッシュ
    # ハッシュキーは、:up,:down,:left,:right,:baseの5つ
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def arrow(hash)
      hash.each{|key, value|
        raise MiakoValueError, "illegal hash key!" unless DIRECTION_LIST.include?(key)
        self[key] = value
      }
      return self
    end
  end

  #==選択肢構造体
  # 選択肢を構成する要素の集合
  #
  # 複数のChoice構造体のインスタンスをまとめて、配列として構成されている
  # 選択肢を表示させるときは、body 自体の表示位置を変更させる必要がある
  #
  #_body_:: 選択肢を示す画像
  #_body_selected_:: 選択肢を示す画像(選択時)
  #_body_disable_:: 選択肢を示す画像(選択不可時)
  #_condition_:: 選択肢を表示できる条件を記述したブロック
  #_enable_:: 選択肢を選択できるときはtrue、不可の時はfalse
  #_selected_:: 選択肢が選択されているときはtrue、選択されていないときはfalse
  #_result_:: 選択した結果を示すインスタンス
  #_left_:: 左方向を選択したときに参照するChoice構造体のインスタンス
  #_up_:: 上方向を選択したときに参照するChoice構造体のインスタンス
  #_right_:: 右方向を選択したときに参照するChoice構造体のインスタンス
  #_down_:: 下方向を選択したときに参照するChoice構造体のインスタンス
  #_base_:: 構造体が要素となっているChoices
  #_attribute_:: 属性を示すハッシュ
  #_end_select_proc_:: この選択肢を選択したときに優先的に処理するブロック。
  #ブロックは1つの引数を取る(コマンド選択テキストボックス))。
  #デフォルトはnil(何もしない)
  #_name_:: 選択肢の名前。名前を明示的に指定しないときは、オブジェクトIDを文字列化したものが入る
  Choice = ChoiceStruct.new(:body, :body_selected, :body_disable,
                            :condition, :enable, :selected, :result,
                            :left, :up, :right, :down,
                            :base, :attribute, :end_select_proc, :name)

  #==選択肢を管理するクラス
  # 選択肢は、Shapeクラスから生成したスプライトもしくは画像で構成される
  class Choices < Delegator
    include SpriteBase
    include Animation
    include Layout

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
    attr_reader :choices #選択肢配列の集合
    attr_reader :name_to_choice #名前と選択肢を関連づけているハッシュ
    attr_reader :layout_spaces #選択肢の位置決めに使うレイアウト空間をハッシュで管理

    # インスタンスを生成する
    # 返却値:: 生成された Choices クラスのインスタンス
    def initialize
      init_layout
      @choices = []
      @name_to_choice = {}
      @layout_spaces = {}
      @now = nil
      @non_select = false
      @last_selected = nil
      @result = nil
      @visible = true
      @org_pos = Point.new(0,0)
      set_layout_size(1, 1)
    end

    def __getobj__
      @choices
    end

    def __setobj__(obj)
    end

    def initialize_copy(obj) #:nodoc:
      @choices = @choices.dup
      copy_layout
    end

    def update_layout_position #:nodoc:
      dx = @layout.pos[0] - rect[0]
      dy = @layout.pos[1] - rect[1]
      @choices.each{|ch| ch.each{|cc| cc.move!(dx, dy) } }
    end

    # 選択肢を作成する
    # Choice 構造体のインスタンスを作成する
    # 構造体には、引数bodyと、必ず true を返す条件ブロックが登録されている。残りは nil
    # name引数の省略時にはnilが渡され、内部で、オブジェクトIDを文字列化したものを入れる
    #_body_:: 選択肢を示す画像
    #_body_selected_:: 選択肢を示す画像(選択時)。デフォルトはnil
    #_selected_:: 生成時に選択されているときはtrue、そうでないときはfalseを設定する
    #_body_disable_:: 選択肢を示す画像(選択不可時)。デフォルトはnil
    #_enable_:: 生成時に選択可能なときはtrue、不可の時はfalseを設定する
    #_name_:: 選択肢の名前
    #返却値:: 生成された Choice構造体のインスタンス
    def Choices.create_choice(body, body_selected = nil, selected = false, body_disable = nil, enable = true, name = nil)
      choice = Choice.new(body, body_selected, body_disable, Proc.new{ true }, enable, selected,
                          nil, nil, nil, nil, nil, nil, {}, nil, nil)
      choice.left = choice
      choice.right = choice
      choice.up = choice
      choice.down = choice
      choice.name = name || choice.object_id.to_s
      return choice
    end

    #=== 選択肢を登録する
    # 選択肢集合(画面に一度に表示する選択肢群、Choice 構造体の配列)を選択肢リストに登録する
    # またこのとき、対象の選択肢をChoices#[]メソッドで参照できるようになる
    # _choices_:: 選択肢(Choice構造体)の配列
    # 返却値:: レシーバ
    def create_choices(choices)
      choices.each{|v|
        v.base = choices
        @name_to_choice[v.name] = v
      }
      @choices.push(choices)
      @last_selected = @choices[0][0] if (@choices.length == 1 && @last_selcted == nil)
      rect = self.broad_rect
      set_layout_size(*rect.size)
      return self
    end

    #=== 名前から選択肢を参照する
    #create_choicesメソッドで登録した選択肢を、名前からもとめる
    #登録されていない名前を渡したときはnilを返す
    #_name_:: 登録されているの名前。文字列
    #返却値:: 対応する選択肢インスタンス
    def regist_layout_space(name, layout_space)
      @layout_spaces[name] = layout_space
      layout_space.snap(self)
    end

    #=== 選択肢データを解放する
    def dispose
      @choices.each{|c| c.clear }
      @choices.clear
      @choices = []
    end

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
      raise MiyakoValueError, "Illegal choice position! [#{x}][#{y}]" if (x != nil && (x < 0 || x >= @choices.length || y < 0 || y >= @choices[x].length))
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

    #===選択肢が選択可能かどうかを問い合わせる
    #現在指している選択肢が選択可能か選択不可かを問い合わせる
    #返却値:: 選択可能ならtrue、選択不可ならfalseを返す
    def enable?
      return false if @non_select
      return false unless @now
      return @now.enable
    end

    #===選択肢を変更する
    #指定の位置の現在の選択状態を、選択状態にする
    #_x_:: x方向位置
    #_y_:: y方向位置
    #返却値:: 自分自身を返す
    def select(x, y)
      raise MiyakoError, "Not select yet!" unless @now
      raise MiyakoValueError, "Illegal choice position! [#{x}][#{y}]" if (x < 0 || x >= @choices.length || y < 0 || y >= @choices[x].length)
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
    def render
      return unless @visible
      return self unless @now
      @now.base.each{|c| c.render }
      return self
    end

    #===画像に描画を指示する
    #現在表示できる選択肢を、現在の状態で描画するよう指示する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る。
    #ブロックの引数は、|インスタンスのSpriteUnit, 画像のSpriteUnit|となる。
    #visibleメソッドの値がfalseのとき、選択が開始されていない時は描画されない。
    #_dst_:: 描画対象の画像インスタンス
    #返却値:: 自分自身を返す
    def render_to(dst)
      return self unless @visible
      return self unless @now
      @now.base.each{|c| c.render_to(dst) }
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

    #===レイアウト空間の大きさを更新する
    # 生成後、選択肢を追加した後の全体の大きさをレイアウト空間の大きさとして更新する
    # ただし、create_choicesめそっどを呼び出したときはこのメソッドを自動的に呼び出している
    #返却値:: 自分自身を返す
    def update_layout_size
      trect = self.broad_rect
      set_layout_size(*trect.size)
      self
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
          r = cc.broad_rect
          xx << r.x
          yy << r.y
          xx << r.x + r.w
          yy << r.y + r.h
        }
      }
      min_x, max_x = xx.minmax
      min_y, max_y = yy.minmax
      return Rect.new(min_x, min_y, max_x-min_x, max_y-min_y)
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
      @now.base.each{|c| c.start }
      return self
    end

    #===選択肢のアニメーションを終了させる
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def stop
      return self unless @now
      @now.base.each{|c| c.stop }
      return self
    end

    #===選択肢のアニメーションの再生位置を最初に戻す
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 自分自身を返す
    def reset
      return self unless @now
      @now.base.each{|c| c.reset }
      return self
    end

    #===選択肢のアニメーションを更新させる
    # (手動で更新する必要があるときに呼び出す)
    # 但し、まだ選択が開始されていなければ何もしない
    # 返却値:: 各選択肢のupdate_spriteメソッドを呼び出した結果を配列として返す
    # ただし、現在選択中の配列リストではないときは[false]を返す
    def update_animation
      return [false] unless @now
      @now.base.map{|c| c.update_animation }
    end

    #=== mixin されたインスタンスの部分矩形幅を取得する
    #返却値:: インスタンスの幅(デフォルトは0)
    def ow
      return self.size[0]
    end

    #=== mixin されたインスタンスの部分矩形高を取得する
    #返却値:: インスタンスの高さ(デフォルトは0)
    def oh
      return self.size[1]
    end
  end
end
