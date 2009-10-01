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
  #タイマーを管理するクラス
  class WaitCounter
    SECOND2TICK = 1000

    @@callbacks = {}
    @@post_callbacks = {}
    @@initialized = false

    #WaitCounterインスタンス固有の名前
    #デフォルトはインスタンスIDを文字列化したもの
    attr_accessor :name

    #===起算時からのミリ秒数を取得する
    #起算時からのミリ秒数を整数で取得する
    #返却値:: 起算時からのミリ秒数(整数)
    def WaitCounter.tick
      return SDL.getTicks
    end

    #===起算時からのミリ秒数を取得する
    #起算時からのミリ秒数を整数で取得する
    #返却値:: 起算時からのミリ秒数(整数)
    def WaitCounter.ticks
      return SDL.getTicks
    end

    def WaitCounter.get_second_to_tick(s) #:nodoc:
      return (SECOND2TICK * s).to_i
    end

    #===コールバックハッシュを参照する
    #コールバック処理を登録しているハッシュを参照する
    #キー(WaitCounterインスタンス)に対応する中身は配列になっており、
    #[block(callするブロック), loops(呼び出し回数(設定値)), count(呼び出し回数(現在値))]
    #で構成される
    def WaitCounter.callbacks
      @@callbacks
    end

    #===コールバックハッシュを参照する
    #コールバック処理を登録しているハッシュを参照する
    #キー(WaitCounterインスタンス)に対応する中身は配列になっており、
    #[block(callするブロック), loops(呼び出し回数(設定値)), count(呼び出し回数(現在値))]
    #で構成される
    def WaitCounter.post_callbacks
      @@post_callbacks
    end

    def WaitCounter.callback_inner(hash) #:nodoc:
      hash.each{|wait, array|
        next unless wait.executing?
        if wait.finished?
          callback[0].call(wait, array[1], array[2])
          if array[1] > 0 && array[1] == array[2]
            wait.stop
          else
            array[2] = array[2] + 1 if array[1] > 0
            wait.start
          end
        end
      }
    end

    #===コールバック処理を更新する
    #Miyako.main_loop内では、Screen.clearが呼ばれる直前(画面消去直前)に呼ばれる
    #WaitCounterの処理を確認して、タイマーが制限時間オーバーしたら登録しているブロックを評価する
    def WaitCounter.update
      WaitCounter.callback_inner(@@callbacks)
    end

    #===コールバック処理を更新する
    #Miyako.main_loop内では、Screen.renderが呼ばれる直前(画面更新直前)に呼ばれる
    #WaitCounterの処理を確認して、タイマーが制限時間オーバーしたら登録しているブロックを評価する
    def WaitCounter.post_update
      WaitCounter.callback_inner(@@post_callbacks)
    end

    #===インスタンスを生成する
    #_seconds_:: タイマーとして設定する秒数(実数で指定可能)
    #_name_:: インスタンス固有の名称。デフォルトはnil
    #(nilを渡した場合、インスタンスIDを文字列化したものが名称になる)
    #返却値:: 生成されたインスタンス
    def initialize(seconds, name=nil)
      @seconds = seconds
      @name = name ? name : __id__.to_s
      @wait = WaitCounter.get_second_to_tick(@seconds)
      @st = 0
      @counting = false
    end

    #===自分自身をコールバック処理に追加する
    #Miyako.main_loop内では、Screen.clearが呼ばれる直前(画面消去直前)にブロックが評価される
    #コールバックは、レシーバが明示的に起動している間だけ呼ばれる
    #(ただし、繰り返し呼ばれているときは、自動的にタイマーを再起動する
    # また、呼び出し回数が既定値に達したときは自動的にタイマーを終了する)
    #呼び出し時にブロックを渡さないと例外が発生する
    #また、既にappend_post_callbackメソッドで別のコールバックに登録されているときも例外が発生する
    #引数として、呼び出し回数を渡す
    #無限に呼び出すときは0以下の値を渡す。省略時は0を渡す
    #渡される引数は、(レシーバ,呼び出し回数(設定値),呼び出し回数(現在数))で構成される
    #_calls_:: レシーバの呼び出し回数。無限に呼び出すときは0以下の値を渡す。省略時は0を渡す
    #返却値:: レシーバ
    def append_callback(calls = 0, &block)
      raise MiyakoError, "This method needs some block!" unless block_given?
      raise MiyakoError, "This instance registerd to post_callback!" if @@post_callbacks.has_key?(self)
      @@callbacks[self] = [block, calls, 1]
      self
    end

    #===自分自身をコールバック処理に追加する
    #Miyako.main_loop内では、Screen.renderが呼ばれる直前(画面更新直前)にブロックが評価される
    #コールバックは、レシーバが明示的に起動している間だけ呼ばれる
    #(ただし、繰り返し呼ばれているときは、自動的にタイマーを再起動する
    # また、呼び出し回数が既定値に達したときは自動的にタイマーを終了する)
    #呼び出し時にブロックを渡さないと例外が発生する
    #また、既にappend_callbackメソッドで別のコールバックに登録されているときも例外が発生する
    #引数として、呼び出し回数を渡す
    #無限に呼び出すときは0以下の値を渡す。省略時は0を渡す
    #渡される引数は、(レシーバ,呼び出し回数(設定値),呼び出し回数(現在数))で構成される
    #_calls_:: レシーバの呼び出し回数。無限に呼び出すときは0以下の値を渡す。省略時は0を渡す
    #返却値:: レシーバ
    def append_post_callback(calls = 0, &block)
      raise MiyakoError, "This method needs some block!" unless block_given?
      raise MiyakoError, "This instance registerd to callback!" if @@callbacks.has_key?(self)
      @@post_callbacks[self] = [block, calls, 1]
      self
    end

    #===自分自身をコールバック処理から解除する
    #コールバックに登録されていないレシーバを指定したときは例外が発生する
    #返却値:: レシーバ
    def remove_callback
      @@callbacks.delete(self) || raise(MiyakoError, "This instance unregisterd to callback!")
      self
    end

    #===自分自身をコールバック処理から解除する
    #コールバックに登録されていないレシーバを指定したときは例外が発生する
    #返却値:: レシーバ
    def remove_post_callback
      @@post_callbacks.delete(self) || raise(MiyakoError, "This instance unregisterd to post-callback!")
      self
    end

    #===コールバックを指定したときの呼び出し数を求める
    #コールバックに登録されていないレシーバを指定したときはnilを返す
    #返却値:: 整数もしくはnil
    def callback_calls
      array = @@callbacks[self] || @@post_callbacks[self]
      return nil unless array
      array[1]
    end

    #===コールバックを指定したときの現在の呼び出し数を求める
    #コールバックに登録されていないレシーバを指定したときはnilを返す
    #呼び出し回数が無限の時は-1を返す
    #返却値:: -1以上の整数もしくはnil
    def callback_count
      array = @@callbacks[self] || @@post_callbacks[self]
      return nil unless array
      return -1 if array[1] <= 0
      return array[2] if @counting==false && array[1] == array[2]
      array[2] - 1
    end

    #===設定されているウェイトの長さを求める
    #ウェイトの長さをミリ秒単位で取得する
    #返却値:: ウェイトの長さ
    def length
      return @wait
    end

    alias :size :length

    #===開始からの経過時間を求める
    #タイマー実行中のとき現在の経過時間をミリ秒単位(0以上の整数)で取得する
    #制限時間を超えていれば、制限時間+1を返す
    #まだスタートしてないときは-1を返す
    #返却値:: 現在の経過長
    def now
      if @stop_tick
        cnt = @stop_tick - @st
        return @wait < cnt ? @wait+1 : cnt
      end
      return -1 unless @counting
      cnt = SDL.getTicks - @st
      return @wait < cnt ? @wait+1 : cnt
    end

    #===開始からの残り時間を求める
    #タイマー実行中のとき、残り時間の長さをミリ秒単位(0以上の整数)で取得する
    #制限時間を超えていれば-1を返す
    #まだスタートしてないときは制限時間+1を返す
    #返却値:: 残り時間の長さ
    def remain
      if @stop_tick
        cnt = @stop_tick - @st
        return @wait < cnt ? -1 : @wait - cnt
      end
      return @wait+1 unless @counting
      cnt = SDL.getTicks - @st
      return @wait < cnt ? -1 : @wait - cnt
    end

    alias :remind :remain

    #===タイマー処理を開始状態にする
    #返却値:: 自分自身を返す
    def start
      @st = SDL.getTicks
      @stop_tick = nil
      @counting = true
      return self
    end

    #===タイマー処理を停止状態にする
    #この状態で、startメソッドを呼ぶと、開始前の状態に戻って処理を開始する
    #resumeメソッドを呼ぶと、停止直前の状態に戻って処理を開始する
    #返却値:: 自分自身を返す
    def stop
      @stop_tick = SDL.getTicks
      @counting = false
      return self
    end

    #===タイマーを開始前の状態に戻す
    #remain,nowの結果がstart前の状態に戻る
    #ただし、停止中の時にしか戻せない
    #返却値:: 自分自身を返す
    def reset
      return self if @counting
      @st = 0
      @stop_tick = nil
      return self
    end

    #===タイマー処理を再会する
    #停止前の状態から再びタイマー処理を開始する
    #返却値:: 自分自身を返す
    def resume
      return self unless @stop_tick
      @st += (SDL.getTicks - @stop_tick)
      @stop_tick = nil
      @counting = true
      return self
    end

    #===タイマー処理中かを返す
    #タイマー処理中ならばtrue、停止中ならばfalseを返す
    #返却値:: タイマー処理中かどうかを示すフラグ
    def execute?
      @counting
    end

    alias :executing? :execute?

    def wait_inner(f) #:nodoc:
      now_time = @stop_tick ? @stop_tick : SDL.getTicks
      (now_time - @st) >= @wait ? !f : f
    end

    private :wait_inner

    #===タイマー処理中かを返す
    #タイマー処理中ならばtrue、停止中ならばfalseを返す
    #返却値:: タイマー処理中かどうかを示すフラグ
    def waiting?
      return wait_inner(true)
    end

    #===タイマーが制限時間に達したかを返す
    #タイマーが制限時間に達した(もしくはオーバーした)らtrue、制限時間内ならfalseを返す
    #タイマーが
    #返却値:: タイマー処理が終わったかどうかを示すフラグ
    def finish?
      return wait_inner(false)
    end

    alias :finished? :finish?

    def wait #:nodoc:
      st = SDL.getTicks
      t = SDL.getTicks
      until (t - st) >= @wait do
        t = SDL.getTicks
      end
      return self
    end

    #===残り時間に応じたブロックを呼び出す
    #タイマー処理の状態に応じてブロックを評価して、その結果を渡す
    #タイマー開始前はpre、タイマー実行中はwaiting、制限時間オーバー後はpostに渡したブロックを評価する
    #callを呼び出すときに、ブロックに渡すparamsの数とブロックで定義したparamsの数との整合に注意する(例外が発生する)
    #_waiting_:: タイマー実行中に行うブロック。省略時は空のブロックを渡す
    #_pre_:: タイマー開始前に行うブロック。省略時は空のブロックを渡す
    #_post_:: タイマー制限時間オーバ後に実行中に行うブロック。省略時は空のブロックを渡す
    #_params_:: ブロックに渡す引数。可変引数
    #返却値:: 各ブロックを評価した結果
    def call(waiting=lambda{|*params|}, pre=lambda{|*params|}, post=lambda{|*params|}, *params)
      case self.now
      when -1
        return pre.call(*params)
      when @wait+1
        return post.call(*params)
      else
        return waiting.call(*params)
      end
    end

    #===インスタンスないで所持している領域を開放する
    #(現段階ではダミー)
    def dispose
    end
  end
end

