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
    @@sub_scenes = [:sub_scene, :sub_routine]
    @@over_scenes = [:over_scene]
  
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
      @fibers = [nil]
      
      @scene_cache = Hash.new
      @scene_cache_list = Array.new
      @scene_cache_max = 20

      @fiber = Proc.new{|sc, num|
        raise MiyakoError, "Illegal Script-label name! : #{sc}" unless Scene.has_scene?(sc.to_s)
        fnum = nil
        bk_nn = sc
        uu = sc.new(self)
        uu.init_inner(@prev_label, self.upper_label)
        uu.setup
        ret = true
        while ret do
          nn = uu.update
          uu.render
          if fnum && @fibers[fnum]
            @fibers[fnum].resume(true)
          elsif nn && !(nn.eql?(uu.class)) && @@over_scenes.include?(nn.scene_type)
            @fibers << Fiber.new(&@fiber)
            fnum = @fibers.length-1
            @fibers[fnum].resume(nn, fnum)
            n = bk_nn
          end
          break unless nn
          ret = Fiber.yield
        end
        uu.final
        uu.dispose
        if (fnum && @fibers[fnum])
          @fibers[fnum].resume(nil)
          @fibers[fnum] = nil
          fnum = nil
        end
        @fibers[num] = nil
      }
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
        raise MiyakoError, "This scene cannot use for Standard Scene! : #{n}" if n.scene_type != :scene
        u = get_scene(n, @stack.size) if u == nil
        u.init_inner(@prev_label, self.upper_label)
        u.setup
        
        loop do
          Input.update
          Screen.clear
          bk_n = on
          n = u.update
          u.render
          if @fibers.first
            @fibers.first.resume(true, 0)
          elsif n && @@over_scenes.include?(n.scene_type)
            @fibers.clear
            @fibers << Fiber.new(&@fiber)
            @fibers.first.resume(n, 0)
            n = bk_n
          end
          Screen.render
          break unless n && on.eql?(n)
        end
        u.next = n
        @next_label = n
        u.final
        if n == nil
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
      if @fibers.length > 0
        @fibers.each{|fiber| fiber.resume(nil) if fiber }
      end
      @scene_cache_list.each{|sy| @scene_cache[sy].dispose }
      @scene_cache.clear
      @scene_cache_list.clear
    end
    
    #==="over_scene"形式のシーンが実行中かどうか判別する
    #返却値:: "over_scene"形式のシーンが実行中の時はtrueを返す
    def over_scene_execute?
      return @now_fiber != nil
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
    #また、シーンには「シーン形式」がある。
    #種類は、シーケンスな移動が出来る「通常シーン」、終了したときに移動元に戻る「サブシーン」、
    #現在実行中のシーン上で並行に実行する「オーバーシーン」の3種類。
    #デフォルトは「通常シーン」となっている。
    #判別は、scene_typeクラスメソッドを呼び出すことで可能。デフォルトは、通常シーンを示すシンボル":scene"が返る。
    #形式を変えるには、scene_typeクラスメソッドをオーバーライドし、返却値を変える。
    #サブシーンの時はシンボル":sub_scene"、オーバーシーンのときはシンボル":over_scene"を返すように実装する
    #(注1)同じクラス名のシーンを繰り返し実行したいときは、いったん別のダミーシーンを介してから元のシーンへ移動する必要がある
    #(注2)オーバーシーン内では、シーンの移動が出来ないが、入れ子形式で別のオーバーシーンを積み上げる形なら移動可能。
    module Scene
	  @@scenes = {}

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

      #==="over_scene"形式のシーンが実行中かどうか判別する
      #返却値:: "over_scene"形式のシーンが実行中の時はtrueを返す
      def over_scene_execute?
        return @story.over_scene_execute?
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
