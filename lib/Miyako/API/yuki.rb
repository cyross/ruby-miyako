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

#=シナリオ言語Yuki実装モジュール
module Miyako
  #==Yuki本体クラス
  #Yukiの内容をオブジェクト化したクラス
  #Yukiのプロット処理を外部メソッドで管理可能
  #プロットは、引数を一つ（Yuki2クラスのインスタンス）を取ったメソッドもしくはブロック
  #として記述する。
  class Yuki
    #==キャンセルを示す構造体
    #コマンド選択がキャンセルされたときに生成される構造体
    Canceled = Struct.new(:dummy)

    #==Yuki実行管理クラス(外部クラスからの管理用)
    #実行中のYukiの管理を行うためのクラス
    #インスタンスは、Yuki#getmanager メソッドを呼ぶことで取得する
    class Manager
      #===インスタンスの作成
      #実際にインスタンスを生成するときは、Yuki#manager メソッドを呼ぶこと
      #_yuki_:: 管理対象の Yuki モジュールを mixin したクラスのインスタンス
      #_plot_proc_:: プロットメソッド・プロシージャインスタンス。デフォルトは nil
      #_with_update_input_:: Yuki#updateメソッドを呼び出した時、同時にYuki#update_plot_inputメソッドを呼び出すかどうかを示すフラグ。デフォルトはfalse
      def initialize(yuki, plot_proc, with_update_input = true)
        @with_update_input = with_update_input
        @yuki_instance = yuki
        @yuki_plot = plot_proc
      end

      #===プロット処理を開始する
      def start
        @yuki_instance.start_plot(@yuki_plot, @with_update_input)
      end

      #===入力更新処理を呼び出す
      def update_input
        @yuki_instance.update_plot_input
      end

      #===更新処理を呼び出す
      def update
        @yuki_instance.update
      end

      #===描画処理を呼び出す
      def render
        @yuki_instance.render
      end

      #===プロットの実行結果を返す
      #返却値:: 実行結果を示すインスタンス。デフォルトは、現在実行しているシーンのインスタンス
      def result
        @yuki_instance.result
      end

      #===コマンド選択がキャンセルされたときの結果を返す
      #返却値:: キャンセルされたときはtrue、されていないときはfalseを返す
      def canceled?
        return @yuki_instance.canceled?
      end
      
      #===プロット処理が実行中かの問い合わせメソッド
      #返却値:: 実行中の時は true を返す
      def executing?
        return @yuki_instance.executing?
      end

      #===コマンド選択中の問い合わせメソッド
      #返却値:: コマンド選択中の時はtrueを返す
      def selecting?
        return @yuki_instance.selecting?
      end

      #===Yuki#waitメソッドによる処理待ちの問い合わせメソッド
      #返却値:: 処理待ちの時はtrueを返す
      def waiting?
        return @yuki_instance.waiting?
      end

      #===メッセージ送り待ちの問い合わせメソッド
      #返却値:: メッセージ送り待ちの時はtrueを返す
      def pausing?
        return @yuki_instance.pausing?
      end
  
      #===Yukiオブジェクトが使用しているオブジェクトを解放する
      def dispose
        @yuki_instance.dispose
        @yuki_instance = nil
      end
    end
  
    #==コマンド構造体
    #_body_:: コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）
    #_body_selected_:: 選択時コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）(省略時は、bodyと同一)
    #_condition_:: 表示条件（ブロック）。評価の結果、trueのときのみ表示
    #_result_:: 選択結果（移動先シーンクラス名、シナリオ（メソッド）名他のオブジェクト）
    Command = Struct.new(:body, :body_selected, :condition, :result)
  
    #==コマンド構造体
    #_body_:: コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）
    #_body_selected_:: 選択時コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）(省略時は、bodyと同一)
    #_condition_:: 表示条件（ブロック）。評価の結果、trueのときのみ表示
    #_result_:: 選択結果（移動先シーンクラス名、シナリオ（メソッド）名他のオブジェクト）
    #_end_select_proc_:: この選択肢を選択したときに優先的に処理するブロック。
    #ブロックは1つの引数を取る(コマンド選択テキストボックス))。デフォルトはnil
    CommandEX = Struct.new(:body, :body_selected, :condition, :result, :end_select_proc)
    
    attr_accessor :update_inner, :update_text
    attr_reader :parts, :vars, :valign
    #release_checks:: ポーズ解除を問い合わせるブロックの配列。
    #callメソッドを持ち、true/falseを返すインスタンスを配列操作で追加・削除できる。
    #ok_checks:: コマンド選択決定を問い合わせるブロックの配列。
    #callメソッドを持ち、true/falseを返すインスタンスを配列操作で追加・削除できる。
    #cancel_checks:: コマンド選択解除（キャンセル）を問い合わせるブロックの配列。
    #callメソッドを持ち、true/falseを返すインスタンスを配列操作で追加・削除できる。
    attr_reader :release_checks, :ok_checks, :cancel_checks
    attr_reader :pre_pause, :pre_command, :pre_cancel, :post_pause, :post_command, :post_cancel
    #selecting_procs:: コマンド選択時に行うブロックの配列。
    #ブロックは4つの引数を取る必要がある。
    #(1)コマンド決定ボタンを押した？(true/false)
    #(2)キャンセルボタンを押した？(true/false)
    #(3)キーパッドの移動量を示す配列([dx,dy])
    #(4)マウスの位置を示す配列([x,y])
    #callメソッドを持つブロックが使用可能。
    attr_reader :selecting_procs
    
    #===Yukiを初期化する
    def initialize
      @yuki = { }
      @text_box = nil
      @command_box = nil

      @executing = false
      @with_update_input = true

      @pausing = false
      @selecting = false
      @waiting = false

      @pause_release = false
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
      @mouse_amount = nil

      @result = nil
      @plot_result = nil

      @update_inner = lambda{|yuki|}
      @update_text   = lambda{|yuki|}
      
      @parts = {}
      @visible = []
      @vars = {}

      @executing_fiber = nil
      
      @valign = :middle

      @release_checks_default = [lambda{ Input.pushed_all?(:btn1) }, lambda{ Input.click?(:left) } ]
      @release_checks = @release_checks_default.dup
      
      @ok_checks_default = [lambda{ Input.pushed_all?(:btn1) },
                            lambda{ self.commandbox.attach_any_command?(*Input.get_mouse_position) && Input.click?(:left) } ]
      @ok_checks = @ok_checks_default.dup

      @cancel_checks_default = [lambda{ Input.pushed_all?(:btn2) },
                                lambda{ Input.click?(:right) } ]
      @cancel_checks = @cancel_checks_default.dup

      @key_amount_proc   = lambda{ Input.pushed_amount }
      @mouse_amount_proc = lambda{ Input.mouse_cursor_inner? ? Input.get_mouse_position : nil }

      @pre_pause    = []
      @pre_command  = []
      @pre_cancel   = []
      @post_pause   = []
      @post_command = []
      @post_cancel  = []
      @selecting_procs = []
      
      @is_outer_height = self.method(:is_outer_height)
    end

    #===Yuki#showで表示指定した画像を描画する
    #描画順は、showメソッドで指定した順に描画される(先に指定した画像は後ろに表示される)
    #返却値:: 自分自身を返す
    def render
      @visible.each{|name|
        @parts[name].render if @parts.has_key?(name)
      }
      return self
    end

    #===オブジェクトを登録する
    #オブジェクトをパーツnameとして登録する。
    #Yuki::parts[name]で参照可能
    #:name:: パーツ名（シンボル）
    #:parts:: 登録対象のインスタンス
    #
    #返却値:: 自分自身を返す
    def regist_parts(name, parts)
      @parts[name] = parts
      return self
    end
  
    #===表示・描画対象のテキストボックスを選択する
    #:box:: テキストボックスのインスタンス
    #
    #返却値:: 自分自身を返す
    def select_textbox(box)
      @text_box = box
      return self
    end
  
    #===表示・描画対象のコマンドボックスを選択する
    #:box:: テキストボックスのインスタンス
    #
    #返却値:: 自分自身を返す
    def select_commandbox(box)
      @command_box = box
      return self
    end
  
    #===テキストボックスを取得する
    #テキストボックスが登録されていないときはnilを返す
    #返却値:: テキストボックスのインスタンス
    def textbox
      return @text_box
    end
  
    #===コマンドボックスを取得する
    #コマンドボックスが登録されていないときはnilを返す
    #返却値:: コマンドボックスのインスタンス
    def commandbox
      return @command_box
    end
  
    #===オブジェクトの登録を解除する
    #パーツnameとして登録されているオブジェクトを登録から解除する。
    #:name:: パーツ名（シンボル）
    #
    #返却値:: 自分自身を返す
    def remove_parts(name)
      @parts.delete(name)
      return self
    end
  
    #===パーツで指定したオブジェクトを先頭に表示する
    #描画時に、指定したパーツを描画する
    #すでにshowメソッドで表示指定している場合は、先頭に表示させる
    #:names:: パーツ名（シンボル）、複数指定可能(指定した順番に描画される)
    #返却値:: 自分自身を返す
    def show(*names)
      names.each{|name|
        @visible.delete(name)
        @visible << name
      }
      return self
    end
  
    #===パーツで指定したオブジェクトを隠蔽する
    #描画時に、指定したパーツを描画させないよう指定する
    #:names:: パーツ名（シンボル）、複数指定可能
    #返却値:: 自分自身を返す
    def hide(*names)
      names.each{|name| @visible.delete(name) }
      return self
    end
  
    #===パーツで指定したオブジェクトの処理を開始する
    #nameで指定したパーツが持つ処理を隠蔽する。
    #（但し、パーツで指定したオブジェクトがstartメソッドを持つことが条件）
    #:name:: パーツ名（シンボル）
    #返却値:: 自分自身を返す
    def start(name)
      @parts[name].start
      return self
    end
  
    #===パーツで指定したオブジェクトを再生する
    #nameで指定したパーツを再生する。
    #（但し、パーツで指定したオブジェクトがplayメソッドを持つことが条件）
    #:name:: パーツ名（シンボル）
    #返却値:: 自分自身を返す
    def play(name)
      @parts[name].play
      return self
    end
  
    #===パーツで指定したオブジェクトの処理を停止する
    #nameで指定したパーツが持つ処理を停止する。
    #（但し、パーツで指定したオブジェクトがstopメソッドを持つことが条件）
    #:name:: パーツ名（シンボル）
    #返却値:: 自分自身を返す
    def stop(name)
      @parts[name].stop
      return self
    end
  
    #===遷移図の処理が終了するまで待つ
    #nameで指定した遷移図の処理が終了するまで、プロットを停止する
    #:name:: 遷移図名（シンボル）
    #返却値:: 自分自身を返す
    def wait_by_finish(name)
      until @parts[name].finish?
        @update_inner.call(self)
      end
      return self
    end
  
    #===シーンのセットアップ時に実行する処理
    #
    #返却値:: あとで書く
    def setup
      @executing = false

      @pausing = false
      @selecting = false
      @waiting = false

      @pause_release = false
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
      @mouse_amount = nil

      @result = nil
      @plot_result = nil
    end
  
    #===プロット処理を実行する(明示的に呼び出す必要がある場合)
    #引数もしくはブロックで指定したプロット処理を非同期に実行する。
    #呼び出し可能なプロットは以下の3種類。(上から優先度が高い順）
    #
    #1)引数prot_proc(Procクラスのインスタンス)
    #
    #2)ブロック引数
    #
    #3)Yuki#plotメソッド
    #
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト
    #_with_update_input_:: Yuki#updateメソッドを呼び出した時、同時にYuki#update_plot_inputメソッドを呼び出すかどうかを示すフラグ。デフォルトはfalse
    #返却値:: あとで書く
    def start_plot(plot_proc = nil, with_update_input = true, &plot_block)
      raise MiyakoError, "Yuki Error! Textbox is not selected!" unless @text_box
      raise MiyakoError, "Yuki Error! Plot must have one parameter!" if plot_proc && plot_proc.arity != 1
      raise MiyakoError, "Yuki Error! Plot must have one parameter!" if plot_block && plot_block.arity != 1
      @with_update_input = with_update_input
      @executing_fiber = Fiber.new{ plot_facade(plot_proc, &plot_block) }
      @executing_fiber.resume
      return self
    end
  
    #===プロット処理を更新する
    #ポーズ中、コマンド選択中、 Yuki#wait メソッドによるウェイトの状態確認を行う。
    #プロット処理の実行確認は出来ない
    def update
      return unless @executing
      update_plot_input if @with_update_input
      pausing if @pausing
      selecting if @selecting
      waiting   if @waiting
      @pause_release = false
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
      @executing_fiber.resume
    end
  
    #===プロット用メソッドをYukiへ渡すためのインスタンスを作成する
    #プロット用に用意したメソッド（引数一つのメソッド）を、Yukiでの選択結果や移動先として利用できる
    #インスタンスに変換する
    #（指定のメソッドをMethodクラスのインスタンスに変換する）
    #_instance_:: 対象のメソッドが含まれているインスタンス(レシーバ)
    #_method_:: メソッド名(シンボルまたは文字列)
    #返却値:: 生成したインスタンスを返す
    def to_plot(instance, method)
      return instance.method(method.to_sym)
    end

    #===プロット処理に使用する入力情報を更新する
    #ポーズ中、コマンド選択中に使用する入力デバイスの押下状態を更新する
    #(但し、プロット処理の実行中にのみ更新する)
    #Yuki#update メソッドをそのまま使う場合は呼び出す必要がないが、 Yuki#exec_plot メソッドを呼び出す
    #プロット処理の場合は、メインスレッドから明示的に呼び出す必要がある
    #返却値:: nil を返す
    def update_plot_input
      return nil unless @executing
      if @pausing && @release_checks.inject(false){|r, c| r |= c.call }
        @pause_release = true
      elsif @selecting
        @select_ok = true if @ok_checks.inject(false){|r, c| r |= c.call }
        @select_cancel = true if @cancel_checks.inject(false){|r, c| r |= c.call }
        @select_amount = @key_amount_proc.call
        @mouse_amount = @mouse_amount_proc.call
      end
      return nil
    end

    #===プロット処理を外部クラスから管理するインスタンスを取得する
    #
    #1)引数prot_proc(Procクラスのインスタンス)
    #
    #2)ブロック引数
    #
    #3)Yuki#plotメソッド
    #
    #_plot_proc_:: プロットの実行部をインスタンス化したオブジェクト
    #_with_update_input_:: Yuki#updateメソッドを呼び出した時、同時にYuki#update_plot_inputメソッドを呼び出すかどうかを示すフラグ。デフォルトはfalse
    #_use_thread_:: スレッドを使ったポーズやタイマー待ちの監視を行うかを示すフラグ。デフォルトはfalse
    #返却値:: YukiManager クラスのインスタンス
    def manager(plot_proc = nil, with_update_input = true, &plot_block)
      return Manager.new(self, plot_proc || plot_block, with_update_input)
    end
  
    def plot_facade(plot_proc = nil, &plot_block) #:nodoc:
      @plot_result = nil
      @executing = true
      @plot_result = plot_proc ? plot_proc.call(self) : plot_block.call(self)
      @executing = false
    end
  
    #===プロット処理が実行中かどうかを確認する
    #返却値:: プロット処理実行中の時はtrueを返す
    def executing?
      return @executing
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
      raise MiyakoError, "Can't find block!" unless block_given?
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
      raise MiyakoError, "Can't find block!" unless block_given?
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
      raise MiyakoError, "Can't find block!" unless block_given?
      backup = [@cancel_checks, @pre_cancel, @post_cancel]
      @cancel_checks, @pre_cancel, @post_cancel = procs, pre_proc, post_proc
      yield
      @cancel_checks, @pre_cancel, @post_cancel = backup.pop(3)
      return self
    end

    #===プロットの処理結果を返す
    #プロット処理の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理が終了していないのに結果を得られるので注意！
    #返却値:: プロットの処理結果
    def result
      return @plot_result
    end
  
    #===プロット処理の結果を設定する
    #_ret_:: 設定する結果。デフォルトはnil
    #返却値:: 自分自身を返す
    def result=(ret = nil)
      @plot_result = ret
      return self
    end

    #===結果がシーンかどうかを問い合わせる
    #結果がシーン（シーンクラス名）のときはtrueを返す
    #対象の結果は、選択結果、プロット処理結果ともに有効
    #返却値:: 結果がシーンかどうか（true/false）
    def is_scene?(result)
      return (result.class == Class && result.include?(Story::Scene))
    end

    #===結果がシナリオかどうかを問い合わせる
    #結果がシナリオ（メソッド）のときはtrueを返す
    #対象の結果は、選択結果、プロット処理結果ともに有効
    #返却値:: 結果がシナリオかどうか（true/false）
    def is_scenario?(result)
      return (result.kind_of?(Proc) || result.kind_of?(Method))
    end

    #===コマンド選択がキャンセルされたときの結果を返す
    #返却値:: キャンセルされたときはtrue、されていないときはfalseを返す
    def canceled?
      return result == @cancel
    end
      
    #===ブロックを条件として設定する
    #メソッドをMethodクラスのインスタンスに変換する
    #_block_:: シナリオインスタンスに変換したいメソッド名(シンボル)
    #返却値:: シナリオインスタンスに変換したメソッド
    def condition(&block)
      return block
    end
    
    #===コマンド選択中の問い合わせメソッド
    #返却値:: コマンド選択中の時はtrueを返す
    def selecting?
      return @selecting
    end
    
    #===Yuki#waitメソッドによる処理待ちの問い合わせメソッド
    #返却値:: 処理待ちの時はtrueを返す
    def waiting?
      return @waiting
    end
    
    #===メッセージ送り待ちの問い合わせメソッド
    #返却値:: メッセージ送り待ちの時はtrueを返す
    def pausing?
      return @pausing
    end
  
    #===条件に合っていればポーズをかける
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
  
    #===テキストボックスに文字を表示する
    #_txt_:: 表示させるテキスト
    #返却値:: 自分自身を返す
    def text(txt)
      return self if txt.eql?(self)
      txt.chars{|ch|
        if /[\n\r]/.match(ch)
          next wait_by_cond(@is_outer_height)
        elsif @text_box.locate.x + @text_box.font.text_size(ch)[0] >= @text_box.textarea.w
          wait_by_cond(@is_outer_height)
        elsif /[\t\f]/.match(ch)
          next nil
        end
        @text_box.draw_text(ch)
        @update_text.call(self)
        Fiber.yield
      }
      return self
    end

    def is_outer_height #:nodoc:
      return @text_box.locate.y + @text_box.max_height >= @text_box.textarea.h
    end
    
    private :is_outer_height
    
    #===文字色を変更する
    #ブロック内で指定した文字列を、指定の色で描画する
    #_color_:: 文字色
    #返却値:: 自分自身を返す
    def color(color, &block)
      @text_box.color_during(Color.to_rgb(color)){ text block.call }
      return self
    end

    #===ブロック評価中、行中の表示位置を変更する
    #ブロックを評価している間だけ、デフォルトの縦の表示位置を変更する
    #変更できる値は、:top、:middle、:bottomの3種類。
    #ブロックを渡していないときはエラーを返す
    #_valign_:: 文字の縦の位置(top, middle, bottom)
    #返却値:: 自分自身を返す
    def valign_during(valign)
      raise MiyakoError, "Can't find block!" unless block_given?
      oalign, @valign = @valign, valign
      yield
      @valign = oalign
      return self
    end

    #===文字の大きさを変更する
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
    #ブロック内で指定した文字列を太文字で表示する
    #(使用すると文字の端が切れてしまう場合あり！)
    #返却値:: 自分自身を返す
    def bold(&block)
      @text_box.font_bold{ text block.call }
      return self
    end
  
    #===斜体文字を描画する
    #ブロック内で指定した文字列を斜体で表示する
    #(使用すると文字の端が切れてしまう場合あり！)
    #返却値:: 自分自身を返す
    def italic(&block)
      @text_box.font_italic{ text block.call }
      return self
    end
  
    #===下線付き文字を描画する
    #ブロック内で指定した文字列を下線付きで表示する
    #返却値:: 自分自身を返す
    def under_line(&block)
      @text_box.font_under_line{ text block.call }
      return self
    end

    #===改行を行う
    #返却値:: 自分自身を返す
    def cr
      @text_box.cr
      return self
    end

    #===テキストボックスの内容を消去する
    #返却値:: 自分自身を返す
    def clear 
      @text_box.clear
      return self
    end

    #===ポーズを行う
    #ポーズが行われると、ポーズ用のカーソルが表示される
    #所定のボタンを押すとポーズが解除され、カーソルが消える
    #解除後は、プロットの続きを処理する
    #引数無しのブロックを渡せば、ポーズ開始前に行いたい処理を施すことが出来る
    #(たとえば、一定時間後に自動的にポーズ解除する場合、そのタイマーを開始させるなど)
    #返却値:: 自分自身を返す
    def pause
      @pre_pause.each{|proc| proc.call}
      yield if block_given?
      @text_box.pause
      @pausing = true
      while @pausing
        @update_inner.call(self)
        Fiber.yield
      end
      @post_pause.each{|proc| proc.call}
      return self
    end

    def pausing #:nodoc:
      return unless @pause_release
      @text_box.release
      @pausing = false
      @pause_release = false
    end
  
    #===ポーズをかけて、テキストボックスの内容を消去する
    #ポーズをかけ、ポーズを解除するときにテキストボックスの内容を消去する
    #返却値:: 自分自身を返す
    def pause_and_clear
      return pause.clear
    end

    #===コマンドを表示する
    #表示対象のコマンド群をCommand構造体の配列で示す。
    #キャンセルのときの結果も指定可能（既定ではキャンセル不可状態）
    #body_selectedをnilにした場合は、bodyと同一となる
    #body_selectedを文字列を指定した場合は、文字色が赤色になることに注意
    #引数無しのブロックを渡せば、コマンド選択開始前に、決定判別・キャンセル判別に必要な前処理を施すことが出来る
    #_command_list_:: 表示するコマンド群。各要素はCommand構造体の配列
    #_cancel_to_:: キャンセルボタンを押したときの結果。デフォルトはnil（キャンセル無効）
    #_chain_block_:: コマンドの表示方法。TextBox#create_choices_chainメソッド参照
    #返却値:: 自分自身を返す
    def command(command_list, cancel_to = Canceled, &chain_block)
      raise MiyakoError, "Yuki Error! Commandbox is not selected!" unless @command_box
      @cancel = cancel_to

      choices = []
      command_list.each{|cm|
        if (cm[:condition] == nil || cm[:condition].call)
          cm_array = [cm[:body], cm[:body_selected], cm[:result]]
          methods = cm.methods
          cm_array << (methods.include?(:end_select_proc) ? cm[:end_select_proc] : nil)
          choices.push(cm_array)
        end
      }
      return self if choices.length == 0

      @pre_command.each{|proc| proc.call}
      @pre_cancel.each{|proc| proc.call}
      yield if block_given?
      @command_box.command(@command_box.create_choices_chain(choices, &chain_block))
      @result = nil
      @selecting = true
      while @selecting
        @update_inner.call(self)
        Fiber.yield
      end
      @post_cancel.each{|proc| proc.call}
      @post_command.each{|proc| proc.call}
      return self
    end

    def selecting #:nodoc:
      return unless @selecting
      return unless @command_box.selecting?
      @selecting_procs.each{|sp|
        sp.call(@select_ok, @select_cansel, @select_amount, @mouse_amount)
      }
      if @select_ok
        if @command_box.choices.end_select?
          @command_box.choices.call_end_select_proc(@command_box)
          return
        end
        @result = @command_box.result
        @command_box.finish_command
        @text_box.release
        @selecting = false
        reset_selecting
      elsif @select_cancel
        @result = @cancel
        @command_box.finish_command
        @text_box.release
        @selecting = false
        reset_selecting
      elsif @select_amount != [0,0]
        @command_box.move_cursor(*@select_amount)
        reset_selecting
      elsif @mouse_amount
        @command_box.attach_cursor(*@mouse_amount.to_a)
        reset_selecting
      end
    end
  
    def reset_selecting #:nodoc:
      @select_ok = false
      @select_cancel = false
      @select_amount = [0, 0]
    end

    #===コマンドの選択結果を返す
    #コマンド選択の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理・コマンド選択が終了していないのに結果を得られるので注意！
    #返却値:: コマンドの選択結果
    def select_result
      return @result
    end

    #===プロットの処理を待機する
    #指定の秒数（少数可）、プロットの処理を待機する。
    #_length_:: 待機する長さ。単位は秒。少数可。
    #返却値:: 自分自身を返す
    def wait(length)
      @waiting_timer = WaitCounter.new(length)
      @waiting_timer.start
      @waiting = true
      while @waiting
        @update_inner.call(self)
        Fiber.yield
      end
      return self
    end

    def waiting #:nodoc:
      return if @waiting_timer.waiting?
      @waiting = false
    end

    #===インスタンスで使用しているオブジェクトを解放する
    def dispose
      @update_inner = nil
      @update_text   = nil
      
      @executing_fiber = nil
      
      @parts.clear
      @parts = nil
      @visible.clear
      @visible = nil
      @vars.clear
      @vars = nil

      @is_outer_height = nil
    end
  end
end
