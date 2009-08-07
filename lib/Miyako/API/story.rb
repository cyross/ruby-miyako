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

require 'singleton'

module Miyako
  #==シーン実行クラス
  #用意したシーンインスタンスを実行
  class Story

    @@sub_scenes = [:sub_scene, :sub_routine]

    def prev_label #:nodoc:
      return @prev_label
    end

    def next_label #:nodoc:
      return @next_label
    end

    def upper_label #:nodoc:
      return @stack.empty? ? nil : @stack.last[0]
    end

    #===インスタンスの作成
    #ストーリー情報の初期か
    #返却値:: 生成したインスタンス
    def initialize
      @prev_label = nil
      @next_label = nil

      @stack = []

      @scene_cache = Hash.new
      @scene_cache_list = Array.new
      @scene_cache_max = 20

    end

    def initialize_copy(obj) #:nodoc:
      @stack = @stack.dup
      @scene_cache = @scene_cache.dup
      @scene_cache_list = @scene_cache_list.dup
    end

    def get_scene(n, s) #:nodoc:
      class_symbol = n.to_s
      if @scene_cache_list.length == @scene_cache_max
        del_symbol = @scene_cache_list.shift
        @scene_cache[del_symbol].dispose
        @scene_cache.delete(del_symbol)
      end
      @scene_cache_list.delete(class_symbol)
      @scene_cache_list.push(class_symbol)
      @scene_cache[class_symbol] ||= n.new(self)
      return @scene_cache[class_symbol]
    end

    #===Storyの実行を始める
    #"obj.run(MainScene)"と記述すると、SceneモジュールをmixinしたMainSceneクラスのインスタンスを作成し、評価を始める
    #_n_:: 最初に実行するシーン名(クラス名を定数で)
    def run(n)
      return nil if n == nil
      u = nil
      on = nil
      @stack = Array.new # reset
      while n != nil
        @prev_label = on
        on = n

        raise MiyakoValueError, "Illegal Script-label name! : #{n}" unless Scene.has_scene?(n.to_s)
        raise MiyakoValueError, "This scene cannot use for Standard Scene! : #{n}" if n.scene_type != :scene
        u = get_scene(n, @stack.size) if u == nil
        u.init_inner(@prev_label, self.upper_label)
        u.setup

        Miyako.main_loop do
          bk_n = on
          n = u.update
          u.render
          break unless n && on.eql?(n)
        end
        u.next = n
        @next_label = n
        u.final
        if n.nil?
          if @@sub_scenes.include?(u.class.scene_type) && @stack.empty? == false
            n, u = @stack.pop
            next
          end
          break
        elsif @@sub_scenes.include?(n.scene_type)
          @stack.push([on, u])
          u = nil
        else
          u = nil
        end
      end
      @scene_cache_list.each{|sy| @scene_cache[sy].dispose }
      @scene_cache.clear
      @scene_cache_list.clear
    end

    #===内部の情報を解放する
    def dispose
      @scene_cache.keys.each{|k| @scene_cache[del_symbol].dispose }
    end

    #==シーン情報格納のための構造体
    ScenePool = Struct.new(:story, :prev, :next, :upper)

    #==シーンモジュール
    #本モジュールをmixinすることにより、シーンを示すインスタンスを作成することができる
    #mixinするときに気をつけなければいけないのは、本モジュールでは以下の
    #モジュール変数を
    #予約しているため、これらの変数の値を勝手に変えてはいけない
    #・@@scenesモジュール変数(シーンクラス一覧が入っているハッシュ)
    #・@@poolモジュール変数(シーン情報が入っているハッシュ)
    #(互換性のために@nowを残しているが、now_sceneのみを使うときは値を上書きしてもかまわない))
    #また、シーンには「シーン形式」がある。
    #種類は、シーケンスな移動が出来る「通常シーン」、終了したときに移動元に戻る「サブシーン」、
    #現在実行中のシーン上で並行に実行する「オーバーシーン」の3種類。
    #デフォルトは「通常シーン」となっている。
    #判別は、scene_typeクラスメソッドを呼び出すことで可能。デフォルトは、
    #通常シーンを示すシンボル":scene"が返る。
    #形式を変えるには、scene_typeクラスメソッドをオーバーライドし、返却値を変える。
    #サブシーンの時はシンボル":sub_scene"を返すように実装する
    #(注1)同じクラス名のシーンを繰り返し実行したいときは、いったん別のダミーシーンを
    #介してから元のシーンへ移動する必要がある
    #(注2)オーバーシーン内では、シーンの移動が出来ないが、入れ子形式で
    #別のオーバーシーンを積み上げる形なら移動可能。
    module Scene
      @@scenes = {}
      @@pool = {}

      def Scene.included(c) #:nodoc:
        unless c.singleton_methods.include?(:scene_type)
          def c.scene_type
            return :scene
          end
        end
        @@scenes[c.to_s] = c
      end

      def Scene.scenes #:nodoc:
        return @@scenes
      end

      def Scene.has_scene?(s) #:nodoc:
        return @@scenes.has_key?(s)
      end

      def initialize(story, check_only=false) #:nodoc:
        return if check_only
        @@pool[self.object_id] = ScenePool.new(story, nil, nil, nil)
        @now = self.now_scene
        self.init
      end

      def init_inner(p, u) #:nodoc:
        @@pool[self.object_id].prev = p
        @@pool[self.object_id].upper = u
      end

      #===前回実行したシーンを返す
      #前回実行しているシーンをクラス名で返す
      #但し、最初のシーンの場合はnilを返す
      #返却値:: 前回実行したシーン名(Classクラスインスタンス)
      def story
        return @@pool[self.object_id].story
      end

      #===サブルーチンの呼び元シーンを返す
      #サブルーチンを呼び出したシーンをクラス名で返す
      #サブルーチンではないときはnilを返す
      #返却値:: 前回実行したシーン名(Classクラスインスタンス)
      def upper_scene
        return @@pool[self.object_id].upper
      end

      def next_scene #:nodoc:
        return @@pool[self.object_id].next
      end

      #===前回実行したシーンを返す
      #前回実行しているシーンをクラス名で返す
      #但し、最初のシーンの場合はnilを返す
      #返却値:: 前回実行したシーン名(Classクラスインスタンス)
      def prev_scene
        return @@pool[self.object_id].prev
      end

      #===現在実行中のシーンを返す
      #現在実行しているシーンをクラス名で返す
      #返却値:: 前回実行したシーン名(Classクラスインスタンス)
      def now_scene
        return self.class
      end

      #===シーン内で使用するオブジェクトの初期化テンプレートメソッド
      #シーン内で使用するインスタンスを生成するときなどにこのメソッドを実装する
      def init
      end

      #===シーン内で使用するオブジェクトの初期設定テンプレートメソッド
      #シーン内で使用するインスタンスの設定を行うときにこのメソッドを実装する
      #(シーン生成時に生成したインスタンスはキャッシュされ、再利用することができることに注意)
      def setup
      end

      #===シーンの情報を更新するテンプレートメソッド
      #
      #現在実行しているシーンを繰り返し実行する場合はインスタンス変数@nowを返すように実装する
      #nilを返すとシーンの処理を終了する(元のStory#runメソッド呼び出しの次に処理が移る)
      #但し、scene_typeメソッドの結果が:sub_routneのとき、移動元シーンに戻る
      #返却値:: 移動先シーンクラス
      def update
        return now_scene
      end

      #===シーンで指定しているインスタンスを画面に描画するテンプレートメソッド
      def render
      end

      #===シーン内で使用したオブジェクトの後始末を行うテンプレートメソッド
      #ここでは、解放処理(dispose)ではなく、終了処理(値を変更するなど)に実装する
      #setupメソッドと対になっているというイメージ
      def final
      end

      #===シーンに使用したデータの解放を記述するテンプレートメソッド
      #initメソッドと対になっているというイメージ
      def dispose
      end

      def next=(label) #:nodoc:
        @@pool[self.object_id].next = label
      end

      #===シーンの解説を返す(テンプレートメソッド)
      #Sceneモジュールをmixinしたとき、解説文を返す実装をしておくと、
      #Scene.#lisutupメソッドを呼び出したときに、noticeメソッドの結果を取得できる
      #返却値:: シーンの解説(文字列)
      def notice
        return ""
      end

      #===登録しているシーン一覧をリストアップする
      #リストの内容は、"シーンクラス名(文字列),シーンクラス(ポインタ),
      #解説(noticeメソッドの内容)"という書式で取得できる
      #返却値:: リストアップしたシーンの配列
      def Scene.listup
        list = Array.new
        sns = @@scenes
        sns.keys.sort.each{|k| list.push("#{k}, #{sns[k]}, \"#{sns[k].notice}\"\n") }
        return list
      end

      #===Scene.#listupメソッドの内容をCSVファイルに保存する
      #_csvname_:: 保存するCSVファイルパス
      def Scene.listup2csv(csvfname)
        csvfname += ".csv" if csvfname !~ /\.csv$/
        list = self.listup
        File.open(csvfname, "w"){|f| list.each{|l| f.print l } }
      end

    end
  end
end
