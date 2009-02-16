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

  #==シーン実行クラス
  #用意したシーンインスタンスを実行
  class Story
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

      @stack = Array.new

      @scene_cache = Hash.new
      @scene_cache_list = Array.new
      @scene_cache_max = 20
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

        raise MiyakoError, "Illegal Script-label name! : #{n}" unless Scene.has_scene?(n.to_s)
        u = get_scene(n, @stack.size) if u == nil
        u.init_inner(@prev_label, self.upper_label)
        u.setup
        
        loop do
          Input.update
          Screen.clear
          n = u.update
          break unless n && on.eql?(n)
          u.render
          Screen.render
        end
        u.next = n
        @next_label = n
        u.final
        if n == nil
          if u.scene_type == :sub_routine && @stack.empty? == false
            n, u = @stack.pop
            next
          end
          break
        elsif n.new(self, false).scene_type == :sub_routine
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

    #==シーンモジュール
    #本モジュールをmixinすることにより、シーンを示すインスタンスを作成することができる
    #mixinするときに気をつけなければいけないのは、本モジュールでは以下のインスタンス変数・モジュール変数を
    #予約しているため、これらの変数の値を勝手に変えてはいけない
    #@@scenesモジュール変数(シーンクラス一覧が入っている配列)、@storyインスタンス変数(シーンを呼び出したStoryクラスインスタンス)
    #@nowインスタンス変数(現在評価しているシーンクラス)、@preインスタンス変数(一つ前に評価していたシーンクラス)
    #@upperインスタンス変数(sub_routineの呼び元シーンクラス)、@nextインスタンス変数(移動先のシーンクラス)
    module Scene
	  @@scenes = {}

      def Scene.included(c) #:nodoc:
        @@scenes[c.to_s] = c
      end

      def Scene.scenes #:nodoc:
        return @@scenes
      end

      def Scene.has_scene?(s) #:nodoc:
        return @@scenes.has_key?(s)
      end

      #===シーン形式を示すテンプレートメソッド
      #シーンには、シーケンスな移動が出来る"scene"形式と、終了したときに移動元に戻る"sub_routine"形式がある。
      #"scene"形式の時はシンボル":scene"、"sub_routine"形式の時はシンボル":sub_routine"を返す様に実装する
      #返却値:: "scene"形式の時はシンボル:scene、"sub_routine"形式の時はシンボル:sub_routineを返す(デフォルトは:sceneを返す)
      def scene_type
        return :scene
      end
      
      def initialize(story, check_only=false) #:nodoc:
        return if check_only
        @story = story
        @now = self.class
        @prev = nil
        @upper = nil
        @next = nil
        self.init
      end

      def init_inner(p, u) #:nodoc:
        @prev = p
        @upper = u
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
        return @now
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
        @next = label
      end

      #===シーンの解説を返す(テンプレートメソッド)
      #Sceneモジュールをmixinしたとき、解説文を返す実装をしておくと、
      #Scene.#lisutupメソッドを呼び出したときに、noticeメソッドの結果を取得できる
      #返却値:: シーンの解説(文字列)
      def notice
        return ""
      end

      #===登録しているシーン一覧をリストアップする
      #リストの内容は、"シーンクラス名(文字列),シーンクラス(ポインタ),解説(noticeメソッドの内容)"という書式で取得できる
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
