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
  #==遷移図モジュール群
  module Diagram
  
    #==遷移図矢印構造体
    #ノードの移動先とトリガー(遷移条件)を収めている。
    #to::移動先ノードのインスタンス
    #trigger::遷移条件オブジェクトのインスタンス
    Arrow = Struct.new(:to, :trigger)

    #==遷移ノードモジュール
    #遷移図のノードを構成するモジュール。
    #
    #mixinすることで、ノード構成に必要なメソッドを定義できる。
    #あとは、initializeメソッドなどで、必要なインスタンスを作成することができる。
    #なお、本モジュールでは、値の格納用に @@node_var を予約しているため、注意が必要
    module NodeBase
      @@node_var = {}
      @@node_var.default = nil

      #===ノードでの開始処理を実装する
      #Processor#start メソッドが呼ばれたとき、ノードの移動があった直後の処理を実装する
      def start
      end

      #===ノードでの中断処理を実装する
      #Processor#stop メソッドが呼ばれたとき、ノードの移動する直前の処理を実装する
      def stop
      end

      #===ノードでの停止処理を実装する
      #停止処理を実装しないときは、本メソッドを実装する必要はない
      #Processor#pause メソッドが呼ばれたときの処理を実装する
      def pause
      end

      #===ノードでの復帰処理を実装する
      #停止処理を実装しないときは、本メソッドを実装する必要はない
      #Processor#resume メソッドが呼ばれたときの処理を実装する
      def resume
      end

      #===ノードでの入力デバイス処理を実装する
      #入力デバイス処理が必要ないときは、本メソッドを実装する必要はない
      #Processor#update_input メソッドが呼ばれたときの処理を実装する
      def update_input
      end
    
      #===ノードでの更新処理を実装する
      #Processor#update メソッドが呼ばれたときの処理を実装する
      def update
      end

      #===ノードでの入力デバイス処理の後始末を実装する
      #入力デバイス処理が必要ないときは、本メソッドを実装する必要はない
      #Processor#reset_input メソッドが呼ばれたときの処理を実装する
      def reset_input
      end
    
      #===ノードでのレンダリング処理を実装する
      #Screen.update メソッドを呼び出しているときは、本メソッドを実装する必要はない
      #Processor#render メソッドが呼ばれたときの処理を実装する
      def render
      end

      #===ノードでの実行が終了しているかを示すフラグを返すテンプレートメソッド
      #Manager#add_arrow メソッドの呼び出しで、移動条件を指定しなければ、このメソッドが呼ばれる。
      #
      #ノードの終了を問い合わせる内容を本メソッドに実装する。
      #返却値:: ノードの実行が終了していれば true を返す(デフォルトは無条件で false を返す)
      def finish?
        return false
      end
  
      #===現在実行しているノードの変数の値を取得するテンプレートメソッド
      #Diagram#[] メソッドが呼ばれたときの処理を実装する
      #
      #mixin されたクラス内でアクセスする際は、便宜上、"self[...]"を使用する
      #_name_:: 変数名(文字列・シンボル)
      #返却値:: 変数の値(デフォルトはnil)
      def [](name)
        unless @@node_var[self.object_id]
          @@node_var[self.object_id] = {}
          @@node_var[self.object_id].default = nil
        end
        return @@node_var[self.object_id][name]
      end

      #===現在実行中のノードの変数に値を設定する
      #Diagram#[]= メソッドが呼ばれたときの処理を実装する
      #
      #mixin されたクラス内でアクセスする際は、便宜上、"self[...]=..."を使用する
      #_name_:: 変数名(文字列・シンボル)
      #_value_:: 設定したい値
      def []=(name, value)
        unless @@node_var[self.object_id]
          @@node_var[self.object_id] = {}
          @@node_var[self.object_id].default = nil
        end
        @@node_var[self.object_id][name] = value
      end

      #===ノードのインスタンスを解放させるテンプレートメソッド
      #Processor#dispose メソッドの呼び出したときに呼び出さされる
      def dispose
      end
    end

    #==遷移条件モジュール
    #遷移図の移動条件を構成するモジュール。
    #
    #mixinすることで、遷移条件構成に必要なメソッドを定義できる。
    #各メソッドは、前処理・後処理と、遷移条件の判別式を定義できる。
    #判別式をあらわすメソッドは、必ずtrue/falseをかえすように設計する。
    #判別式を用意できるのは、updateとrenderの処理のみ。
    #あとは、initializeメソッドなどで、必要なインスタンスを作成することができる。
    module TriggerBase
      #===前処理を実装する
      #Processor#start メソッドが呼び出されたときの処理を実装する
      def pre_process
      end
  
      #===後始末を実装する
      #Processor#stop メソッドが呼び出されたときの処理を実装する
      def post_process
      end
  
      #===ノードの更新処理を行うかどうかの問い合わせメソッドを実装する
      #NodeBase#update を呼び出すかどうかを返す処理を実装する
      #デフォルトでは、無条件で true を返す
      #返却値:: NodeBase#update メソッドを呼び出したいときは true を返す
      def update?
        return true
      end

      #===ノードの更新処理が終わった後の後始末を行う
      #NodeBase#update を呼び出された後の処理を実装する
      def post_update
      end
  
      #===ノードのレンダリング処理を行うかどうかの問い合わせメソッドを実装する
      #NodeBase#render を呼び出すかどうかを返す処理を実装する
      #デフォルトでは、無条件で true を返す
      #Screen.update メソッドを呼び出しているときは、本メソッドを実装する必要はない
      #返却値:: NodeBase#render メソッドを呼び出したいときは true を返す
      def render?
        return true
      end
  
      #===ノードのレンダリング処理が終わった後の後始末を行う
      #Screen.update メソッドを呼び出しているときは、本メソッドを実装する必要はない
      #NodeBase#render を呼び出された後の処理を実装する
      def post_render
      end
    end

    #==デフォルト遷移条件クラス
    #デフォルトの遷移条件を構成したクラス。
    #
    #遷移条件が無条件のときにインスタンスを作成するだけで使用できる。
    #すべての条件式が「true」を返すのみとなっている。
    class DefaultTrigger
      include Miyako::Diagram::TriggerBase
    end

    #==遷移図クラス本体
    #但し、実質的にメソッドを呼び出すのはDiagramFacadeクラスから呼び出す
    class DiagramBody
      attr_reader :name #:nodoc:
      TRIGGER_TYPES=[:immediate, :next]

      def initialize(name, body, trigger = nil) #:nodoc:
        @name = name # デバッグ用
        @node = body
        @trigger = trigger ? trigger : Miyako::Diagram::DefaultTrigger.new
        @arrow  = []
        @next_trigger = nil
      end

      def add_arrow(to, trigger) #:nodoc:
        @arrow.push(Miyako::Diagram::Arrow.new(to, trigger))
      end

      def start #:nodoc:
        @trigger.pre_process
        @node.start
      end

      def stop #:nodoc:
        @node.stop
        @trigger.post_process
      end

      def pause #:nodoc:
        @node.pause
      end

      def resume #:nodoc:
        @node.resume
      end

      def update_input #:nodoc:
        @node.update_input
      end
    
      def update #:nodoc:
        if @trigger.update?
          @node.update
          @trigger.post_update
          @node.reset_input
          if @next_trigger
            @trigger = @next_trigger
            @next_trigger = nil
          end
        end
      end

      def render #:nodoc:
        if @trigger.render?
          @node.render
          @trigger.post_render
        end
      end

      def [](name) #:nodoc:
        return @node[name]
      end

      def []=(name, value) #:nodoc:
       @node[name] = value
      end

      #===更新タイミングを計るトリガーオブジェクトを置き換える
      #現在実行しているトリガーを新しいトリガーオブジェクトに置き換える。
      #置き換えのタイミングは、以下の２種が選択可能(シンボルで指定)
      #:immediate:: 即時に置き換え。現在実行中のトリガーを停止して、引数で指定したトリガーに置き換えて実行を開始する
      #:next:: 次回更新時に置き換え。本メソッドが呼ばれた次の更新(updateメソッドが呼ばれた時)にトリガーを置き換える
      #_new_trigger_:: 置き換え対象のトリガーオブジェクト
      #_timing_:: 置き換えのタイミング。:immediateと:nextの２種類がある
      def replace_trigger(new_trigger, timing=:next)
        raise MiyakoError, "I can't understand Timing Typ! : #{timing}" unless TRIGGER_TYPES.include?(timing)
        case timing
        when :immediate
          @trigger.stop
          @trigger.post_process
          @trigger = new_trigger
          @trigger.pre_process
        when :next
          @next_trigger = new_trigger
        end
      end
      
      def dispose #:nodoc:
        @node.dispose
      end

      def go_next #:nodoc:
        next_obj = self
        @arrow.each{|arrow|
          break (next_obj = arrow.to) if (arrow.trigger && arrow.trigger.call(@node))
          break (next_obj = arrow.to) if @node.finish?
        }
        @trigger.post_process unless self.equal?(next_obj)
        return next_obj
      end
    end

    #==遷移図管理クラス
    #遷移図クラス本体(Diagramクラス)を管理するクラス。
    class Manager
      def initialize #:nodoc:
        @name2idx = {}
        @list = []
        @ptr = nil
        @first = nil
        @executing = false
      end

      #===遷移図にノードを追加する
      #_name_:: ノード名。文字列かシンボルを使用
      #_body_:: ノード本体。DiagramNodeBase モジュールを mixin したクラスのインスタンス
      #_trigger_:: NodeTriggerBase モジュールを mixin したクラスのインスタンス。デフォルトは NpdeTrogger クラスのインスタンス
      def add(name, body, trigger = nil)
        @list << Miyako::Diagram::DiagramBody.new(name, body, trigger)
        @name2idx[name] = @list.last
        @first = @list.first unless @first
        return self
      end

      #===ノード間移動のアローを追加する
      #trigger のブロックを実行した結果、true のときは、to_name で示したノードへ移動する。
      #false のときは、ノード間移動をせずに直前に実行したノードを再実行する
      #_from_name_:: 移動元ノード名。文字列かシンボルを使用
      #_to_name_:: 移動先ノード名。文字列かシンボルを使用
      #_trigger_:: ノード間移動するかどうかを返すブロック。ブロックは引数を一つ取る(from_name で示したノードのインスタンス)
      def add_arrow(from_name, to_name, &trigger)
        @name2idx[from_name].add_arrow(to_name ? @name2idx[to_name] : nil, trigger)
        return self
      end
  
      #===対象の名前を持つノードを取得する
      #ノード内の変数にアクセスするときに使う
      #_name_:: ノード名
      #返却値:: 指定のノード
      def [](name)
        raise MiyakoError, "Don't set undefined node name!" unless @name2idx.has_key?(name)
        return @name2idx[name]
      end
 
      #===実行開始ノードを変更する
      #但し、遷移図処理が行われていないときに変更可能
      #_name_:: ノード名
      def move(name)
        raise MiyakoError, "Don't set undefined node name!" unless @name2idx.has_key?(name)
        return if @executing
        @ptr = @name2idx[name]
      end

      #===実行開始ノードを、最初に登録したノードに変更する
      #但し、遷移図処理が行われていないときに変更可能
      def first
        return if @executing
        @ptr = @first
      end

      def now #:nodoc
        return @ptr ? @ptr.name : nil
      end

      def now_node #:nodoc
        return @ptr
      end

      def start #:nodoc:
        @ptr = @first unless @ptr
        return unless @ptr
        @ptr.start
        @executing = true
      end

      def stop #:nodoc:
        @ptr.stop if @ptr
        @ptr = nil
        @executing = false
      end

      def pause #:nodoc:
        @ptr.pause if @ptr
      end

      def resume #:nodoc:
        @ptr.resume if @ptr
      end

      def update_input #:nodoc:
        @ptr.update_input if @ptr
      end
    
      def update #:nodoc:
        return unless @ptr
        @ptr.update
        nxt = @ptr.go_next
        unless @ptr.equal?(nxt)
          @ptr.stop
          @ptr = nxt
          @ptr.start if @ptr
        end
      end

      def render #:nodoc:
        @ptr.render if @ptr
      end

      def finish? #:nodoc:
        return @ptr == nil
      end

      def dispose #:nodoc:
        @name2idx.keys.each{|k|
          @name2idx[k].dispose
        }
      end
    end

    #==レンダラクラス
    #レンダリングのみを行うクラス
    #Processor#render メソッドのみを呼び出せる
    #インスタンス生成は、Processor#renderer メソッドを呼び出して行う
    class Renderer
      def initialize(obj) #:nodoc:
        @renderer = obj
      end

      #===レンダリングを行う
      #Processor#render メソッドを呼び出す
      def render
        @renderer.call
      end
    end

    #==遷移図操作クラス
    #遷移図形式の処理を制御するクラス
    class Processor
      #遷移図本体。Manager クラスのインスタンス
      attr_reader :diagram

      #===インスタンスを生成する
      #遷移図形式のインスタンス群を生成する
      #ブロックを必ず取り(取らないとエラー)、ブロック内では、遷移図の構成を実装する
      #(Manager#add, Manager#add_arrow の各メソッドを参照)
      #返却値:: 生成されたインスタンス
      def initialize
        @loop = self.method(:main_loop)
        @states = {:execute => false, :pause => false, :type1 => false }
        @diagram = Miyako::Diagram::Manager.new
        yield @diagram if block_given?
      end

      #===遷移図形式の処理を開始する
      def start
        return if @states[:execute]
        @diagram.start
        @states[:execute] = true
      end

      #===実行中の処理を中断させる
      def stop
        return unless @states[:execute]
        @diagram.stop
        @states[:execute] = false
      end

      #===実行中の処理を停止させる
      #resume メソッドが呼び出されるまで停止は復帰されない
      def pause
        return unless @states[:execute]
        @states[:pause] = true
      end

      #===停止状態から復帰する
      #このメソッドを呼び出すまで停止状態を保つ
      def resume
        return unless @states[:execute]
        @states[:pause] = false
      end

      #===入力デバイスに関わる処理を行う
      def update_input
        return if @states[:pause]
        @diagram.update_input
      end
    
      #===処理の更新を行う
      def update
        return if @states[:pause]
        @diagram.update
        @states[:execute] = false if @diagram.finish?
      end
    
      #===レンダリング処理を行う
      #Screen.update メソッドを使用している場合は使う必要はない
      def render
        @diagram.render
      end

      #===遷移図形式の処理が終了しているかどうかを取得する
      #遷移図処理が終了したときと停止(Diagram::Processor#stop メソッドを実行)した時に finish? メソッドは true を返す
      #返却値:: 処理が終了していれば(開始前ならば) true を返す
      def finish?
        @diagram.finish?
      end

      #===各ノードに格納されているインスタンスを解放する
      def dispose
        @diagram.dispose
      end

      #===レンダリングのみのインスタンスを生成する
      #MVCを推し進めるため、別の場所でレンダリングを行いたい場合に生成する。
      #返却値:: DiagramRenderer クラスのインスタンス
      def renderer
        return Miyako::Diagram::Renderer.new(self.method(:render))
      end
  
      #===指定した名前のノードを取得する
      #_name_:: ノード名(文字列・シンボル)
      #返却値:: ノード名に対応したノードのインスタンス
      def [](name)
        return @diagram[name]
      end

      #===現在実行しているノード名を取得する
      #返却値:: ノード名(文字列・シンボル)
      def now
        return @diagram.now
      end

      #===現在実行しているノードを取得する
      #返却値:: ノードのインスタンス
      def now_node
        return @diagram.now_node
      end
    end
  end
end
