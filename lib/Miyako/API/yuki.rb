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

require 'thread'

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
    Canseled = Struct.new(:dummy)

    #==Yuki実行管理クラス(外部クラスからの管理用)
    #実行中のYukiの管理を行うためのクラス
    #インスタンスは、Yuki#getmanager メソッドを呼ぶことで取得する
    class Manager
      #===インスタンスの作成
      #実際にインスタンスを生成するときは、Yuki#manager メソッドを呼ぶこと
      #_yuki_:: 管理対象の Yuki モジュールを mixin したクラスのインスタンス
      #_plot_proc_:: プロットメソッド・プロシージャインスタンス。デフォルトは nil
      #_with_update_input_:: Yuki#updateメソッドを呼び出した時、同時にYuki#update_plot_inputメソッドを呼び出すかどうかを示すフラグ。デフォルトはfalse
      #_use_thread_:: スレッドを使ったポーズやタイマー待ちの監視を行うかを示すフラグ。デフォルトはfalse
      def initialize(yuki, plot_proc, with_update_input = true, use_thread = false)
        @with_update_input = with_update_input
        @use_thread = use_thread
        @yuki_instance = yuki
        @yuki_plot = plot_proc
      end

      #===プロット処理を開始する
      def start
        @yuki_instance.start_plot(@yuki_plot, @with_update_input, @use_thread)
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
      def canseled?
        return @yuki_instance.canseled?
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

    attr_accessor :update_inner, :update_text
    attr_reader :parts, :diagrams, :vars
    
    #===Yukiを初期化する
    def initialize
      @yuki = { }
      @yuki[:text_box] = nil
      @yuki[:command_box] = nil

      @yuki[:btn] = {:ok => :btn1, :cansel => :btn2, :release => :btn1 }

      @yuki[:plot_thread] = nil

      @yuki[:exec_plot] = false
      @yuki[:with_update_input] = true

      @yuki[:pausing] = false
      @yuki[:selecting] = false
      @yuki[:waiting] = false

      @yuki[:pause_release] = false
      @yuki[:select_ok] = false
      @yuki[:select_cansel] = false
      @yuki[:select_amount] = [0, 0]

      @yuki[:result] = nil
      @yuki[:plot_result] = nil

      @update_inner = lambda{|yuki|}
      @update_text   = lambda{|yuki|}
      @mutex = Mutex.new
      
      @parts = {}
      @visible = []
      @diagrams = {}
      @vars = {}

      @is_outer_height = self.method(:is_outer_height)
    end

    #===Yuki#showで表示指定した画像を描画する
    #描画順は、showメソッドで指定した順に描画される(先に指定した画像は後ろに表示される)
    #返却値:: 自分自身を返す
    def render
      @visible.each{|name|
        @parts[name].render if @parts.has_key?(name)
        @diagrams[name].render if @diagrams.has_key?(name)
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
      @yuki[:text_box] = box
      return self
    end
  
    #===表示・描画対象のコマンドボックスを選択する
    #:box:: テキストボックスのインスタンス
    #
    #返却値:: 自分自身を返す
    def select_commandbox(box)
      @yuki[:command_box] = box
      return self
    end
  
    #===遷移図を登録する
    #遷移図をパーツnameとして登録する。
    #遷移図を登録すると、update_inputメソッドがYuki2::update_plotメソッドを呼び出した時に
    #自動的に呼び出される(renderメソッドは呼ばれないことに注意！)。
    #Yuki::diagrams[name]で参照可能
    #:name:: パーツ名（シンボル）
    #:diagram:: 登録対象の遷移図インスタンス
    #
    #返却値:: 自分自身を返す
    def regist_diagram(name, diagram)
      @diagrams[name] = diagram
      return self
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
  
    #===遷移図の登録を解除する
    #パーツnameとして登録されている遷移図を登録から解除する。
    #:name:: パーツ名（シンボル）
    #
    #返却値:: 自分自身を返す
    def remove_diagram(name)
      @diagrams.delete(@parts[name])
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
        Thread.pass unless Thread.current.eql?(Thread.main)
      end
      return self
    end
  
    #===各ボタンの設定リストを出力する
    #コマンド決定・キャンセル時に使用するボタンの一覧をシンボルのハッシュとして返す。ハッシュの内容は以下の通り
    #ハッシュキー:: 説明:: デフォルト
    #:release:: メッセージ待ちを終了するときに押すボタン:: :btn1
    #:ok:: コマンド選択で「決定」するときに押すボタン:: btn1
    #:cansel:: コマンド選択で「キャンセル」するときに押すボタン:: btn2
    #
    #返却値:: ボタンの設定リスト
    def button
      return @yuki[:btn]
    end
  
    #===シーンのセットアップ時に実行する処理
    #
    #返却値:: あとで書く
    def setup
      @yuki[:plot_result] = nil

      @yuki[:exec_plot] = false

      @yuki[:pausing] = false
      @yuki[:selecting] = false
      @yuki[:waiting] = false

      @yuki[:pause_release] = false
      @yuki[:select_ok] = false
      @yuki[:select_cansel] = false
      @yuki[:select_amount] = [0, 0]

      @yuki[:result] = nil
      @yuki[:plot_result] = nil
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
    #_use_thread_:: スレッドを使ったポーズやタイマー待ちの監視を行うかを示すフラグ。デフォルトはfalse
    #返却値:: あとで書く
    def start_plot(plot_proc = nil, with_update_input = true, use_thread = false, &plot_block)
      raise MiyakoError, "Yuki Error! Textbox is not selected!" unless @yuki[:text_box]
      raise MiyakoError, "Yuki Error! Plot must have one parameter!" if plot_proc && plot_proc.arity != 1
      raise MiyakoError, "Yuki Error! Plot must have one parameter!" if plot_block && plot_block.arity != 1
      @yuki[:text_box].exec{ plot_facade(plot_proc, &plot_block) }
      until @yuki[:exec_plot] do; end
      @yuki[:plot_thread] = Thread.new{ update_plot_thread } if use_thread
      @yuki[:with_update_input] = with_update_input
      return self
    end
  
    #===プロット処理を更新する
    #ポーズ中、コマンド選択中、 Yuki#wait メソッドによるウェイトの状態確認を行う。
    #プロット処理の実行確認は出来ない
    def update
      return unless @yuki[:exec_plot]
      update_plot_input if @yuki[:with_update_input]
      unless @yuki[:plot_thread]
        pausing if @yuki[:pausing]
        selecting if @yuki[:selecting]
        waiting   if @yuki[:waiting]
      end
      @diagrams.each_value{|dia|
        dia.update_input
        dia.update if dia.sync?
      }
      @mutex.lock
      @yuki[:pause_release] = false
      @yuki[:select_ok] = false
      @yuki[:select_cansel] = false
      @yuki[:select_amount] = [0, 0]
      @mutex.unlock
    end
  
    def update_plot_thread #:nodoc:
      while @yuki[:exec_plot]
        pausing if @yuki[:pausing]
        selecting if @yuki[:selecting]
        waiting   if @yuki[:waiting]
        Thread.pass
      end
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
      return nil unless @yuki[:exec_plot]
      if @yuki[:pausing] && Input.pushed_all?(@yuki[:btn][:ok])
        @yuki[:pause_release] = true
      elsif @yuki[:selecting]
        @yuki[:select_ok] = true if Input.pushed_all?(@yuki[:btn][:ok])
        @yuki[:select_cansel] = true if Input.pushed_all?(@yuki[:btn][:cansel])
        @yuki[:select_amount] = Input.pushed_amount
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
    def manager(plot_proc = nil, with_update_input = true, use_thread = false, &plot_block)
      return Manager.new(self, plot_proc || plot_block, with_update_input, use_thread)
    end
  
    def plot_facade(plot_proc = nil, &plot_block) #:nodoc:
      @mutex.lock
      @yuki[:plot_result] = nil
      @yuki[:exec_plot] = true
      @mutex.unlock
      @yuki[:plot_result] = plot_proc ? plot_proc.call(self) : plot_block.call(self)
      @diagrams.each_value{|dia| dia.stop }
      @mutex.lock
      @yuki[:exec_plot] = false
      if @yuki[:plot_thread]
        @yuki[:plot_thread].join
        @yuki[:plot_thread] = nil
      end
      @mutex.unlock
    end
  
    #===プロット処理が実行中かどうかを確認する
    #返却値:: プロット処理実行中の時はtrueを返す
    def executing?
      return @yuki[:exec_plot]
    end

    #===プロットの処理結果を返す
    #プロット処理の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理が終了していないのに結果を得られるので注意！
    #返却値:: プロットの処理結果
    def result
      return @yuki[:plot_result]
    end
  
    #===プロット処理の結果を設定する
    #_ret_:: 設定する結果。デフォルトはnil
    #返却値:: 自分自身を返す
    def result=(ret = nil)
      @yuki[:plot_result] = ret
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
    def canseled?
      return result == @yuki[:cansel]
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
      return @yuki[:selecting]
    end
    
    #===Yuki#waitメソッドによる処理待ちの問い合わせメソッド
    #返却値:: 処理待ちの時はtrueを返す
    def waiting?
      return @yuki[:waiting]
    end
    
    #===メッセージ送り待ちの問い合わせメソッド
    #返却値:: メッセージ送り待ちの時はtrueを返す
    def pausing?
      return @yuki[:pausing]
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
        elsif @yuki[:text_box].locate.x + @yuki[:text_box].font.text_size(ch)[0] >= @yuki[:text_box].textarea.w
          wait_by_cond(@is_outer_height)
        elsif /[\t\f]/.match(ch)
          next nil
        end
        @yuki[:text_box].draw_text(ch)
        @update_text.call(self)
      }
      return self
    end

    def is_outer_height #:nodoc:
      return @yuki[:text_box].locate.y + @yuki[:text_box].max_height >= @yuki[:text_box].textarea.h
    end
    
    private :is_outer_height
    
    #===文字色を変更する
    #ブロック内で指定した文字列を、指定の色で描画する
    #_color_:: 文字色
    #返却値:: 自分自身を返す
    def color(color, &block)
      @yuki[:text_box].color_during(Color.to_rgb(color)){ text block.call }
      return self
    end

    #===文字の大きさを変更する
    #ブロック内で指定した文字列を、指定の大きさで描画する
    #_size_:: 文字の大きさ（整数）
    #_valign_:: 文字の縦の位置(top, middle, bottom)。デフォルトは:middle
    #返却値:: 自分自身を返す
    def size(size, valign = :middle, &block)
      @yuki[:text_box].font_size(size){
        @yuki[:text_box].margin_during(@yuki[:text_box].margin_height(valign)){ text block.call }
      }
      return self
    end
  
    #===太文字を描画する
    #ブロック内で指定した文字列を太文字で表示する
    #(使用すると文字の端が切れてしまう場合あり！)
    #返却値:: 自分自身を返す
    def bold(&block)
      @yuki[:text_box].font_bold{ text block.call }
      return self
    end
  
    #===斜体文字を描画する
    #ブロック内で指定した文字列を斜体で表示する
    #(使用すると文字の端が切れてしまう場合あり！)
    #返却値:: 自分自身を返す
    def italic(&block)
      @yuki[:text_box].font_italic{ text block.call }
      return self
    end
  
    #===下線付き文字を描画する
    #ブロック内で指定した文字列を下線付きで表示する
    #返却値:: 自分自身を返す
    def under_line(&block)
      @yuki[:text_box].font_under_line{ text block.call }
      return self
    end

    #===改行を行う
    #返却値:: 自分自身を返す
    def cr
      @yuki[:text_box].cr
      return self
    end

    #===テキストボックスの内容を消去する
    #返却値:: 自分自身を返す
    def clear 
      @yuki[:text_box].clear
      return self
    end

    #===ポーズを行う
    #ポーズが行われると、ポーズ用のカーソルが表示される
    #所定のボタンを押すとポーズが解除され、カーソルが消える
    #解除後は、プロットの続きを処理する
    #返却値:: 自分自身を返す
    def pause
      @yuki[:text_box].pause
      @mutex.lock
      @yuki[:pausing] = true
      @mutex.unlock
      while @yuki[:pausing]
        @update_inner.call(self)
        Thread.pass unless Thread.current.eql?(Thread.main)
      end
      return self
    end

    def pausing #:nodoc:
      return unless @yuki[:pause_release]
      @yuki[:text_box].release
      @mutex.lock
      @yuki[:pausing] = false
      @yuki[:pause_release] = false
      @mutex.unlock
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
    #_command_list_:: 表示するコマンド群。各要素はCommand構造体の配列
    #_cansel_to_:: キャンセルボタンを押したときの結果。デフォルトはnil（キャンセル無効）
    #_chain_block_:: コマンドの表示方法。あとで書く
    #返却値:: 自分自身を返す
    def command(command_list, cansel_to = Canseled, &chain_block)
      raise MiyakoError, "Yuki Error! Commandbox is not selected!" unless @yuki[:command_box]
      @yuki[:cansel] = cansel_to

      choices = []
      command_list.each{|cm| choices.push([cm[:body], cm[:body_selected], cm[:result]]) if (cm[:condition] == nil || cm[:condition].call) }
      return self if choices.length == 0

      @yuki[:command_box].command(@yuki[:command_box].create_choices_chain(choices, &chain_block))
      @mutex.lock
      @yuki[:result] = nil
      @yuki[:selecting] = true
      @mutex.unlock
      while @yuki[:selecting]
        @update_inner.call(self)
        Thread.pass unless Thread.current.eql?(Thread.main)
      end
      return self
    end

    def selecting #:nodoc:
      return unless @yuki[:selecting]
      exit if $miyako_debug_mode && Input.quit_or_escape?
      if @yuki[:command_box].selecting?
        if @yuki[:select_ok]
          @mutex.lock
          @yuki[:result] = @yuki[:command_box].result
          @mutex.unlock
          @yuki[:command_box].finish_command
          @yuki[:text_box].release
          @mutex.lock
          @yuki[:selecting] = false
          @mutex.unlock
          reset_selecting
        elsif @yuki[:select_cansel]
          @mutex.lock
          @yuki[:result] = @yuki[:cansel]
          @mutex.unlock
          @yuki[:command_box].finish_command
          @yuki[:text_box].release
          @mutex.lock
          @yuki[:selecting] = false
          @mutex.unlock
          reset_selecting
        elsif @yuki[:select_amount] != [0,0]
          @yuki[:command_box].move_cursor(*@yuki[:select_amount])
          reset_selecting
        end
      end
    end
  
    def reset_selecting #:nodoc:
      @mutex.lock
      @yuki[:select_ok] = false
      @yuki[:select_cansel] = false
      @yuki[:select_amount] = [0, 0]
      @mutex.unlock
    end

    #===コマンドの選択結果を返す
    #コマンド選択の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理・コマンド選択が終了していないのに結果を得られるので注意！
    #返却値:: コマンドの選択結果
    def select_result
      return @yuki[:result]
    end

    #===プロットの処理を待機する
    #指定の秒数（少数可）、プロットの処理を待機する。
    #_length_:: 待機する長さ。単位は秒。少数可。
    #返却値:: 自分自身を返す
    def wait(length)
      @waiting_timer = WaitCounter.new(length)
      @waiting_timer.start
      @mutex.lock
      @yuki[:waiting] = true
      @mutex.unlock
      while @yuki[:waiting]
        @update_inner.call(self)
        Thread.pass unless Thread.current.eql?(Thread.main)
      end
      return self
    end

    def waiting #:nodoc:
      return if @waiting_timer.waiting?
      @mutex.lock
      @yuki[:waiting] = false
      @mutex.unlock
    end

    #===インスタンスで使用しているオブジェクトを解放する
    def dispose
      @yuki.clear
      @yuki = nil

      @update_inner = nil
      @update_text   = nil
      @mutex = nil
      
      @parts.clear
      @parts = nil
      @visible.clear
      @visible = nil
      @diagrams.clear
      @diagrams = nil
      @vars.clear
      @vars = nil

      @is_outer_height = nil
    end
  
    private :button
  end
end
