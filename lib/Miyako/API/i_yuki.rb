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

#=シナリオ言語Yuki実装モジュール
module Miyako

  #==InitiativeYukiクラスに対応したテンプレートモジュール
  module InitiativeYukiTemplate
    def render_inner(engine)
    end

    def render_to_inner(engine, dst)
    end

    def update_animation_inner(engine)
    end

    def update_inner(engine)
    end

    def text_inner(engine, ch)
    end

    def cr_inner(engine)
    end

    def clear_inner(engine)
    end

    def input_inner(engine)
    end

    def pausing_inner(engine)
    end

    def selecting_inner(engine)
    end

    def waiting_inner(engine)
    end
  end

  InitiativeScenarioEngineTemplate = InitiativeYukiTemplate

  #==主導権を持ったYuki本体クラス
  #Yukiの内容をオブジェクト化したクラス
  #Yukiのプロット処理を外部メソッドで管理可能
  #プロットは、引数を一つ（Yuki2クラスのインスタンス）を取ったメソッドもしくはブロック
  #として記述する。
  class InitiativeYuki
    include InitiativeYukiTemplate
    include SpriteBase
    include Animation

    ALL_TRUE = lambda{ true }

    #==キャンセルを示す構造体
    #コマンド選択がキャンセルされたときに生成される構造体
    Canceled = Struct.new(:dummy)

    #==コマンド構造体
    #_body_:: コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）
    #_body_selected_:: 選択時コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）(省略時は、bodyと同一)
    #_condition_:: 表示条件（ブロック）。評価の結果、trueのときのみ表示
    #_result_:: 選択結果（移動先シーンクラス名、シナリオ（メソッド）名他のオブジェクト）
    #_body_disable_:: 選択不可時コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）(省略時は、bodyと同一)
    #_enabe_:: コマンド選択の時はtrue、選択不可の時はfalseを設定
    Command = Struct.new(:body, :body_selected, :body_disable, :enable, :condition, :result)

    class Command
      # Command構造体をChoice構造体に変換する
      def to_choice(font=Font.sans_serif, size=16, color=Color[:white])
        org_font_color = font.color
        org_font_size = font.size

        font.color = color
        tmp = self[:body]
        body = tmp.method(:to_sprite).arity == 0 ? tmp.to_sprite : tmp.to_sprite(font)

        font.color = Color[:red]
        tmp = self[:body_selected]
        body_selected = tmp ? (tmp.method(:to_sprite).arity == 0 ? tmp.to_sprite : tmp.to_sprite(font)) : body

        font.color = Color[:dark_gray]
        tmp = self[:body_disable]
        body_disable= tmp ? (tmp.method(:to_sprite).arity == 0 ? tmp.to_sprite : tmp.to_sprite(font)) : body

        cond = self[:condition] || ALL_TRUE

        choice = Choice.new(body, body_selected, body_disable,
                            cond, self[:enable], false, self[:result],
                            nil, nil, nil, nil,
                            nil, {}, lambda{}, nil)
        choice.left = choice
        choice.right = choice
        choice.up = choice
        choice.down = choice
        choice.name = choice.__id__.to_s

        font.color = org_font_color
        font.size  = org_font_size

        choice
      end
    end

    #==コマンド構造体
    #_body_:: コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）
    #_body_selected_:: 選択時コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）(省略時は、bodyと同一)
    #_condition_:: 表示条件（ブロック）。評価の結果、trueのときのみ表示
    #_result_:: 選択結果（移動先シーンクラス名、シナリオ（メソッド）名他のオブジェクト）
    #_end_select_proc_:: この選択肢を選択したときに優先的に処理するブロック。
    #_body_disable_:: 選択不可時コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）(省略時は、bodyと同一)
    #ブロックは1つの引数を取る(コマンド選択テキストボックス))。デフォルトはnil
    #_enabe_:: コマンド選択の時はtrue、選択不可の時はfalseを設定
    CommandEX = Struct.new(:body, :body_selected, :condition, :body_disable, :enable, :result, :end_select_proc)

    class CommandEx
      # Command構造体をChoice構造体に変換する
      def to_choice(font=Font.sans_serif, size=16, color=Color[:white])
        org_font_color = font.color
        org_font_size = font.size

        font.color = color
        tmp = self[:body]
        body = tmp.method(:to_sprite).arity == 0 ? tmp.to_sprite : tmp.to_sprite(font)

        font.color = Color[:red]
        tmp = self[:body_selected]
        body_selected = tmp ? (tmp.method(:to_sprite).arity == 0 ? tmp.to_sprite : tmp.to_sprite(font)) : body

        font.color = Color[:dark_gray]
        tmp = self[:body_disable]
        body_disable= tmp ? (tmp.method(:to_sprite).arity == 0 ? tmp.to_sprite : tmp.to_sprite(font)) : body

        cond = self[:condition] || ALL_TRUE

        choice = Choice.new(body, body_selected, body_disable,
                            cond, self[:enable], false, self[:result],
                            nil, nil, nil, nil,
                            nil, {}, self[:end_select_proc], nil)
        choice.left = choice
        choice.right = choice
        choice.up = choice
        choice.down = choice
        choice.name = choice.__id__.to_s

        font.color = org_font_color
        font.size  = org_font_size

        choice
      end
    end

    #外部との共用変数を収めるところ
    @@common_use = {}

    def InitiativeYuki.[](key)
      @@common_use[key]
    end

    def InitiativeYuki.[]=(key, value)
      @@common_use[key] = value
      value
    end

    attr_reader :common_use
    attr_reader :visibles, :pre_visibles, :bgs, :base
    attr_reader :valign
    #release_checks:: ポーズ解除を問い合わせるブロックの配列。
    #callメソッドを持ち、true/falseを返すインスタンスを配列操作で追加・削除できる。
    #ok_checks:: コマンド選択決定を問い合わせるブロックの配列。
    #callメソッドを持ち、true/falseを返すインスタンスを配列操作で追加・削除できる。
    #cancel_checks:: コマンド選択解除（キャンセル）を問い合わせるブロックの配列。
    #callメソッドを持ち、true/falseを返すインスタンスを配列操作で追加・削除できる。
    attr_reader :release_checks, :ok_checks, :cancel_checks
    attr_reader :pre_pause, :pre_command, :pre_cancel, :post_pause, :post_command, :post_cancel, :on_disable
    #selecting_procs:: コマンド選択時に行うブロックの配列。
    #ブロックは4つの引数を取る必要がある。
    #(1)コマンド決定ボタンを押した？(true/false)
    #(2)キャンセルボタンを押した？(true/false)
    #(3)キーパッドの移動量を示す配列([dx,dy])
    #(4)マウスの位置を示す配列([x,y])
    #<<(2.1.15-追加、省略可能)>>
    #(5)現在指しているコマンドは選択可能?(true/false)
    #(6)現在指しているコマンドの結果
    #callメソッドを持つブロックが使用可能。
    attr_reader :selecting_procs

    #over_execを使用したシナリオエンジンのコールスタック
    #over_execするエンジンを基準に、一番大本のエンジンから順に積み込まれる
    #自分自身(self)は含まない
    attr_reader :engine_stack

    #===Yukiにメソッドを追加する(すべてのYukiインスタンスに適応)
    #ブロックを渡すことで、Yukiに新しいメソッドを追加できる。
    #追加したメソッドは、すべてのYukiインスタンスで利用可能となる。
    #コンテキストはYukiクラスのインスタンスとなるため、Yukiスクリプトと同じ感覚でメソッドを追加できる。
    #ただし、すでに追加したメソッド(もしくはYukiクラスですでに追加されているメソッド)を追加しようとすると例外が発生する
    #
    #_name_:: ブロックに渡す引数リスト
    #_block_:: メソッドとして実行させるブロック
    def InitiativeYuki.add_method(name, &block)
      name = name.to_sym
      raise MiyakoError, "Already added method! : #{name.to_s}" if self.methods.include?(name)
      define_method(name, block)
      return nil
    end

    #===Yukiにメソッドを追加する(指定のYukiインスタンスのみ適応)
    #ブロックを渡すことで、Yukiに新しいメソッドを追加できる。
    #追加したメソッドは、指定したYukiインスタンスのみ利用可能となる。
    #コンテキストはYukiクラスのインスタンスとなるため、Yukiスクリプトと同じ感覚でメソッドを追加できる。
    #ただし、すでに追加したメソッド(もしくはYukiクラスですでに追加されているメソッド)を追加しようとすると例外が発生する
    #
    #_name_:: ブロックに渡す引数リスト
    #_block_:: メソッドとして実行させるブロック
    def add_method(name, &block)
      name = name.to_sym
      raise MiyakoError, "Already added method! : #{name.to_s}" if self.methods.include?(name)
      self.define_singleton_method(name, block)
      return nil
    end

    #===Yukiを初期化する
    #
    #ブロック引数として、テキストボックスの変更などの処理をブロック内に記述することが出来る。
    #引数の数とブロック引数の数が違っていれば例外が発生する
    #_params_:: ブロックに渡す引数リスト(ただし、ブロックを渡しているときのみに有効)
    def initialize(*params, &proc)
      @base = nil
      @over_yuki = nil
      @under_yuki = nil
      @yuki = { }
      @text_box = nil
      @command_box = nil
      @text_box_all = nil
      @command_box_all = nil

      @exec_plot = nil

      @pausing = false
      @selecting = false
      @waiting = false

      @pause_release = false
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
      @cencel = nil
      @mouse_amount = nil

      @mouse_enable = true

      @select_mouse_enable = true
      @select_key_enable = false

      @result = nil
      @plot_result = nil

      @parts = {}
      @visibles = SpriteList.new
      @pre_visibles = SpriteList.new
      @bgs = SpriteList.new
      @vars = {}

      @text_methods = {:char => self.method(:text_by_char),
                      :string => self.method(:text_by_str) }
      @text_method_name = :char

      @valign = :middle

      @release_checks_default = [lambda{ Input.pushed_any?(:btn1, :spc) }, lambda{ @mouse_enable && Input.click?(:left) } ]
      @release_checks = @release_checks_default.dup

      @ok_checks_default = [lambda{ Input.pushed_any?(:btn1, :spc) },
                            lambda{ @mouse_enable && self.commandbox.attach_any_command?(*Input.get_mouse_position) && Input.click?(:left) } ]
      @ok_checks = @ok_checks_default.dup

      @cancel_checks_default = [lambda{ Input.pushed_any?(:btn2, :esc) },
                                lambda{ @mouse_enable && Input.click?(:right) } ]
      @cancel_checks = @cancel_checks_default.dup

      @key_amount_proc   = lambda{ Input.pushed_amount }
      @mouse_amount_proc = lambda{ Input.mouse_cursor_inner? ? Input.get_mouse_position : nil }

      @pre_pause    = []
      @pre_command  = []
      @pre_cancel   = []
      @post_pause   = []
      @post_command = []
      @post_cancel  = []
      @on_disable   = []
      @selecting_procs = []

      @is_outer_height = self.method(:is_outer_height)

      @now_page = nil
      @first_page = nil

      @engine_stack = []

      @common_use = {}

      raise MiyakoProcError, "Argument count is not same block parameter count!" if proc && proc.arity.abs != params.length
      instance_exec(*params, &proc) if block_given?
    end

    def initialize_copy(obj) #:nodoc:
      raise MiyakoCopyError.not_copy("Yuki")
    end

    #===エンジンスタックを生成する
    #base:: over_exec呼び出し元のエンジン
    def create_engine_stack(base)
      return unless @engine_stack.empty?
      @engine_stack.push(*base.engine_stack, base)
    end

    #===マウスでの制御を可能にする
    #ゲームパッド・キーボードでのコマンド・ポーズ制御を行えるが、
    #それに加えて、マウスでもゲームパッド・キーボードでの制御が行える
    #Yukiクラスインスタンス生成時はマウス利用可能
    #返却値:: 自分自身を返す
    def enable_mouse
      @mouse_enable = true
      return self
    end

    #===マウスでの制御を不可にする
    #ゲームパッド・キーボードでのコマンド・ポーズ制御を行えるが、
    #マウスでの利用を制限する
    #Yukiクラスインスタンス生成時はマウス利用可能
    #返却値:: 自分自身を返す
    def disable_mouse
      @mouse_enable = false
      return self
    end

    #===マウスでの制御を可・不可を問い合わせる
    #マウスを利用できるときはtrue、利用できないときはfalseを返す
    #返却値:: true/false
    def mouse_enable?
      @mouse_enable
    end

    def render_all
      self.bgs.render
      self.visibles.render
      self.textbox_all.render
      self.commandbox_all.render unless self.box_shared?
      self.pre_visibles.render
    end

    def start_all
      self.bgs.start
      self.visibles.start
      self.textbox_all.start
      self.commandbox_all.start unless self.box_shared?
      self.pre_visibles.start
    end

    def stop_all
      self.bgs.stop
      self.visibles.stop
      self.textbox_all.stop
      self.commandbox_all.stop unless self.box_shared?
      self.pre_visibles.stop
    end

    def reset_all
      self.bgs.reset
      self.visibles.reset
      self.textbox_all.reset
      self.commandbox_all.reset unless self.box_shared?
      self.pre_visibles.reset
    end

    def animation_all
      self.bgs.update_animation
      self.visibles.update_animation
      self.textbox_all.update_animation
      self.commandbox_all.update_animation unless self.box_shared?
      self.pre_visibles.update_animation
    end

    #===Yuki#showで表示指定した画像を描画する
    #描画順は、showメソッドで指定した順に描画される(先に指定した画像は後ろに表示される)
    #なお、visibleの値がfalseの時は描画されない。
    #返却値:: 自分自身を返す
    def render
      return @base.render_inner(self) if @base
      return self
    end

    def render_to_all(dst)
      self.bgs.render_to(dst)
      self.visibles.render_to(dst)
      self.textbox_all.render_to(dst)
      self.commandbox_all.render_to(dst) unless self.box_shared?
      self.pre_visibles.render_to(dst)
    end

    #===Yuki#showで表示指定した画像を描画する
    #描画順は、showメソッドで指定した順に描画される(先に指定した画像は後ろに表示される)
    #なお、visibleの値がfalseの時は描画されない。
    #返却値:: 自分自身を返す
    def render_to(dst)
      return @base.render_to_inner(self, dst) if @base
      return self
    end

    #===プロット処理を更新する
    #ポーズ中、コマンド選択中、 Yuki#wait メソッドによるウェイトの状態確認を行う。
    #プロット処理の実行確認は出来ない
    def update
      @base.update_inner(self) if @base
      @pause_release = false
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
      return nil
    end

    def update_animation_all
      self.bgs.update_animation
      self.visibles.update_animation
      self.textbox_all.update_animation
      self.commandbox_all.update_animation unless self.box_shared?
      self.pre_visibles.update_animation
    end

    #===Yuki#showで表示指定した画像のアニメーションを更新する
    #showメソッドで指定した画像のupdate_animationメソッドを呼び出す
    #返却値:: 描く画像のupdate_spriteメソッドを呼び出した結果を配列で返す
    def update_animation
      return @base.update_animation_inner(self) if @base
      return false
    end

    def [](key)
      @common_use[key] || @@common_use[key]
    end

    def []=(key, value)
      @common_use[key] = value
      value
    end

    #===変数を参照する
    #[[Yukiスクリプトとして利用可能]]
    #変数の管理オブジェクトを、ハッシュとして参照する。
    #変数名nameを指定して、インスタンスを参照できる。
    #未登録の変数はnilが変える。
    #(例)vars[:a] = 2 # 変数への代入
    #    vars[:b] = vars[:a] + 5
    #    show vars[:my_name]
    #
    #_name_:: パーツ名（シンボル）
    #
    #返却値:: 変数管理ハッシュ
    def vars
      @vars
    end

    #===変数を参照する
    #[[Yukiスクリプトとして利用可能]]
    #変数の管理オブジェクトを、ハッシュとして参照する。
    #変数名nameを指定して、インスタンスを参照できる。
    #未登録の変数はnilが変える。
    #(例)vars[:a] = 2 # 変数への代入
    #    vars[:b] = vars[:a] + 5
    #    vars_names => [:a, :b]
    #
    #_name_:: パーツ名（シンボル）
    #
    #返却値:: 変数管理ハッシュ
    def vars_names
      @vars.keys
    end

    #===パーツを参照する
    #[[Yukiスクリプトとして利用可能]]
    #パーツの管理オブジェクトを、ハッシュとして参照する。
    #パーツ名nameを指定して、インスタンスを参照できる
    #未登録のパーツはnilが返る
    #(例)parts[:chr1]
    #
    #返却値:: パーツ管理ハッシュ
    def parts
      @parts
    end

    #===パーツ名の一覧を参照する
    #[[Yukiスクリプトとして利用可能]]
    #パーツ管理オブジェクトに登録されているパーツ名の一覧を配列として返す。
    #順番は登録順。
    #まだ何も登録されていないときは空の配列が返る。
    #(例)regist_parts :chr1, hoge
    #    regist_parts :chr2, fuga
    #    parts_names # => [:chr1, :chr2]
    #
    #返却値:: パーツ管理ハッシュ
    def parts_names
      @parts.keys
    end

    #===現在描画対象のパーツ名のリストを取得する
    #[[Yukiスクリプトとして利用可能]]
    #現在描画しているパーツ名の配列を参照する。
    #実体のインスタンスは、partsメソッドで参照できるハッシュの値として格納されている。
    #Yuki#renderで描画する際、配列の先頭から順に、要素に対応するインスタンスを描画する(つまり、配列の後ろにある方が前に描画される
    #(例):[:a, :b, :c]の順に並んでいたら、:cが指すインスタンスが一番前に描画される。
    #
    #返却値:: 描画対象リスト
    def visibles_names
      @visibles.names
    end

    #===現在描画対象のパーツ名のリストを取得する
    #[[Yukiスクリプトとして利用可能]]
    #現在描画しているパーツ名の配列を参照する。
    #実体のインスタンスは、partsメソッドで参照できるハッシュの値として格納されている。
    #Yuki#renderで描画する際、配列の先頭から順に、要素に対応するインスタンスを描画する(つまり、配列の後ろにある方が前に描画される
    #(例):[:a, :b, :c]の順に並んでいたら、:cが指すインスタンスが一番前に描画される。
    #
    #返却値:: 描画対象リスト
    def pre_visibles_names
      @pre_visibles.names
    end

    #===現在描画対象のパーツ名のリストを取得する
    #[[Yukiスクリプトとして利用可能]]
    #現在描画しているパーツ名の配列を参照する。
    #実体のインスタンスは、partsメソッドで参照できるハッシュの値として格納されている。
    #Yuki#renderで描画する際、配列の先頭から順に、要素に対応するインスタンスを描画する(つまり、配列の後ろにある方が前に描画される
    #(例):[:a, :b, :c]の順に並んでいたら、:cが指すインスタンスが一番前に描画される。
    #
    #返却値:: 描画対象リスト
    def bgs_names
      @bgs.names
    end

    #===オブジェクトを登録する
    #[[Yukiスクリプトとして利用可能]]
    #オブジェクトをパーツnameとして登録する。
    #Yuki::parts[name]で参照可能
    #_name_:: パーツ名（シンボル）
    #_parts_:: 登録対象のインスタンス
    #
    #返却値:: 自分自身を返す
    def regist_parts(name, parts)
      @parts[name] = parts
      return self
    end

    #===表示・描画対象のテキストボックスを選択する
    #第2引数として、テキストボックス全体を渡せる(省略可能)
    #第1引数が、PartsやSpriteListの1部分のときに、第2引数を渡すことで、
    #テキストボックス全体を制御可能
    #第2引数を省略時は、全バージョンに引き続いて、テキストボックス本体のみを制御する
    #[[Yukiスクリプトとして利用可能]]
    #_box_:: テキストボックス本体
    #_box_all_:: テキストボックス全体
    #
    #返却値:: 自分自身を返す
    def select_textbox(box, box_all = nil)
      @text_box = box
      @text_box_all = box_all || box
      unless @command_box
        @command_box = @text_box
        @command_box_all = @text_box_all
      end
      return self
    end

    #===表示・描画対象のコマンドボックスを選択する
    #第2引数として、テキストボックス全体を渡せる(省略可能)
    #第1引数が、PartsやSpriteListの1部分のときに、第2引数を渡すことで、
    #テキストボックス全体を制御可能
    #第2引数を省略時は、全バージョンに引き続いて、テキストボックス本体のみを制御する
    #[[Yukiスクリプトとして利用可能]]
    #_box_:: テキストボックス本体
    #_box_all_:: テキストボックス全体
    #
    #返却値:: 自分自身を返す
    def select_commandbox(box, box_all = nil)
      @command_box = box
      @command_box_all = box_all || box
      return self
    end

    #===テキストボックスを取得する
    #[[Yukiスクリプトとして利用可能]]
    #テキストボックスが登録されていないときはnilを返す
    #返却値:: テキストボックス
    def textbox
      return @text_box
    end

    #===コマンドボックスを取得する
    #[[Yukiスクリプトとして利用可能]]
    #コマンドボックスが登録されていないときはnilを返す
    #返却値:: コマンドボックス
    def commandbox
      return @command_box
    end

    #===テキストボックス全体を取得する
    #[[Yukiスクリプトとして利用可能]]
    #テキストボックスが登録されていないときはnilを返す
    #返却値:: テキストボックス全体
    def textbox_all
      return @text_box_all
    end

    #===コマンドボックス全体を取得する
    #[[Yukiスクリプトとして利用可能]]
    #コマンドボックスが登録されていないときはnilを返す
    #返却値:: コマンドボックス全体
    def commandbox_all
      return @command_box_all
    end

    #===テキストボックスを描画可能にする
    #[[Yukiスクリプトとして利用可能]]
    #返却値:: レシーバ
    def show_textbox
      @text_box_all.show
      return self
    end

    #===コマンドボックスを描画可能にする
    #[[Yukiスクリプトとして利用可能]]
    #返却値:: レシーバ
    def show_commandbox
      @command_box_all.show
      return self
    end

    #===テキストボックスを描画不可能にする
    #[[Yukiスクリプトとして利用可能]]
    #返却値:: レシーバ
    def hide_textbox
      @text_box_all.hide
      return self
    end

    #===コマンドボックスを描画不可能にする
    #[[Yukiスクリプトとして利用可能]]
    #返却値:: レシーバ
    def hide_commandbox
      @command_box_all.hide
      return self
    end

    #===コマンドボックスとテキストボックスを共用しているか問い合わせる
    #[[Yukiスクリプトとして利用可能]]
    #テキストボックスとコマンドボックスを共用しているときはtrueを返す
    #共用していなければfalseを返す
    #返却値:: true/false
    def box_shared?
      @text_box_all.object_id == @command_box_all.object_id
    end

    #===オブジェクトの登録を解除する
    #[[Yukiスクリプトとして利用可能]]
    #パーツnameとして登録されているオブジェクトを登録から解除する。
    #_name_:: パーツ名（シンボル）
    #
    #返却値:: 自分自身を返す
    def remove_parts(name)
      @parts.delete(name)
      return self
    end

    #===パーツで指定したオブジェクトを先頭に表示する
    #[[Yukiスクリプトとして利用可能]]
    #描画時に、指定したパーツを描画する
    #すでにshowメソッドで表示指定している場合は、先頭に表示させる
    #_names_:: パーツ名（シンボル）、複数指定可能(指定した順番に描画される)
    #返却値:: 自分自身を返す
    def show(*names)
      if names.length == 0
        @visibles.each_value{|sprite| sprite.show}
        return self
      end
      names.each{|name|
        @visibles.add(name, @parts[name]) unless @visibles.include?(name)
        @visibles[name].show
      }
      return self
    end

    #===パーツで指定したオブジェクトを隠蔽する
    #[[Yukiスクリプトとして利用可能]]
    #描画時に、指定したパーツを描画させないよう指定する
    #_names_:: パーツ名（シンボル）、複数指定可能
    #返却値:: 自分自身を返す
    def hide(*names)
      if names.length == 0
        @visibles.each_value{|sprite| sprite.hide}
        return self
      end
      names.each{|name| @visibles[name].hide }
      return self
    end

    #===パーツで指定したオブジェクトを先頭に表示する
    #[[Yukiスクリプトとして利用可能]]
    #描画時に、指定したパーツを描画する
    #すでにshowメソッドで表示指定している場合は、先頭に表示させる
    #_names_:: パーツ名（シンボル）、複数指定可能(指定した順番に描画される)
    #返却値:: 自分自身を返す
    def pre_show(*names)
      if names.length == 0
        @pre_visibles.each_value{|sprite| sprite.show}
        return self
      end
      names.each{|name|
        @pre_visibles.add(name, @parts[name]) unless @pre_visibles.include?(name)
        @pre_visibles[name].show
      }
      return self
    end

    #===パーツで指定したオブジェクトを隠蔽する
    #[[Yukiスクリプトとして利用可能]]
    #描画時に、指定したパーツを描画させないよう指定する
    #_names_:: パーツ名（シンボル）、複数指定可能
    #返却値:: 自分自身を返す
    def pre_hide(*names)
      if names.length == 0
        @pre_visibles.each_value{|sprite| sprite.hide}
        return self
      end
      names.each{|name| @pre_visibles[name].hide }
      return self
    end

    #===パーツで指定した背景を表示する
    #[[Yukiスクリプトとして利用可能]]
    #描画時に、指定したパーツを描画する
    #すでにshowメソッドで表示指定している場合は、先頭に表示させる
    #_names_:: パーツ名（シンボル）、複数指定可能(指定した順番に描画される)
    #返却値:: 自分自身を返す
    def bg_show(*names)
      if names.length == 0
        @bgs.each_value{|sprite| sprite.show}
        return self
      end
      names.each{|name|
        @bgs.add(name, @parts[name]) unless @bgs.include?(name)
        @bgs[name].show
      }
      return self
    end

    #===パーツで指定した背景を隠蔽する
    #[[Yukiスクリプトとして利用可能]]
    #描画時に、指定したパーツを描画させないよう指定する
    #_names_:: パーツ名（シンボル）、複数指定可能
    #返却値:: 自分自身を返す
    def bg_hide(*names)
      if names.length == 0
        @bgs.each_value{|sprite| sprite.hide}
        return self
      end
      names.each{|name| @bgs[name].hide }
      return self
    end

    #===ファイル名で指定したスプライトを登録する
    #[[Yukiスクリプトとして利用可能]]
    #画面に表示するスプライトを登録する
    #すでにshowメソッドで表示指定している場合は、先頭に表示させる
    #_name_:: スプライト名(重複するときは上書き)
    #_filename_:: 読み込むファイル名
    #_pre_:: pre_visiblesに登録するときはtrue、visiblesに登録するときはfalseを渡す
    #        省略時はfalse
    #返却値:: 自分自身を返す
    def load_sprite(name, filename, pre=false)
      spr = Sprite.new(:file=>filename, :type=>:ac)
      @parts[name] = spr
      @parts[name].hide
      pre ? @pre_visibles.add(name, @parts[name]) :  @visibles.add(name, @parts[name])
      return self
    end

    #===背景を登録する
    #[[Yukiスクリプトとして利用可能]]
    #画面に表示する背景を登録する
    #すでにshowメソッドで表示指定している場合は、先頭に表示させる
    #_name_:: スプライト名(重複するときは上書き)
    #_filename_:: 読み込むファイル名
    #返却値:: 自分自身を返す
    def load_bg(name, filename)
      spr = Sprite.new(:file=>filename, :type=>:ac)
      @parts[name] = spr
      @parts[name].hide
      @bgs.add(name, @parts[name])
      return self
    end

    #===BGMを登録する
    #[[Yukiスクリプトとして利用可能]]
    #音声ファイルを読み込み、BGMとして登録する
    #登録したBGMはpartsメソッドを使って参照できる
    #_name_:: スプライト名(重複するときは上書き)
    #_filename_:: 読み込むファイル名
    #返却値:: 自分自身を返す
    def load_bgm(name, filename)
      @parts[name] = Audio::BGM.new(filename)
      return self
    end

    #===効果音を登録する
    #[[Yukiスクリプトとして利用可能]]
    #音声ファイルを読み込み、効果音として登録する
    #登録した効果音はpartsメソッドを使って参照できる
    #_name_:: スプライト名(重複するときは上書き)
    #_filename_:: 読み込むファイル名
    #返却値:: 自分自身を返す
    def load_se(name, filename)
      @parts[name] = Audio::SE.new(filename)
      return self
    end

    #===パーツで指定したオブジェクトの処理を開始する
    #[[Yukiスクリプトとして利用可能]]
    #nameで指定したパーツが持つ処理(例：アニメーション)を開始する。
    #（但し、パーツで指定したオブジェクトがstartメソッドを持つことが条件）
    #_name_:: パーツ名（シンボル）
    #返却値:: 自分自身を返す
    def start(name)
      @parts[name].start
      post_process
      return self
    end

    #===パーツで指定したオブジェクトを再生する
    #[[Yukiスクリプトとして利用可能]]
    #nameで指定したパーツを再生(例:BGM)する。
    #（但し、パーツで指定したオブジェクトがplayメソッドを持つことが条件）
    #_name_:: パーツ名（シンボル）
    #返却値:: 自分自身を返す
    def play(name)
      @parts[name].play
      post_process
      return self
    end

    #===パーツで指定したオブジェクトの処理を停止する
    #[[Yukiスクリプトとして利用可能]]
    #nameで指定したパーツが持つ処理を停止する。
    #（但し、パーツで指定したオブジェクトがstopメソッドを持つことが条件）
    #_name_:: パーツ名（シンボル）
    #返却値:: 自分自身を返す
    def stop(name)
      @parts[name].stop
      post_process
      return self
    end

    #===遷移図の処理が終了するまで待つ
    #[[Yukiスクリプトとして利用可能]]
    #nameで指定した遷移図の処理が終了するまで、プロットを停止する
    #_name_: 遷移図名（シンボル）
    #返却値:: 自分自身を返す
    def wait_by_finish(name, is_clear = true)
      until @parts[name].finish?
        process(is_clear)
      end
      return self
    end

    def process(is_clear = true)
      pre_process(is_clear)
      post_process
    end

    def pre_process(is_clear = true)
      Audio.update
      Input.update
      WaitCounter.update
      self.update_input
      self.update
      self.update_animation
      Screen.clear if is_clear
    end

    def post_process
      self.render
      WaitCounter.post_update
      Animation.update
      Screen.render
    end

    #===シーンのセットアップ時に実行する処理
    #
    #ブロック引数として、テキストボックスの変更などの処理をブロック内に記述することが出来る。
    #引数の数とブロック引数の数が違っていれば例外が発生する
    #_params_:: ブロックに渡す引数リスト(ブロックを渡しているときのみ)
    #返却値:: 自分自身を返す
    def setup(*params, &proc)
      @exec_plot = nil

      @pause_release = false
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
      @mouse_amount = nil

      @result = nil
      @plot_result = nil

      @now_page = nil
      @first_page = nil

      raise MiyakoProcError, "Argument count is not same block parameter count!" if proc && proc.arity.abs != params.length
      instance_exec(*params, &proc) if proc

      return self
    end

    #===実行するプロットと登録する
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト
    #返却値:: 自分自身を返す
    def select_plot(plot_proc)
      @exec_plot = plot_proc
      return self
    end

    #===プロット処理を実行する(明示的に呼び出す必要がある場合)
    #引数もしくはブロックで指定したプロット処理を非同期に実行する。
    #呼び出し可能なプロットは以下の3種類。(上から優先度が高い順）
    #プロットが見つからなければ例外が発生する
    #
    #1)引数prot_proc(Procクラスのインスタンス)
    #
    #2)引数として渡したブロック
    #
    #3)select_plotメソッドで登録したブロック(Procクラスのインスタンス)
    #
    #_base_:: プロット
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト。省略時はnil(paramsを指定するときは必ず設定すること)
    #_params_:: プロットに引き渡す引数リスト
    #返却値:: 自分自身を返す
    def start_plot(base, plot_proc = nil, *params, &plot_block)
      raise MiyakoValueError, "Yuki Error! Textbox is not selected!" unless @text_box
      raise MiyakoProcError, "Argument count is not same block parameter count!" if plot_proc && plot_proc.arity.abs != params.length
      raise MiyakoProcError, "Argument count is not same block parameter count!" if plot_block && plot_block.arity.abs != params.length
      raise MiyakoProcError, "Argument count is not same block parameter count!" if @exec_plot && @exec_plot.arity.abs != params.length
      @base = base
      plot_facade(plot_proc, *params, &plot_block)
      return self
    end

    def over_engine
      @over_yuki
    end

    def over_engine=(engine)
      @over_yuki = engine
      engine.under_engine = self
      engine.engine_stack.clear
      engine.create_engine_stack(self)
    end

    def under_engine
      @under_yuki
    end

    def under_engine=(engine)
      @under_yuki = engine
    end

    #===別のYukiエンジンを実行する
    #[[Yukiスクリプトとして利用可能]]
    #もう一つのYukiエンジンを実行させ、並行実行させることができる
    #ウインドウの上にウインドウを表示したりするときに、このメソッドを使う
    #renderメソッドで描画する際は、自分のインスタンスが描画した直後に描画される
    #自分自身を実行しようとするとMiyakoValueError例外が発生する
    #_yuki_:: 実行対象のYukiインスタンス(事前にsetupの呼び出しが必要)
    #_plot_:: プロットインスタンス。すでにsetupなどで登録しているときはnilを渡す
    #_params_:: プロット実行開始時に、プロットに渡す引数
    #返却値:: 自分自身を返す
    def over_exec(yuki = nil, base = nil, plot = nil, *params)
      raise MiyakoValueError, "This Yuki engine is same as self!" if yuki.eql?(self)
      self.over_engine = yuki if yuki
      @over_yuki.start_plot(base ? base : @over_yuki, plot, *params)
      yuki.engine_stack.clear if yuki
      return self
    end

    #===プロット用ブロックをYukiへ渡すためのインスタンスを作成する
    #プロット用に用意したブロック(ブロック引数無し)を、Yukiでの選択結果や移動先として利用できる
    #インスタンスに変換する
    #返却値:: ブロックをオブジェクトに変換したものを返す
    def to_plot(&plot)
      return plot
    end

    #===プロット処理に使用する入力情報を更新する
    #ポーズ中、コマンド選択中に使用する入力デバイスの押下状態を更新する
    #(但し、プロット処理の実行中にのみ更新する)
    #Yuki#update メソッドをそのまま使う場合は呼び出す必要がないが、 Yuki#exec_plot メソッドを呼び出す
    #プロット処理の場合は、メインスレッドから明示的に呼び出す必要がある
    #返却値:: nil を返す
    def update_input
      @base.input_inner(self) if @base
      return nil
    end

    def plot_facade(plot_proc = nil, *params, &plot_block) #:nodoc:
      @plot_result = nil
      exec_plot = @exec_plot
      @plot_result = plot_proc ? self.instance_exec(*params, &plot_proc) :
                     block_given? ? self.instance_exec(*params, &plot_block) :
                     exec_plot ? self.instance_exec(*params, &exec_plot) :
                     raise(MiyakoProcError, "Cannot find plot!")
    end

    #===プロット処理中に別のプロットを呼び出す
    #呼び出し可能なプロットは以下の2種類。(上から優先度が高い順）
    #
    #1)引数prot_proc(Procクラスのインスタンス)
    #
    #2)引数として渡したブロック
    #
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト
    #返却値:: プロットの実行結果を返す
    def call_plot(plot_proc = nil, &plot_block)
      return plot_proc ? self.instance_exec(&plot_proc) :
                         self.instance_exec(&plot_block)
    end

    #===プロット処理中に別のプロットを呼び出す
    #呼び出し可能なプロットは以下の2種類。(上から優先度が高い順）
    #
    #1)引数prot_proc(Procクラスのインスタンス)
    #
    #2)引数として渡したブロック
    #
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト
    #返却値:: プロットの実行結果を返す
    def call_plot_params(plot_proc, *params)
      return self.instance_exec(*params, &plot_proc)
    end

    #===プロット処理中に別のプロットを呼び出す
    #呼び出し可能なプロットは以下の2種類。(上から優先度が高い順）
    #
    #1)引数prot_proc(Procクラスのインスタンス)
    #
    #2)引数として渡したブロック
    #
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト
    #返却値:: プロットの実行結果を返す
    def call_plot_block(*params, &plot_block)
      return self.instance_exec(*params, &plot_block)
    end

    #===ポーズ解除問い合わせメソッド配列を初期状態に戻す
    #返却値:: 自分自身を返す
    def reset_release_checks
      @release_checks = @release_checks_default.dup
      return self
    end

    #===コマンド選択決定問い合わせメソッド配列を初期状態に戻す
    #返却値:: 自分自身を返す
    def reset_ok_checks
      @ok_checks = @ok_checks_default.dup
      return self
    end

    #===コマンド選択キャンセル問い合わせメソッド配列を初期状態に戻す
    #返却値:: 自分自身を返す
    def reset_cancel_checks
      @cancel_checks = @cancel_checks_default.dup
      return self
    end

    #===ポーズ前後処理メソッド配列を初期状態に戻す
    #pre_pause/post_pauseの処理を初期状態([])に戻す
    #返却値:: 自分自身を返す
    def reset_pre_post_release
      @pre_pause = []
      @post_pause = []
      return self
    end

    #===コマンド選択前後処理メソッド配列を初期状態に戻す
    #pre_command/post_commandの処理を初期状態([])に戻す
    #返却値:: 自分自身を返す
    def reset_pre_post_command
      @pre_command = []
      @post_command = []
      return self
    end

    #===コマンド選択キャンセル前後処理メソッド配列を初期状態に戻す
    #pre_cancel/post_cancelの処理を初期状態([])に戻す
    #返却値:: 自分自身を返す
    def reset_pre_post_cancel
      @pre_acncel = []
      @post_cancel = []
      return self
    end

    #===ブロック評価中、ポーズ解除問い合わせメソッド配列を置き換える
    #同時に、ポーズ時処理(Yuki#pre_pause)、ポーズ解除時処理(Yuki#post_pause)を引数で設定できる。
    #ブロックの評価が終われば、メソッド配列・ポーズ時処理・ポーズ解除時処理を元に戻す
    #procs:: 置き換えるメソッド配列(callメソッドを持ち、true/falseを返すメソッドの配列)
    #pre_proc:: ポーズ開始時に実行させるProc(デフォルトは[](何もしない))
    #post_proc:: ポーズ解除時に実行させるProc(デフォルトは[](何もしない))
    #返却値:: 自分自身を返す
    def release_checks_during(procs, pre_procs = [], post_procs = [])
      raise MiyakoProcError, "Can't find block!" unless block_given?
      backup = [@release_checks, @pre_pause, @post_pause]
      @release_checks, @pre_pause, @post_pause = procs, pre_proc, post_proc
      yield
      @release_checks, @pre_pause, @post_pause = backup.pop(3)
      return self
    end

    #===ブロック評価中、コマンド選択決定問い合わせメソッド配列を置き換える
    #同時に、コマンド選択開始時処理(Yuki#pre_command)、コマンド選択終了時処理(Yuki#post_command)を引数で設定できる。
    #ブロックの評価が終われば、メソッド配列・コマンド選択開始時処理・コマンド選択終了時処理を元に戻す
    #procs:: 置き換えるメソッド配列(callメソッドを持ち、true/falseを返すメソッドの配列)
    #pre_proc:: コマンド選択開始時に実行させるProc(デフォルトは[](何もしない))
    #post_proc:: コマンド選択決定時に実行させるProc(デフォルトは[](何もしない))
    #返却値:: 自分自身を返す
    def ok_checks_during(procs, pre_procs = [], post_procs = [])
      raise MiyakoProcError, "Can't find block!" unless block_given?
      backup = [@ok_checks, @pre_command, @post_command]
      @ok_checks, @pre_command, @post_command = procs, pre_proc, post_proc
      yield
      @ok_checks, @pre_command, @post_command = backup.pop(3)
      return self
    end

    #===ブロック評価中、コマンド選択キャンセル問い合わせメソッド配列を置き換える
    #同時に、コマンド選択開始時処理(Yuki#pre_cancel)、コマンド選択終了時処理(Yuki#post_cancel)を引数で設定できる。
    #ブロックの評価が終われば、メソッド配列・コマンド選択開始時処理・コマンド選択終了時処理を元に戻す
    #procs:: 置き換えるメソッド配列(callメソッドを持ち、true/falseを返すメソッドの配列)
    #pre_proc:: コマンド選択開始時に実行させるProc(デフォルトは[](何もしない))
    #post_proc:: コマンド選択キャンセル時に実行させるProc(デフォルトは[](何もしない))
    #返却値:: 自分自身を返す
    def cancel_checks_during(procs, pre_procs = [], post_procs = [])
      raise MiyakoProcError, "Can't find block!" unless block_given?
      backup = [@cancel_checks, @pre_cancel, @post_cancel]
      @cancel_checks, @pre_cancel, @post_cancel = procs, pre_proc, post_proc
      yield
      @cancel_checks, @pre_cancel, @post_cancel = backup.pop(3)
      return self
    end

    #===プロットの処理結果を返す
    #[[Yukiスクリプトとして利用可能]]
    #プロット処理の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理が終了していないのに結果を得られるので注意！
    #返却値:: プロットの処理結果
    def result
      return @plot_result
    end

    #===プロット処理の結果を設定する
    #[[Yukiスクリプトとして利用可能]]
    #_ret_:: 設定する結果。デフォルトはnil
    #返却値:: 自分自身を返す
    def result=(ret = nil)
      @plot_result = ret
      return self
    end

    #===結果がシーンかどうかを問い合わせる
    #[[Yukiスクリプトとして利用可能]]
    #結果がシーン（シーンクラス名）のときはtrueを返す
    #対象の結果は、選択結果、プロット処理結果ともに有効
    #返却値:: 結果がシーンかどうか（true/false）
    def is_scene?(result)
      return (result.class == Class && result.include?(Story::Scene))
    end

    #===結果がシナリオかどうかを問い合わせる
    #[[Yukiスクリプトとして利用可能]]
    #結果がシナリオ（メソッド）のときはtrueを返す
    #対象の結果は、選択結果、プロット処理結果ともに有効
    #返却値:: 結果がシナリオかどうか（true/false）
    def is_scenario?(result)
      return (result.kind_of?(Proc) || result.kind_of?(Method))
    end

    #===コマンド選択がキャンセルされたときの結果を返す
    #[[Yukiスクリプトとして利用可能]]
    #返却値:: キャンセルされたときはtrue、されていないときはfalseを返す
    def canceled?
      return @result == @cancel
    end

    #===ブロックを条件として設定する
    #[[Yukiスクリプトとして利用可能]]
    #メソッドをMethodクラスのインスタンスに変換する
    #_block_:: シナリオインスタンスに変換したいメソッド名(シンボル)
    #返却値:: シナリオインスタンスに変換したメソッド
    def condition(&block)
      return block
    end

    #===条件に合っていればポーズをかける
    #[[Yukiスクリプトとして利用可能]]
    #引数で設定した条件（Proc,メソッドインスタンス,ブロック）を評価した結果、trueのときはポーズを行い、
    #condの値がnilで、ブロックが渡されていないときは何もしない
    #falseのときは改行してプロットの処理を継続する
    #_cond_:: 条件を示すオブジェクト（返却値はtrue/false）。デフォルトはnil（渡されたブロックを評価する）
    #返却値:: 自分自身を返す
    def wait_by_cond(cond = nil)
      return yield ? pause_and_clear : cr if block_given?
      return cond.call ? pause_and_clear : cr if cond
      return self
    end

    #===テキストボックスに文字を表示する方法を指定する
    #引数に、:charを渡すと１文字ごと、:stringを渡すと文字列ごとに表示される。それ以外を指定したときは例外が発生
    #ブロックを渡せば、ブロックの評価中のみ設定が有効になる。
    #ブロック評価終了後、呼び出し前の設定に戻る
    #_mode_:: テキストの表示方法。:charのときは文字ごと、:stringのときは文字列ごとに表示される。それ以外を指定したときは例外が発生
    #返却値:: 自分自身を返す
    def text_method(mode)
      raise MiyakoValueError, "undefined text_mode! #{mode}" unless [:char,:string].include?(mode)
      backup = @text_method_name
      @text_method_name = mode
      if block_given?
        yield
        @text_method_name = backup
      end
      return self
    end

    #===テキストボックスに文字を表示する
    #[[Yukiスクリプトとして利用可能]]
    #テキストボックスとして用意している画像に文字を描画する。
    #描画する単位(文字単位、文字列単位)によって、挙動が違う。
    #(文字単位の時)
    #Yuki#text_by_charメソッドと同じ挙動。
    #(文字列単位の時)
    #Yuki#text_by_strメソッドと同じ挙動。
    #デフォルトは文字単位。
    #引数txtの値は、内部で１文字ずつ分割され、１文字描画されるごとに、
    #update_textメソッドが呼び出され、続けてYuki#start_plotもしくはYuki#updateメソッド呼び出し直後に戻る
    #_txt_:: 表示させるテキスト
    #返却値:: 自分自身を返す
    def text(txt)
      return self if txt.eql?(self)
      return self if txt.empty?
      return @text_methods[@text_method_name].call(txt)
    end

    #===テキストボックスに文字を1文字ずつ表示する
    #[[Yukiスクリプトとして利用可能]]
    #引数txtの値は、内部で１文字ずつ分割され、１文字描画されるごとに、
    #update_textメソッドが呼び出され、続けてYuki#start_plotもしくはYuki#updateメソッド呼び出し直後に戻る
    #注意として、改行が文字列中にあれば改行、タブやフィードが文字列中にあれば、nilを返す。
    #_txt_:: 表示させるテキスト
    #返却値:: 自分自身を返す
    def text_by_char(txt)
      return self if txt.eql?(self)
      txt.chars{|ch|
        pre_process
        if /[\n\r]/.match(ch)
          next wait_by_cond(@is_outer_height)
        elsif @text_box.locate.x + @text_box.font.text_size(ch)[0] >= @text_box.textarea.w
          wait_by_cond(@is_outer_height)
        elsif /[\t\f]/.match(ch)
          next nil
        end
        @text_box.draw_text(ch)
        @base.text_inner(self, ch) if @base
        post_process
      }
      return self
    end

    #===テキストボックスに文字を表示する
    #[[Yukiスクリプトとして利用可能]]
    #文字列が描画されるごとに、update_textメソッドが呼び出され、
    #続けてYuki#start_plotもしくはYuki#updateメソッド呼び出し直後に戻る
    #注意として、改行が文字列中にあれば改行、タブやフィードが文字列中にあれば、nilを返す。
    #_txt_:: 表示させるテキスト
    #返却値:: 自分自身を返す
    def text_by_str(txt)
      return self if txt.eql?(self)
      use_cr = false
      until txt.empty? do
        pre_process
        if /[\n\r]/.match(txt)
          tmp = Regexp.last_match.pre_match
          txt = Regexp.last_match.post_match
          use_cr = true
        elsif @text_box.locate.x + @text_box.font.text_size(txt)[0] >= @text_box.textarea.w
          w = (@text_box.textarea.w - @text_box.locate.x) / @text_box.font.size
          tmp = txt.slice!(0,w)
          use_cr = true
        elsif /[\t\f]/.match(txt)
          post_process
          next nil
        else
          tmp = txt
          txt = ""
        end
        @text_box.draw_text(tmp)
        self.cr if use_cr
        @base.text_inner(self, tmp) if @base
        use_cr = false
        post_process
      end
      return self
    end

    def is_outer_height #:nodoc:
      return @text_box.locate.y + @text_box.max_height >= @text_box.textarea.h
    end

    private :is_outer_height

    #===文字色を変更する
    #[[Yukiスクリプトとして利用可能]]
    #ブロック内で指定した文字列を、指定の色で描画する
    #_color_:: 文字色
    #返却値:: 自分自身を返す
    def color(color, &block)
      @text_box.color_during(Color.to_rgb(color)){ text block.call }
      return self
    end

    #===ブロック評価中、行中の表示位置を変更する
    #[[Yukiスクリプトとして利用可能]]
    #ブロックを評価している間だけ、デフォルトの縦の表示位置を変更する
    #変更できる値は、:top、:middle、:bottomの3種類。
    #ブロックを渡していないときはエラーを返す
    #_valign_:: 文字の縦の位置(top, middle, bottom)
    #返却値:: 自分自身を返す
    def valign_during(valign)
      raise MiyakoProcError, "Can't find block!" unless block_given?
      oalign, @valign = @valign, valign
      yield
      @valign = oalign
      return self
    end

    #===文字の大きさを変更する
    #[[Yukiスクリプトとして利用可能]]
    #ブロック内で指定した文字列を、指定の大きさで描画する
    #_size_:: 文字の大きさ（整数）
    #_valign_:: 文字の縦の位置(top, middle, bottom)。デフォルトは:middle(Yuki#valign=,Yuki#valign_duringで変更可能)
    #返却値:: 自分自身を返す
    def size(size, valign = @valign, &block)
      @text_box.font_size_during(size){
        @text_box.margin_during(@text_box.margin_height(valign)){ text block.call }
      }
      return self
    end

    #===太文字を描画する
    #[[Yukiスクリプトとして利用可能]]
    #ブロック内で指定した文字列を太文字で表示する
    #(使用すると文字の端が切れてしまう場合あり！)
    #返却値:: 自分自身を返す
    def bold(&block)
      @text_box.font_bold{ text block.call }
      return self
    end

    #===斜体文字を描画する
    #[[Yukiスクリプトとして利用可能]]
    #ブロック内で指定した文字列を斜体で表示する
    #(使用すると文字の端が切れてしまう場合あり！)
    #返却値:: 自分自身を返す
    def italic(&block)
      @text_box.font_italic{ text block.call }
      return self
    end

    #===下線付き文字を描画する
    #[[Yukiスクリプトとして利用可能]]
    #ブロック内で指定した文字列を下線付きで表示する
    #返却値:: 自分自身を返す
    def under_line(&block)
      @text_box.font_under_line{ text block.call }
      return self
    end

    #===改行を行う
    #[[Yukiスクリプトとして利用可能]]
    #開業後にupdate_crテンプレートメソッドが１回呼ばれる
    #_tm_:: 改行回数。デフォルトは1
    #返却値:: 自分自身を返す
    def cr(tm = 1)
      tm.times{|n|
        @text_box.cr
        @base.cr_inner(self) if @base
      }
      return self
    end

    #===テキストボックスの内容を消去する
    #[[Yukiスクリプトとして利用可能]]
    #開業後にupdate_clearテンプレートメソッドが１回呼ばれる
    #返却値:: 自分自身を返す
    def clear
      @text_box.clear
      @base.clear_inner(self) if @base
      return self
    end

    #===ポーズを行う
    #[[Yukiスクリプトとして利用可能]]
    #ポーズが行われると、ポーズ用のカーソルが表示される
    #所定のボタンを押すとポーズが解除され、カーソルが消える
    #解除後は、プロットの続きを処理する
    #引数無しのブロックを渡せば、ポーズ開始前に行いたい処理を施すことが出来る
    #ポーズ中、update_innerメソッドを呼び出し、続けて、処理をYuki#startもしくはYuki#update呼び出し直後に戻す
    #Yuki#updateが呼び出されてもポーズ中の場合は、再び上記の処理を繰り返す
    #(たとえば、一定時間後に自動的にポーズ解除する場合、そのタイマーを開始させるなど)
    #返却値:: 自分自身を返す
    def pause
      @pre_pause.each{|proc| proc.call}
      yield if block_given?
      @text_box.pause
      pause_release = false
      until pause_release
        pre_process
        @base.pausing_inner(self) if @base
        pause_release = @release_checks.inject(false){|r, c| r |= c.call }
        post_process
      end
      @text_box.release
      @post_pause.each{|proc| proc.call}
      return self
    end

    #===ポーズをかけて、テキストボックスの内容を消去する
    #[[Yukiスクリプトとして利用可能]]
    #ポーズをかけ、ポーズを解除するときにテキストボックスの内容を消去する
    #返却値:: 自分自身を返す
    def pause_and_clear
      return pause.clear
    end

    def select_mouse_enable?
      @select_mouse_enable
    end

    def select_key_enable?
      @select_key_enable
    end

    #===コマンドを表示する
    #[[Yukiスクリプトとして利用可能]]
    #表示対象のコマンド群をCommand構造体の配列で示す。
    #キャンセルのときの結果も指定可能（既定ではキャンセル不可状態）
    #body_selectedをnilにした場合は、bodyと同一となる
    #body_selectedを文字列を指定した場合は、文字色が赤色になることに注意
    #引数無しのブロックを渡せば、コマンド選択開始前に、決定判別・キャンセル判別に必要な前処理を施すことが出来る
    #選択中、update_innerメソッドを呼び出し、続けて、処理をYuki#startもしくはYuki#update呼び出し直後に戻す
    #Yuki#updateが呼び出されても選択中の場合は、再び上記の処理を繰り返す
    #_command_list_:: 表示するコマンド群。各要素はCommand構造体/CommandEx構造体/Choicesクラスオブジェクトの配列
    #_cancel_to_:: キャンセルボタンを押したときの結果。デフォルトはnil（キャンセル無効）
    #_chain_block_:: コマンドの表示方法。TextBox#create_choices_chainメソッド参照
    #返却値:: 自分自身を返す
    def command(command_list, cancel_to = Miyako::InitiativeYuki::Canceled, &chain_block)
      raise MiyakoValueError, "Yuki Error! Commandbox is not selected!" unless @command_box
      @cancel = cancel_to

      if command_list.kind_of?(Choices)
        @pre_command.each{|proc| proc.call}
        @pre_cancel.each{|proc| proc.call}
        @command_box_all.show if @command_box_all.object_id != @text_box_all.object_id
        @command_box.command(command_list)
      else
        choices = []
        command_list.each{|cm|
          if (cm[:condition] == nil || cm[:condition].call)
            cm_array = [cm[:body], cm[:body_selected], cm[:body_disable], cm[:enable], cm[:result]]
            methods = cm.methods
            cm_array << (methods.include?(:end_select_proc) ? cm[:end_select_proc] : nil)
            choices.push(cm_array)
          end
        }
        return self if choices.length == 0

        @pre_command.each{|proc| proc.call}
        @pre_cancel.each{|proc| proc.call}
        @command_box_all.show if @command_box_all.object_id != @text_box_all.object_id
        @command_box.command(@command_box.create_choices_chain(choices, &chain_block))
      end

      @result = nil
      @select_mouse_enable = true
      @select_key_enable = false
      selecting = true
      reset_selecting
      while selecting
        pre_process
        @select_amount = @key_amount_proc.call
        @mouse_amount = @mouse_amount_proc.call
        if @select_amount != [0,0]
          @select_mouse_enable = false
          @select_key_enable = true
        elsif Input.mouse_dx != 0 and Input.mouse_dy != 0
          @select_mouse_enable = true
          @select_key_enable = false
        else
          @select_mouse_enable = false
          @select_key_enable = false
        end
        @select_ok = true if @ok_checks.inject(false){|r, c| r |= c.call }
        @select_cancel = true if @cancel && @cancel_checks.inject(false){|r, c| r |= c.call }
        @selecting_procs.each{|sp|
          case sp.arity
          when 6
            sp.call(@select_ok, @select_cansel,
              @select_amount, @mouse_amount,
              @command_box.enable_choice?, @command_box.result
            )
          else
            sp.call(@select_ok, @select_cansel,
              @select_amount, @mouse_amount
            )
          end
        }
        if @select_ok
          unless @command_box.enable_choice?
            @on_disable.each{|proc| proc.call}
            post_process
            next
          end
          @result = @command_box.result
          @command_box.finish_command
          @command_box_all.hide if @command_box_all.object_id != @text_box_all.object_id
          @text_box.release
          selecting = false
          reset_selecting
        elsif @select_cancel
          @result = @cancel
          @command_box.finish_command
          @command_box_all.hide if @command_box_all.object_id != @text_box_all.object_id
          @text_box.release
          selecting = false
          reset_selecting
        elsif @select_amount != [0,0] and @select_key_enable
          @command_box.move_cursor(*@select_amount)
          reset_selecting
        elsif @mouse_amount and @select_mouse_enable
          @command_box.attach_cursor(*@mouse_amount.to_a) if @mouse_enable
          reset_selecting
        elsif Input.mouse_cursor_inner?
          @command_box.attach_cursor(Input.mouse_x, Input.mouse_y) if @mouse_enable
        end
        @base.selecting_inner(self) if @base
        post_process
      end
      @post_cancel.each{|proc| proc.call}
      @post_command.each{|proc| proc.call}
      return self
    end

    def reset_selecting #:nodoc:
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
    end

    #===コマンドの選択結果を返す
    #[[Yukiスクリプトとして利用可能]]
    #コマンド選択の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理・コマンド選択が終了していないのに結果を得られるので注意！
    #返却値:: コマンドの選択結果
    def select_result
      return @result
    end

    #===プロットの処理を待機する
    #[[Yukiスクリプトとして利用可能]]
    #指定の秒数（少数可）、プロットの処理を待機する。
    #待機中、update_innerメソッドを呼び出し、続けて、処理をYuki#startもしくはYuki#update呼び出し直後に戻す
    #Yuki#updateが呼び出されても待機中の場合は、再び上記の処理を繰り返す
    #_length_:: 待機する長さ。単位は秒。少数可。
    #返却値:: 自分自身を返す
    def wait(length)
      @waiting_timer = WaitCounter.new(length)
      @waiting_timer.start
      waiting = true
      while waiting
        pre_process
        @base.waiting_inner(self) if @base
        waiting = @waiting_timer.waiting?
        post_process
      end
      return self
    end

    #===シナリオ上の括り(ページ)を実装する
    #[[Yukiスクリプトとして利用可能]]
    #シナリオ上、「このプロットの明示的な範囲」を示すために使用する(セーブ時の再現位置の指定など)
    #Yuki#select_first_pageメソッドで開始位置が指定されている場合、以下の処理を行う。
    #(1)select_first_pageメソッドで指定されたページから処理する。それまでのページは無視される
    #(2)開始ページを処理する前に、select_first_pageメソッドの内容をクリアする(nilに変更する)
    #このメソッドはブロックが必須。ブロックがないと例外が発生する。
    #_name_:: ページ名。select_first_pageメソッドは、この名前を検索する。また、now_pageメソッドの返却値でもある
    #_use_pause_::ページの処理が終了した後、必ずpauseメソッドを呼び出すかどうかのフラグ。デフォルトはtrue
    #返却値:: select_first_pageメソッドで指定されていないページのときはnil、指定されているページの場合は引数nameの値
    def page(name, use_pause = true)
      raise MiyakoProcError, "Yuki#page needs block!" unless block_given?
      return nil if (@first_page && name != @first_page)
      @first_page = nil
      @now_page = name
      yield
      pause if use_pause
      @now_page = nil
      return name
    end

    #===シナリオ上の現在のページを返す
    #[[Yukiスクリプトとして利用可能]]
    #呼び出し当時、シナリオ上、pageメソッドでくくられていない場合は、nilを返す
    #返却値:: ページ名
    def now_page
      return @now_page
    end

    #===プロット上の最初に実行するページを指定知る
    #[[Yukiスクリプトとして利用可能]]
    #但し、ページ名を指定しないときはnilを指定する。
    #_name_:: 最初に実行するページ名
    def select_first_page(name)
      @first_page = name
    end

    #===インスタンスで使用しているオブジェクトを解放する
    def dispose
      @parts.clear
      @parts = nil
      @visibles.clear
      @visibles = nil
      @vars.clear
      @vars = nil

      @is_outer_height = nil
    end
  end

  InitiativeScenarioEngine = InitiativeYuki
end
