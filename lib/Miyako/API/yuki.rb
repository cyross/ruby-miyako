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

require 'thread'

#=シナリオ言語Yuki実装モジュール
module Yuki
  #===Yukiのバージョン番号を返す
  #返却値:: Yukiのバージョン番号(文字列)
  def Yuki::version
    return "1.5"
  end

  #==Yuki例外クラス
  class YukiError < Exception
  end

  #==Yuki実行管理クラス(外部クラスからの管理用)
  #実行中のYukiの管理を行うためのクラス
  #インスタンスは、Yuki#getmanager メソッドを呼ぶことで取得する
  class YukiManager
    #===インスタンスの作成
    #--
    #実際にインスタンスを生成するときは、Yuki#manager メソッドを呼ぶこと
    #_yuki_:: 管理対象の Yuki モジュールを mixin したクラスのインスタンス
    #_now_scene_:: 実行中のシーンクラスのインスタンス
    #_plot_proc_:: プロットメソッド・プロシージャインスタンス。デフォルトは nil
    #++
    def initialize(yuki, now_scene, plot_proc) #:nodoc:
      @yuki_instance = yuki
      @now_scene = now_scene
      @yuki_plot = plot_proc
    end
    
    #===プロット処理を開始する
    def start
      @yuki_instance.exec_plot(@yuki_plot)
    end
    
    #===入力更新処理を呼び出す
    def update_input
      @yuki_instance.update_plot_input
    end

    #===プロットの実行結果を返す
    #返却値:: 実行結果を示すインスタンス。デフォルトは、現在実行しているシーンのインスタンス
    def result
      @yuki_instance.get_plot_result(@now_scene)
    end

    #===プロット処理が実行中かの問い合わせメソッド
    #返却値:: 実行中の時は true を返す
    def executing?
      return @yuki_instance.plot_executing?
    end
  end
  
  #==コマンド構造体
  Command = Struct.new(:body, :condition, :result)

  @@yuki = {}
  @@yuki[:pre_plot] = true
  @@yuki[:exec_plot] = false

  @@yuki[:pausing] = false
  @@yuki[:selecting] = false
  @@yuki[:waiting] = false
  
  @@yuki[:pause_release] = false
  @@yuki[:select_ok] = false
  @@yuki[:select_cansel] = false
  @@yuki[:select_amount] = [0, 0]

  @@yuki[:result] = nil
  @@yuki[:plot_result] = nil

  #===Yukiを初期化する
  #Yukiの実装部に、メッセージボックスとコマンドボックスを登録する
  #
  #各ボックスはともに、TextBoxクラスのインスタンス(もしくはそれを含むPartsクラスのインスタンス)
  #
  #メッセージボックスは、コマンドボックスとの兼用が可能
  #
  #(注)Yukiを使う際は、クラス変数@@yuki、インスタンス変数@yukiはすでに予約されているため、使用しないこと
  #
  #_box_:: テキストボックスを示すTextBoxクラスのインスタンスもしくはそのインスタンスを含むPartsクラスのインスタンス
  #_cbox_:: コマンドボックスを示すTextBoxクラスのインスタンスもしくはそのインスタンスを含むPartsクラスのインスタンス。デフォルトはnil(テキストボックスと共通)
  #_parts_name:: ボックスがPartsクラスインスタンスのときは、ボックスを示す部品名(シンボル)。デフォルトはnil(TextBoxクラスインスタンスを直接渡し)
  #
  #(注)parts_nameを使用する際は、box,cboxともにPartsクラスのインスタンスで、また、TextBoxクラスのインスタンスを同じシンボルで参照可能にする必要がある。
  #
  #(例1)boxとcboxともに別のテキストボックス、TextBoxクラスのインスタンス・・・　init_yuki(box, cbox)
  #(例2)boxがコマンドボックスと兼用、TextBoxクラスのインスタンス・・・　init_yuki(box)
  #(例3)boxとcboxともに別のテキストボックス、Partsクラスのインスタンス(シンボル：:box)・・・　init_yuki(box, cbox, :box)
  #(例4)boxがコマンドボックスと兼用、Partsクラスのインスタンス(シンボル：:box)・・・　init_yuki(box, nil, :box)
  def init_yuki(box, cbox = nil, parts_name = nil)
    @yuki = { }
    @yuki[:text_box] = parts_name ? box[parts_name] : box
    @yuki[:command_box] = parts_name ? (cbox[parts_name] || box[parts_name]) : (cbox || box)

    @yuki[:text_box_part] = box
    @yuki[:command_box_part] = cbox || box
    
    @yuki[:text_box].clear
    @yuki[:command_box].clear

    @yuki[:btn] = {:ok => :btn1, :cansel => :btn2, :release => :btn1 }
    
    @yuki[:mutex] = Mutex.new
    @yuki[:plot_thread] = nil
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
  #シーンのsetupメソッド内で必ず呼ぶこと
  #返却値:: あとで書く
  def setup_yuki
    @yuki[:plot_result] = nil

    @@yuki[:pre_plot] = true

    @@yuki[:exec_plot] = false

    @@yuki[:pausing] = false
    @@yuki[:selecting] = false
    @@yuki[:waiting] = false

    @@yuki[:pause_release] = false
    @@yuki[:select_ok] = false
    @@yuki[:select_cansel] = false
    @@yuki[:select_amount] = [0, 0]

    @@yuki[:result] = nil
    @@yuki[:plot_result] = nil
  end
  
  def update #:nodoc:
    if @@yuki[:pre_plot]
      @yuki[:text_box].exec{ plot_facade }
      until @@yuki[:exec_plot] do; end
      @@yuki[:pre_plot] = false
      return @now
    end
    return update_plot(@now)
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
  #返却値:: あとで書く
  def exec_plot(plot_proc = nil, &plot_block)
    @yuki[:text_box].exec{ plot_facade(plot_proc, &plot_block) }
    until @@yuki[:exec_plot] do; end
    @yuki[:plot_thread] = Thread.new{ update_plot_thread }
    return self
  end
  
  #===プロット処理を更新する
  #ポーズ中、コマンド選択中、 Yuki#wait メソッドによるウェイトの
  #状態確認を行う。プロット処理が終了していれば、返却値として移動先インスタンスを取得する
  #(処理中の時は、引数 default_return インスタンスを取得する)
  #_default_return_:: 更新時に移動先が指定されなかったときの移動先インスタンス(規定値はnil)
  #返却値:: あとで書く
  def update_plot(default_return = nil)
    ret = default_return
    if @@yuki[:exec_plot]
      update_plot_input
      pausing   if @@yuki[:pausing]
      selecting if @@yuki[:selecting]
      waiting   if @@yuki[:waiting]
      @yuki[:mutex].lock
      @@yuki[:pause_release] = false
      @@yuki[:select_ok] = false
      @@yuki[:select_cansel] = false
      @@yuki[:select_amount] = [0, 0]
      @yuki[:mutex].unlock
    else
      r = @@yuki[:plot_result]
      ret = (r.class == Class && r.include?(Story::Scene)) ? r : nil
    end
    return ret
  end
  
  def update_plot_thread #:nodoc:
    while @@yuki[:exec_plot]
      pausing if @@yuki[:pausing]
      selecting if @@yuki[:selecting]
      waiting   if @@yuki[:waiting]
      Thread.pass
    end
  end
  
  #===プロット処理の結果を得る
  #プロットが実行されたときの結果を得る
  #(処理中の時は、引数 default_return を取得する)
  #_default_return_:: 更新時に移動先が指定されなかったときの移動先インスタンス(規定値はnil)
  #返却値:: プロットの実行が終了している場合はその値、実行中の時は default_return の値をそのまま返す
  def get_plot_result(default_return = nil)
    r = @@yuki[:plot_result]
#    return (r.class == Class && r.include?(Story::Scene)) ? r : default_return
    return plot_executing? ? default_return : r
  end
  
  #===プロット処理に使用する入力情報を更新する
  #ポーズ中、コマンド選択中に使用する入力デバイスの押下状態を更新する
  #Yuki#update メソッドをそのまま使う場合は呼び出す必要がないが、 Yuki#exec_plot メソッドを呼び出す
  #プロット処理の場合は、メインスレッドから明示的に呼び出す必要がある
  #返却値:: nil を返す
  def update_plot_input
    if @@yuki[:pausing] && Miyako::Input.pushed_all?(@yuki[:btn][:ok])
      @@yuki[:pause_release] = true
    elsif @@yuki[:selecting]
      @@yuki[:select_ok] = true if Miyako::Input.pushed_all?(@yuki[:btn][:ok])
      @@yuki[:select_cansel] = true if @yuki[:cansel] && Miyako::Input.pushed_all?(@yuki[:btn][:cansel])
      @@yuki[:select_amount] = Input.pushed_amount
    end
    return nil
  end
  
  #===プロット処理が実行中かどうかを確認する
  #返却値:: プロット処理実行中の時はtrueを返す
  def plot_executing?
    return @@yuki[:exec_plot]
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
  #返却値:: YukiManager クラスのインスタンス
  def manager(plot_proc = nil, &plot_block)
    return Yuki::YukiManager.new(self, @now, plot_proc || plot_block)
  end
  
  #=== Yuki#update メソッドを実行している時に実行させたいコードを入れる
  #Yuki#update メソッド内部で呼び出すテンプレートメソッド
  #返却値:: なし
  def update_inner
  end

  #=== Yuki#text メソッドによる文字表示時に実行させたいコードを入れる
  #Yuki#text メソッド内部で呼び出すテンプレートメソッド
  #返却値:: なし
  def update_text
  end
  
  def plot_facade(plot_proc = nil, &plot_block) #:nodoc:
    @yuki[:mutex].lock
    @@yuki[:plot_result] = nil
    @@yuki[:exec_plot] = true
    @yuki[:mutex].unlock
    @yuki[:text_box_part].show
    @@yuki[:plot_result] = plot_proc ? plot_proc.call : (plot_block ? plot_block.call : plot)
    @yuki[:text_box_part].hide
    @yuki[:mutex].lock
    @@yuki[:exec_plot] = false
    @yuki[:plot_thread].join
    @yuki[:plot_thread] = nil
    @yuki[:mutex].unlock
  end

  #===プロットを示すテンプレートメソッド
  #このメソッド内にYukiのコードを記述すると、Yuki#update メソッドか Yuki#exec_plot
  #メソッドでプロット処理が始まる
  #返却値:: あとで書く
  def plot
  end

  #===メソッドをシナリオインスタンスに変換する
  #メソッドをMethodクラスのインスタンスに変換する
  #_method_:: シナリオインスタンスに変換したいメソッド名(シンボル)
  #返却値:: シナリオインスタンスに変換したメソッド
  def scenario(method)
    return self.method(method)
  end
  
  #===メソッドをシナリオインスタンスに変換する
  #メソッドをMethodクラスのインスタンスに変換する
  #_block_:: シナリオインスタンスに変換したいメソッド名(シンボル)
  #返却値:: シナリオインスタンスに変換したメソッド
  def condition(&block)
    return block
  end
  
  #===あとで書く
  #_cond_:: あとで書く
  #返却値:: あとで書く
  def wait_by_cond(cond)
    return cond ? pause_and_clear : cr
  end
  
  #===あとで書く
  #_txt_:: あとで書く
  #返却値:: あとで書く
  def text(txt)
    return self if txt.eql?(self)
    txt.split(//).each{|ch|
      if /[\n\r]/.match(ch)
        next wait_by_cond(@yuki[:text_box].locate.y + @yuki[:text_box].max_height >= @yuki[:text_box].textarea.h)
      elsif @yuki[:text_box].locate.x + @yuki[:text_box].font.text_size(ch)[0] >= @yuki[:text_box].textarea.w
        wait_by_cond(@yuki[:text_box].locate.y + @yuki[:text_box].max_height >= @yuki[:text_box].textarea.h)
      elsif /[\t\f]/.match(ch)
        next nil
      end
      @yuki[:text_box].draw_text(ch)
      update_text
    }
    return self
  end
  
  #===あとで書く
  #_color_:: あとで書く
  #返却値:: あとで書く
  def color(color, &block)
    tcolor = @yuki[:text_box].font.color
    @yuki[:text_box].font.color = Color.to_rgb(color)
    text block.call
    @yuki[:text_box].font.color = tcolor
    return self
  end

  #===あとで書く
  #_size_:: あとで書く
  #返却値:: あとで書く
  def size(size, &block)
    tsize = @yuki[:text_box].font.size
    @yuki[:text_box].font.size = size
    text block.call
    @yuki[:text_box].font.size = tsize
    return self
  end
  
  #===あとで書く
  #返却値:: あとで書く
  def bold(&block)
    tbold = @yuki[:text_box].font.bold?
    @yuki[:text_box].font.bold = true
    text block.call
    @yuki[:text_box].font.bold = tbold
    return self
  end
  
  #===あとで書く
  #返却値:: あとで書く
  def italic(&block)
    titalic = @yuki[:text_box].font.bold?
    @yuki[:text_box].font.italic = true
    text block.call
    @yuki[:text_box].font.italic = titalic
    return self
  end
  
  #===あとで書く
  #返却値:: あとで書く
  def under_line(&block)
    tunder_line = @yuki[:text_box].font.under_line?
    @yuki[:text_box].font.under_line = true
    text block.call
    @yuki[:text_box].font.under_line = tunder_line
    return self
  end

  #===あとで書く
  #返却値:: あとで書く
  def cr
    return @yuki[:text_box].cr
  end

  #===あとで書く
  #返却値:: あとで書く
  def clear 
    @yuki[:text_box].clear
    return self
  end

  #===あとで書く
  #返却値:: あとで書く
  def pause
    @yuki[:text_box].pause
    @yuki[:mutex].lock
    @@yuki[:pausing] = true
    @yuki[:mutex].unlock
    while @@yuki[:pausing]
      update_inner
      Thread.pass unless Thread.current.eql?(Thread.main)
    end
    return self
  end

  def pausing
    return unless @@yuki[:pause_release]
    @yuki[:text_box].release
    @yuki[:mutex].lock
    @@yuki[:pausing] = false
    @@yuki[:pause_release] = false
    @yuki[:mutex].unlock
  end
  
  #===あとで書く
  #返却値:: あとで書く
  def pause_and_clear
    return pause.clear
  end

  #===あとで書く
  #_command_list_:: あとで書く
  #_cansel_to_:: あとで書く
  #返却値:: あとで書く
  def command(command_list, cansel_to = nil, &chain_block)
    @yuki[:cansel] = cansel_to

    choices = []
    command_list.each{|cm| choices.push([cm[:body], cm[:result]]) if (cm[:condition] == nil || cm[:condition].call) }
    return self if choices.length == 0

    @yuki[:command_box].command(@yuki[:command_box].create_choices_chain(choices, &chain_block))
    @yuki[:command_box_part].show
    @yuki[:mutex].lock
    @@yuki[:result] = nil
    @@yuki[:selecting] = true
    @yuki[:mutex].unlock
    while @@yuki[:selecting]
      update_inner
      Thread.pass unless Thread.current.eql?(Thread.main)
    end
    return self
  end

  def selecting #:nodoc:
    return unless @@yuki[:selecting]
    exit if $miyako_debug_mode && Input.quit_or_escape?
    if @yuki[:command_box].selecting?
      if @@yuki[:select_ok]
        @yuki[:mutex].lock
        @@yuki[:result] = @yuki[:command_box].result
        @yuki[:mutex].unlock
        @yuki[:command_box].finish_command
        @yuki[:command_box_part].hide unless @yuki[:command_box].equal?(@yuki[:text_box])
        @yuki[:text_box].release
        @yuki[:mutex].lock
        @@yuki[:selecting] = false
        @yuki[:mutex].unlock
        reset_selecting
      elsif @@yuki[:select_cansel]
        @yuki[:mutex].lock
        @@yuki[:result] = @yuki[:cansel]
        @yuki[:mutex].unlock
        @yuki[:command_box].finish_command
        @yuki[:text_box].release
        @yuki[:mutex].lock
        @@yuki[:selecting] = false
        @yuki[:mutex].unlock
        reset_selecting
      elsif @@yuki[:select_amount] != [0,0]
        @yuki[:command_box].move_cursor(*@@yuki[:select_amount])
        reset_selecting
      end
    end
  end
  
  def reset_selecting #:nodoc:
    @yuki[:mutex].lock
    @@yuki[:select_ok] = false
    @@yuki[:select_cansel] = false
    @@yuki[:select_amount] = [0, 0]
    @yuki[:mutex].unlock
  end

  #===あとで書く
  #返却値:: あとで書く
  def result
    return @@yuki[:result]
  end

  #===あとで書く
  #返却値:: あとで書く
  def result_is_scene?
    return (@@yuki[:result].class == Class && @@yuki[:result].include?(Miyako::Story::Scene))
  end

  #===あとで書く
  #返却値:: あとで書く
  def result_is_scenario?
    return (@@yuki[:result].kind_of?(Proc) || @@yuki[:result].kind_of?(Method))
  end

  #===あとで書く
  #返却値:: あとで書く
  def wait(length)
    @waiting_timer = Miyako::WaitCounter.new(length)
    @waiting_timer.start
    @yuki[:mutex].lock
    @@yuki[:waiting] = true
    @yuki[:mutex].unlock
    while @@yuki[:waiting]
      update_inner
      Thread.pass unless Thread.current.eql?(Thread.main)
    end
    return self
  end

  def waiting #:nodoc:
    return if @waiting_timer.waiting?
    @yuki[:mutex].lock
    @@yuki[:waiting] = false
    @yuki[:mutex].unlock
  end
  
  private :init_yuki, :setup_yuki, :button, :update_inner, :update_text, :plot, :scenario, :condition, :wait_by_cond
  
  #==Yuki本体クラス
  #Yukiの内容をオブジェクト化したクラス
  #Yukiのプロット処理を外部メソッドで管理可能
  #プロットは、引数を一つ（Yuki2クラスのインスタンス）を取ったメソッドもしくはブロック
  #として記述する。
  class Yuki2
    #==Yuki実行管理クラス(外部クラスからの管理用)
    #実行中のYukiの管理を行うためのクラス
    #インスタンスは、Yuki#getmanager メソッドを呼ぶことで取得する
    class Manager
      #===インスタンスの作成
      #--
      #実際にインスタンスを生成するときは、Yuki#manager メソッドを呼ぶこと
      #_yuki_:: 管理対象の Yuki モジュールを mixin したクラスのインスタンス
      #_plot_proc_:: プロットメソッド・プロシージャインスタンス。デフォルトは nil
      #++
      def initialize(yuki, plot_proc) #:nodoc:
        @yuki_instance = yuki
        @yuki_plot = plot_proc
      end
    
      #===プロット処理を開始する
      def start
        @yuki_instance.exec_plot(@yuki_plot)
      end
    
      #===入力更新処理を呼び出す
      def update_input
        @yuki_instance.update_plot_input
      end

      #===更新処理を呼び出す
      def update
        @yuki_instance.update
      end

      #===プロットの実行結果を返す
      #返却値:: 実行結果を示すインスタンス。デフォルトは、現在実行しているシーンのインスタンス
      def result
        @yuki_instance.get_plot_result
      end

      #===プロット処理が実行中かの問い合わせメソッド
      #返却値:: 実行中の時は true を返す
      def executing?
        return @yuki_instance.plot_executing?
      end
    end
  
    #==コマンド構造体
    #_body_:: コマンドの名称（移動する、調べるなど、アイコンなどの画像も可）
    #_condition_:: 表示条件（ブロック）。評価の結果、trueのときのみ表示
    #_result_:: 選択結果（移動先シーンクラス名、シナリオ（メソッド）名他のオブジェクト）
    Command = Struct.new(:body, :condition, :result)

    attr_accessor :update_inner, :update_text
    attr_reader :parts, :vars
    
    #===Yukiを初期化する
    #Yukiの実装部に、メッセージボックスとコマンドボックスを登録する
    #
    #各ボックスはともに、TextBoxクラスのインスタンス(もしくはそれを含むPartsクラスのインスタンス)
    #
    #メッセージボックスは、コマンドボックスとの兼用が可能
    #
    #(注)Yukiを使う際は、クラス変数@@yuki、インスタンス変数@yukiはすでに予約されているため、使用しないこと
    #
    #_box_:: テキストボックスを示すTextBoxクラスのインスタンスもしくはそのインスタンスを含むPartsクラスのインスタンス
    #_cbox_:: コマンドボックスを示すTextBoxクラスのインスタンスもしくはそのインスタンスを含むPartsクラスのインスタンス。デフォルトはnil(テキストボックスと共通)
    #_parts_name_:: ボックスがPartsクラスインスタンスのときは、ボックスを示す部品名(シンボル)。デフォルトはnil(TextBoxクラスインスタンスを直接渡し)
    #
    #(注)parts_nameを使用する際は、box,cboxともにPartsクラスのインスタンスで、また、TextBoxクラスのインスタンスを同じシンボルで参照可能にする必要がある。
    #
    #(例1)boxとcboxともに別のテキストボックス、TextBoxクラスのインスタンス・・・　init_yuki(box, cbox)
    #(例2)boxがコマンドボックスと兼用、TextBoxクラスのインスタンス・・・　init_yuki(box)
    #(例3)boxとcboxともに別のテキストボックス、Partsクラスのインスタンス(シンボル：:box)・・・　init_yuki(box, cbox, :box)
    #(例4)boxがコマンドボックスと兼用、Partsクラスのインスタンス(シンボル：:box)・・・　init_yuki(box, nil, :box)
    def initialize(box, cbox = nil, parts_name = nil)
      @yuki = { }
      @yuki[:text_box] = parts_name ? box[parts_name] : box
      @yuki[:command_box] = parts_name ? (cbox[parts_name] || box[parts_name]) : (cbox || box)

      @yuki[:text_box_part] = box
      @yuki[:command_box_part] = cbox || box
    
      @yuki[:text_box].clear
      @yuki[:command_box].clear

      @yuki[:btn] = {:ok => :btn1, :cansel => :btn2, :release => :btn1 }
    
      @yuki[:plot_thread] = nil

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

      @update_inner = lambda{|yuki|}
      @update_text   = lambda{|yuki|}
      @mutex = Mutex.new
      
      @parts = {}
      @diagrams = []
      @vars = {}

      @is_outer_height = self.method(:is_outer_height)
    end

  #===オブジェクトを登録する
  #オブジェクトをパーツnameとして登録する。
  #Yuki2::parts[name]で参照可能
  #:name:: パーツ名（シンボル）
  #:parts:: 登録対象のインスタンス
  #
  #返却値:: 自分自身を返す
  def regist_parts(name, parts)
    @parts[name] = parts
    return self
  end
  
  #===遷移図を登録する
  #遷移図をパーツnameとして登録する。
  #Yuki2::parts[name]で参照可能（registerメソッドで登録する名称と重複しない様に注意！）
  #registerメソッドでも登録できるが、このときはupdate_input,renderメソッドが機能しない
  #遷移図を登録すると、update_input,renderの各メソッドがYuki2::update_plotメソッドを呼び出した時に
  #自動的に呼び出される。
  #:name:: パーツ名（シンボル）
  #:diagram:: 登録対象の遷移図インスタンス
  #
  #返却値:: 自分自身を返す
  def regist_diagram(name, diagram)
    @parts[name] = diagram
    @diagrams << diagram
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
    @parts.delete(name)
    return self
  end
  
  #===パーツで指定したオブジェクトを表示する
  #nameで指定したパーツを表示する。
  #（但し、パーツで指定したオブジェクトがshowメソッドを持つことが条件）
  #:name:: パーツ名（シンボル）
  #返却値:: 自分自身を返す
  def show(name)
    @parts[name].show
    return self
  end
  
  #===パーツで指定したオブジェクトを隠蔽する
  #nameで指定したパーツを隠蔽する。
  #（但し、パーツで指定したオブジェクトがhideメソッドを持つことが条件）
  #:name:: パーツ名（シンボル）
  #返却値:: 自分自身を返す
  def hide(name)
    @parts[name].hide
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
    #返却値:: あとで書く
    def exec_plot(plot_proc = nil, &plot_block)
      @yuki[:text_box].exec{ plot_facade(plot_proc, &plot_block) }
      until @yuki[:exec_plot] do; end
      @yuki[:plot_thread] = Thread.new{ update_plot_thread }
      return self
    end
  
    #===プロット処理を更新する
    #ポーズ中、コマンド選択中、 Yuki#wait メソッドによるウェイトの
    #状態確認を行う。プロット処理が終了していれば、返却値として移動先インスタンスを取得する
    #(処理中の時は、引数 default_return インスタンスを取得する)
    #_default_return_:: 更新時に移動先が指定されなかったときの移動先インスタンス(規定値はnil)
    #返却値:: あとで書く
    def update_plot(default_return = nil)
      ret = default_return
      if @yuki[:exec_plot]
        update_plot_input
        pausing   if @yuki[:pausing]
        selecting if @yuki[:selecting]
        waiting   if @yuki[:waiting]
        @diagrams.each{|dia| dia.update_input }
        @mutex.lock
        @yuki[:pause_release] = false
        @yuki[:select_ok] = false
        @yuki[:select_cansel] = false
        @yuki[:select_amount] = [0, 0]
        @mutex.unlock
        @diagrams.each{|dia| dia.render }
      else
        r = @yuki[:plot_result]
        ret = (r.class == Class && r.include?(Story::Scene)) ? r : nil
      end
      return ret
    end
  
    def update_plot_thread #:nodoc:
      while @yuki[:exec_plot]
        pausing if @yuki[:pausing]
        selecting if @yuki[:selecting]
        waiting   if @yuki[:waiting]
        Thread.pass
      end
    end
  
    #===プロット処理の結果を得る
    #プロットが実行されたときの結果を得る
    #(処理中の時は、引数 default_return を取得する)
    #_default_return_:: 更新時に移動先が指定されなかったときの移動先インスタンス(規定値はnil)
    #返却値:: プロットの実行が終了している場合はその値、実行中の時は default_return の値をそのまま返す
    def get_plot_result(default_return = nil)
      r = @yuki[:plot_result]
      return plot_executing? ? default_return : r
    end
  
    #===プロット処理の結果を設定する
    #_ret_:: 設定する結果。デフォルトはnil
    #返却値:: 自分自身を返す
    def result=(ret = nil)
      @yuki[:plot_result] = ret
      return self
    end
  
    #===プロット処理に使用する入力情報を更新する
    #ポーズ中、コマンド選択中に使用する入力デバイスの押下状態を更新する
    #Yuki#update メソッドをそのまま使う場合は呼び出す必要がないが、 Yuki#exec_plot メソッドを呼び出す
    #プロット処理の場合は、メインスレッドから明示的に呼び出す必要がある
    #返却値:: nil を返す
    def update_plot_input
      if @yuki[:pausing] && Miyako::Input.pushed_all?(@yuki[:btn][:ok])
        @yuki[:pause_release] = true
      elsif @yuki[:selecting]
        @yuki[:select_ok] = true if Miyako::Input.pushed_all?(@yuki[:btn][:ok])
        @yuki[:select_cansel] = true if @yuki[:cansel] && Miyako::Input.pushed_all?(@yuki[:btn][:cansel])
        @yuki[:select_amount] = Input.pushed_amount
      end
      return nil
    end
  
    #===プロット処理が実行中かどうかを確認する
    #返却値:: プロット処理実行中の時はtrueを返す
    def plot_executing?
      return @yuki[:exec_plot]
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
    #返却値:: YukiManager クラスのインスタンス
    def manager(plot_proc = nil, &plot_block)
      return Manager.new(self, plot_proc || plot_block)
    end
  
  def plot_facade(plot_proc = nil, &plot_block) #:nodoc:
    @mutex.lock
    @yuki[:plot_result] = nil
    @yuki[:exec_plot] = true
    @mutex.unlock
    @yuki[:text_box_part].show
    @yuki[:plot_result] = plot_proc ? plot_proc.call(self) : plot_block.call(self)
    @diagrams.each{|dia| dia.stop }
    @yuki[:text_box_part].hide
    @mutex.lock
    @yuki[:exec_plot] = false
    @yuki[:plot_thread].join
    @yuki[:plot_thread] = nil
    @mutex.unlock
  end

    #===メソッドをシナリオインスタンスに変換する
    #メソッドをシナリオのインスタンス（Methodクラスのインスタンス）に変換する
    #_method_:: メソッド名(シンボル)
    #返却値:: シナリオインスタンスに変換したメソッド
    def scenario(method)
      return self.method(method)
    end
  
    #===ブロックを条件として設定する
    #メソッドをMethodクラスのインスタンスに変換する
    #_block_:: シナリオインスタンスに変換したいメソッド名(シンボル)
    #返却値:: シナリオインスタンスに変換したメソッド
    def condition(&block)
      return block
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
      txt.split(//).each{|ch|
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
      tcolor = @yuki[:text_box].font.color
      @yuki[:text_box].font.color = Color.to_rgb(color)
      text block.call
      @yuki[:text_box].font.color = tcolor
      return self
    end

    #===文字の大きさを変更する
    #ブロック内で指定した文字列を、指定の大きさで描画する
    #_size_:: 文字の大きさ（整数）
    #返却値:: 自分自身を返す
    def size(size, &block)
      tsize = @yuki[:text_box].font.size
      @yuki[:text_box].font.size = size
      text block.call
      @yuki[:text_box].font.size = tsize
      return self
    end
  
    #===太文字を描画する
    #ブロック内で指定した文字列を太文字で表示する
    #返却値:: 自分自身を返す
    def bold(&block)
      tbold = @yuki[:text_box].font.bold?
      @yuki[:text_box].font.bold = true
      text block.call
      @yuki[:text_box].font.bold = tbold
      return self
    end
  
    #===斜体文字を描画する
    #ブロック内で指定した文字列を斜体で表示する
    #返却値:: 自分自身を返す
    def italic(&block)
      titalic = @yuki[:text_box].font.bold?
      @yuki[:text_box].font.italic = true
      text block.call
      @yuki[:text_box].font.italic = titalic
      return self
    end
  
    #===下線付き文字を描画する
    #ブロック内で指定した文字列を下線付きで表示する
    #返却値:: 自分自身を返す
    def under_line(&block)
      tunder_line = @yuki[:text_box].font.under_line?
      @yuki[:text_box].font.under_line = true
      text block.call
      @yuki[:text_box].font.under_line = tunder_line
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
    #_command_list_:: 表示するコマンド群。各要素はCommand構造体の配列
    #_cansel_to_:: キャンセルボタンを押したときの結果。デフォルトはnil（キャンセル無効）
    #_chain_block_:: コマンドの表示方法。あとで書く
    #返却値:: 自分自身を返す
    def command(command_list, cansel_to = nil, &chain_block)
      @yuki[:cansel] = cansel_to

      choices = []
      command_list.each{|cm| choices.push([cm[:body], cm[:result]]) if (cm[:condition] == nil || cm[:condition].call) }
      return self if choices.length == 0

      @yuki[:command_box].command(@yuki[:command_box].create_choices_chain(choices, &chain_block))
      @yuki[:command_box_part].show
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
          @yuki[:command_box_part].hide unless @yuki[:command_box].equal?(@yuki[:text_box])
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

    #===結果を返す
    #コマンド選択など、プロット処理の結果を返す。
    #まだ結果が得られていない場合はnilを得る
    #プロット処理が終了していないのに結果を得られるので注意！
    #返却値:: プロットの処理結果
    def result
      return @yuki[:result]
    end

    #===結果がシーンかどうかを問い合わせる
    #プロット処理の結果がシーン（シーンクラス名）のときはtrueを返す
    #返却値:: 結果がシーンかどうか（true/false）
    def result_is_scene?
      return (@yuki[:result].class == Class && @yuki[:result].include?(Miyako::Story::Scene))
    end

    #===結果がシナリオかどうかを問い合わせる
    #プロット処理の結果がシナリオ（メソッド）のときはtrueを返す
    #返却値:: 結果がシナリオかどうか（true/false）
    def result_is_scenario?
      return (@yuki[:result].kind_of?(Proc) || @yuki[:result].kind_of?(Method))
    end

    #===プロットの処理を待機する
    #指定の秒数（少数可）、プロットの処理を待機する。
    #_length_:: 待機する長さ。単位は秒。少数可。
    #返却値:: 自分自身を返す
    def wait(length)
      @waiting_timer = Miyako::WaitCounter.new(length)
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
  
    private :button
  end
end
