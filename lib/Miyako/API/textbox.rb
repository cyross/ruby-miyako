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

module Miyako
  #==テキストボックスを構成するクラス
  #テキスト表示部、ウェイトカーソル、選択カーソルで構成される
  class TextBox
    include SpriteBase
    include Animation
    include Layout
    extend Forwardable

    @@windows = Array.new

    attr_accessor :textarea
    attr_accessor :select_type, :waiting, :selecting
    attr_accessor :font, :margin
    attr_reader :wait_cursor, :select_cursor, :choices
    attr_reader :locate, :size, :max_height

    #===インスタンスの作成
    #テキストボックスを生成する。パラメータは以下の通り。
    #(括弧内は省略形)
    #_:font_:: 描画フォント(Fontクラスのインスタンス)　デフォルトはFont.sans_serif
    #_:size_:: 描画文字数(2要素の配列またはSize構造体のインスタンス)　デフォルトはSize(20,8)
    #_:wait_cursor(:wc)_:: ボタン入力待ちを示すカーソル(SpriteもしくはSpriteAnimationクラスのインスタンス)
    #_:select_cursor(:sc)_:: 選択カーソル(SpriteもしくはSpriteAnimationクラスのインスタンス)
    #_:page_size_:: 一度にテキストボックスに表示させる選択肢の数(縦方向、デフォルトは8)
    #
    #_params_:: 生成時のパラメータ(ハッシュ引数)
    #返却値:: TextBoxクラスのインスタンス
    def initialize(params = {})
      init_layout
      @visible = true
      @font = params[:font] || Font.sans_serif
      @max_height = @font.line_height
      @locate     = Point.new(0, 0)

      @base = params[:size] || Size.new(20, 8)
      @size = Size.new((@font.size + @font.hspace) * @base[0] - @font.hspace +
                        (@font.use_shadow ? @font.shadow_margin[0] : 0),
                       @font.line_height *
                        @base[1] - @font.vspace)
      @pos = Point.new(0, 0)
      set_layout_size(*@size)

      @margin = 0

      @textarea = Sprite.new({:size => @size, :type => :ac, :is_fill => true})

      @wait_cursor = params[:wait_cursor] || params[:wc] || nil
      @wait_cursor.snap(@textarea) if @wait_cursor
      @default_wait_cursor_position = lambda{|wcursor, tbox| wcursor.center.bottom(:inside)}
      @wait_cursor_position = @default_wait_cursor_position
      @select_cursor = params[:select_cursor] || params[:sc] || nil
      @select_cursor.snap(@textarea) if @select_cursor
      @default_select_cursor_position = lambda{|scursor, tbox| scursor.left(:outside).middle}
      @select_cursor_position = @default_select_cursor_position

      @on_pause = lambda{}

      @on_release = lambda{}
      
      @on_draw = lambda{}
      
      @command_page_size = params[:page_size] || @base[1]

      @choices = Choices.new
      @now_choice = nil
      @pre_attach = false
      
      @waiting = false
      @select_type = :left
      @selecting = false

      @textarea.snap(self)
      @textarea.centering

      @@windows.push(self)

      @move_list = [[lambda{               },
                     lambda{ @choices.right },
                     lambda{ @choices.left }],
                    [lambda{ @choices.down },
                     lambda{                },
                     lambda{               }],
                    [lambda{ @choices.up   },
                     lambda{                },
                     lambda{               }]]
                  
    end

    #===表示可能な文字行数を取得する
    #返却値:: 表示可能な行数
    def rows
      return @base.h
    end

    #===一列に表示可能な文字数を取得する
    #返却される値は全角文字の数だが、半角文字も全角文字1文字と計算されるので注意
    #返却値:: 表示可能な文字数
    def columns
      return @base.w
    end

    #===一列に表示可能な文字数と行数を取得する
    #文字数はcolumns、行数はrowsの値と同一
    #Size構造体のインスタンスとして取得
    #返却値:: 表示可能な文字数と行数
    def text_size
      return Size.new(@base.w, @base.h)
    end

    def update #:nodoc:
    end
    
    #===テキストボックスのアニメーションを開始する
    #返却値:: 自分自身を返す
    def start
      @textarea.start
      @wait_cursor.start if @wait_cursor
      @choices.start
      @select_cursor.start if @select_cursor
      return self
    end

    #===テキストボックスのアニメーションを停止する
    #返却値:: 自分自身を返す
    def stop
      @textarea.stop
      @wait_cursor.stop if @wait_cursor
      @choices.stop
      @select_cursor.stop if @select_cursor
      return self
    end

    #===テキストボックスのアニメーションを先頭に戻す
    #返却値:: 自分自身を返す
    def reset
      @textarea.reset
      @wait_cursor.reset if @wait_cursor
      @choices.reset
      @select_cursor.reset if @select_cursor
      return self
    end

    #===テキストボックスの表示を更新する
    #テキストボックス・選択カーソル・選択肢・ウェイトカーソルのアニメーションを更新する
    #返却値:: 常にfalseを返す
    def update_animation
      @textarea.update_animation
      @wait_cursor.update_animation if (@wait_cursor && @waiting)
      if @selecting 
        @choices.update_animation
        @select_cursor.update_animation if @select_cursor
      end
      return false
    end

    #===スプライトに変換した画像を表示する
    #すべてのパーツを貼り付けた、１枚のスプライトを返す
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 描画したスプライト
    def to_sprite
      rect = self.broad_rect
      sprite = Sprite.new(:size=>rect.to_a[2,2], :type=>:ac)
      self.render_to(sprite){|sunit, dunit| sunit.x -= rect.x; sunit.y -= rect.y }
      yield sprite if block_given?
      return sprite
    end

    #===SpriteUnit構造体を生成する
    #いったんSpriteインスタンスを作成し、それをもとにSpriteUnit構造体を生成する。
    #返却値:: 生成したSpriteUnit構造体
    def to_unit
      return self.to_sprite.to_unit
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #テキストボックスの状態により、取得できる矩形の大きさが変わる
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      rect = self.rect.to_a
      rect_list = []
      rect_list << @wait_cursor.broad_rect if (@wait_cursor && @waiting)
      if @selecting 
        rect_list << @choices.broad_rect
        rect_list << @select_cursor.broad_rect if @select_cursor
      end
      return self.rect if rect_list.length == 0
      rect_list = rect.zip(*rect_list)
      # width -> right
      rect_list[2] = rect_list[2].zip(rect_list[0]).map{|xw| xw[0] + xw[1]}
      # height -> bottom
      rect_list[3] = rect_list[3].zip(rect_list[1]).map{|xw| xw[0] + xw[1]}
      x, y = rect_list[0].min, rect_list[1].min
      return Rect.new(x, y, rect_list[2].max - x, rect_list[3].max - y)
    end

    #===画面に描画する
    #現在のテキストエリア・カーソルを、現在の状態で描画する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る。
    #ブロックの引数は、|インスタンスのSpriteUnit, 画面のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #返却値:: 自分自身を返す
    def render(&block)
      return unless @visible
      @textarea.render(&block)
      @wait_cursor.render(&block) if (@wait_cursor && @waiting)
      if @selecting 
        @choices.render(&block)
        @select_cursor.render(&block) if @select_cursor
      end
      return self
    end

    #===画面に描画する
    #現在のテキストエリア・カーソルを、現在の状態で描画する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る。
    #ブロックの引数は、|インスタンスのSpriteUnit, 転送先のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #返却値:: 自分自身を返す
    def render_to(dst, &block)
      return unless @visible
      @textarea.render_to(dst, &block)
      @wait_cursor.render(dst, &block) if (@wait_cursor && @waiting)
      if @selecting 
        @choices.render(dst, &block)
        @select_cursor.render(dst, &block) if @select_cursor
      end
      return self
    end

    #===文字の描画位置にマージンを設定する
    #marginで指定したピクセルぶん、下に描画する
    #ブロックを渡すと、ブロックを評価している間だけマージンが有効になる
    #_margin_:: 設定するマージン
    #返却値:: 自分自身を返す
    def margin_during(margin)
      raise MiyakoError, "not given block!" unless block_given?
      omargin, @margin = @margin, margin
      yield
      @margin = omargin
      return self
    end

    #===指定した高さで描画する際のマージンを求める
    #現在のフォントの設定で指定の文字列を描画したとき、予想される描画サイズを返す。実際に描画は行われない。
    #第1引数に渡す"align"は、以下の3種類のシンボルのどれかを渡す
    #_:top_:: 上側に描画(マージンはゼロ)
    #_:middle_:: 中間に描画
    #_:bottom_:: 下部に描画
    #
    #_align_:: 描画位置
    #_height_:: 描画する高さ(デフォルトは、描画した最大の高さ）
    #返却値:: マージンの値
    def margin_height(align, height = @max_height)
      return @font.margin_height(align, height)
    end

    #===ブロックを評価している間、文字色を変更する
    #_color_:: 変更する文字色([r,g,b]の3要素の配列(値:0～255))
    #返却値:: 自分自身を返す
    def color_during(color)
      raise MiyakoError, "not given block!" unless block_given?
      @font.color_during(color){ yield }
      return self
    end

    #===フォントサイズを変更する
    #行中の最大フォントサイズが更新されるので、見栄えの良い表示のためにこちらを使用することをお薦めします
    #_size_:: 変更するフォントサイズ
    #返却値:: 自分自身を返す
    def font_size=(size)
      @font.size = size
      @max_height = @font.line_height if @max_height < @font.line_height
      return self
    end

    #===ブロックを評価している間、フォントサイズを変更する
    #_size_:: 変更するフォントサイズ
    #返却値:: 自分自身を返す
    def font_size_during(size)
      raise MiyakoError, "not given block!" unless block_given?
      @font.size_during(size){
        @max_height = @font.line_height if @max_height < @font.line_height
        yield
      }
      return self
    end

    #===ブロックを評価している間、太字に変更する
    #文字が領域外にはみ出る場合があるので注意！
    #返却値:: 自分自身を返す
    def font_bold
      raise MiyakoError, "not given block!" unless block_given?
      @font.bold{ yield }
      return self
    end

    #===ブロックを評価している間、斜体文字に変更する
    #文字が領域外にはみ出る場合があるので注意！
    #返却値:: 自分自身を返す
    def font_italic
      raise MiyakoError, "not given block!" unless block_given?
      @font.italic{ yield }
      return self
    end

    #===ブロックを評価している間、下線付き文字に変更する
    #返却値:: 自分自身を返す
    def font_under_line
      raise MiyakoError, "not given block!" unless block_given?
      @font.under_line{ yield }
      return self
    end

    #===テキストエリアに文字を描画する
    #_text_:: 描画する文字列
    #返却値:: 自分自身を返す
    def draw_text(text)
      @locate.x = @font.draw_text(@textarea, text, @locate.x, @locate.y + @margin)
      @max_height = [@max_height, @font.line_height].max
      @on_draw.call
      return self
    end

    #===文字描画時に行う処理を記述したブロックを登録する
    #処理を行うブロックはオブジェクトとして渡す。
    #ブロック引数の時は、そのブロックを処理している間のみ、そのオブジェクトを呼び出して処理させる
    #_event_:: 文字描画時処理するブロック
    #返却値:: 自分自身を返す
    def on_draw=(event)
      tdraw = @on_draw
      @on_draw = event
      if block_given?
        yield
        @on_draw = tdraw
      end
      return self
    end

    #===選択肢の集合をTextBoxインスタンスに見合う形のChoicesクラスインスタンスの配列に変換する
    #ブロック(引数一つのブロックのみ有効)を渡したときは、ブロックを評価して変換したChoicesクラスの配列を作成する。
    #引数は、以下の構成を持つ配列のリスト。
    #[非選択時スプライト(文字列可),選択時スプライト(文字列・nil可),選択結果インスタンス]
    #　非選択時スプライト：自身が選択されていない時に表示するスプライト。文字列の時は、Shapeクラスなどでスプライトに変更する
    #　選択時スプライト：自身が選択されている時に表示するスプライト。文字列の時は、Shapeクラスなどでスプライトに変更する
    #　(そのとき、文字色が赤色になる)。
    #　nilを渡すと、非選択時スプライトが使われる
    #　選択結果インスタンス：コマンドが決定したときに、resultメソッドの値として渡すインスタンス。
    #_choices_:: 選択肢の集合(上記参照)
    #返却値:: Choicesクラスのインスタンスの配列
    def create_choices_chain(choices)
      if block_given?
        return yield(choices)
      end
      choices = choices.map{|v|
        org_font_color = @font.color
        @font.color = Color[:white]
        body = v[0].to_sprite(@font)
        @font.color = Color[:red]
        body_selected = v[1] ? v[1].to_sprite(@font) : body
        @font.color = org_font_color
        choice = Choices.create_choice(body, body_selected)
        choice.result = v[2]
        choice.end_select_proc = v[3]
        next choice
      }
      choices2 = choices.each_slice(@command_page_size).to_a
      choices2.each_with_index{|cc, x|
        len = cc.length
        right = choices2[x + 1] || choices2[0]
        left = choices2[x - 1]
        yp = @textarea.y + @locate.y
        cc.each_with_index{|v, y|
          v.down = cc[y + 1] || cc[0]
          v.up = cc[y - 1]
          v.right = right[y] || right.last
          v.left = left[y] || left.last
          v.body.move_to(@textarea.x + @locate.x, yp)
          v.body_selected.move_to(@textarea.x + @locate.x, yp)
          yp += [v.body.broad_rect.h, v.body_selected.broad_rect.h].max
        }
      }
      return choices2
    end
    
    #===コマンド選択を設定する
    #コマンド選択処理に移る(self#selecting?メソッドがtrueになる)
    #引数choicesは配列だが、要素は、[コマンド文字列・画像,選択時コマンド文字列・画像,選択した結果(オブジェクト)]
    #として構成されている
    #body_selectedをnilにした場合は、bodyと同一となる
    #body_selectedを文字列を指定した場合は、文字色が赤色になることに注意
    #_choices_:: 選択肢の配列
    #返却値:: 自分自身を返す
    def command(choices)
      @choices.clear
      choices.each{|cc| @choices.create_choices(cc) }
      start_command
      return self
    end

    #===コマンド選択を開始する
    #但し、commandメソッドを呼び出したときは自動的に呼ばれるので注意
    #返却値:: 自分自身を返す
    def start_command
      raise MiyakoError, "don't set Choice!" if @choices.length == 0
      @choices.start_choice
      if @select_cursor
        @select_cursor.snap(@choices.body)
        @select_cursor_position.call(@select_cursor, @choices.body)
      end
      @selecting = true
      return self
    end

    #===コマンド選択を終了する
    #返却値:: 自分自身を返す
    def finish_command
      @selecting = false
      return self
    end

    #===選択肢・選択カーソルを移動させる
    #但し、非選択状態だったときは、選択状態に戻るだけ
    #(そのときの選択肢は、最後に選択した選択肢を指定する)
    #_dx_:: 移動量(x軸方向)。-1,0,1の3種類
    #_dy_:: 移動量(y軸方向)。-1,0,1の3種類
    #返却値:: 自分自身を返す
    def move_cursor(dx, dy)
      unless @choices.any_select?
        @choices.start_choice(nil) # 選択状態を元に戻す
        return self
      end
      @move_list[dy][dx].call
      if @select_cursor
        @select_cursor.snap(@choices.body)
        @select_cursor_position.call(@select_cursor, @choices.body)
      end
      return self
    end

    #===マウスカーソルの位置とコマンドを照合する
    #選択肢・選択カーソルを、マウスカーソルが当たっているコマンドに移動させる
    #どのコマンドにも当たっていない場合は、すべてのコマンドは非選択状態になる
    #_x_:: マウスカーソルの位置(x軸方向)
    #_y_:: マウスカーソルの位置(y軸方向)
    #返却値:: 自分自身を返す
    def attach_cursor(x, y)
      attach = @choices.attach(x, y)
      if attach
        if @select_cursor
          @select_cursor.snap(@choices.body)
          @select_cursor_position.call(@select_cursor, @choices.body)
        end
      else
        @choices.non_select if @pre_attach
      end
      @pre_attach = attach
      return self
    end

    #===マウスカーソルの位置にコマンドがあるかどうかを問い合わせる
    #マウスカーソルがどれかのコマンドの上にあるときはtrue、どれにも当たっていないときはfalseを返す
    #_x_:: マウスカーソルの位置(x軸方向)
    #_y_:: マウスカーソルの位置(y軸方向)
    #返却値:: マウスカーソルがどれかのコマンドにあるときはtrueを返す
    def attach_any_command?(x, y)
      return @choices.attach(x, y)
    end

    def update_layout_position #:nodoc:
      @pos.move_to(*@layout.pos)
    end

    #===入力待ち状態(ポーズ)に表示するカーソルの位置を設定する
    #ポーズカーソルの位置を、パラメータ二つ(カーソル本体・テキストボックス)を引数に取るブロックで実装する
    #位置は、テキストエリアをsnapしていると想定して実装する
    #デフォルトは、テキストエリアの中下に置かれる(center.bottom(:inside))
    #(例)テキストボックスの中下(テキストエリアの外) -> {|wc, tbox| wc.center.bottom(:outside) }
    # 　 テキストボックスの右下(テキストエリアの中) -> {|wc, tbox| wc.right.bottom }
    # 　 テキストの最後尾 -> {|wc, tbox| wc.left{|b| tbox.locate.x }.top{|b| tbox.locate.y} }
    #    (テキストエリアの左上から右下へ現在の描画開始位置(tbox.locateメソッドで示した値)の距離移動した箇所)
    #ブロックを渡していなかったり、ブロックの引数が2個でなければエラーを返す
    #返却値:: 自分自身を返す
    def set_wait_cursor_position(&proc)
      raise MiyakoError, "Can't find block!" unless proc
      raise MiyakoError, "This method must have two parameters!" unless proc.arity == 2
      @wait_cursor_position = proc
      return self
    end

    #===入力待ち状態(ポーズ)に表示するカーソルの位置をデフォルトに戻す
    #デフォルトの位置は、テキストエリアの中下(center.bottom(:inside))に設定されている
    #返却値:: 自分自身を返す
    def reset_wait_cursor_position
      @wait_cursor_position = @default_wait_cursor_position
      return self
    end

    #===コマンド選択時に表示するカーソルの位置を設定する
    #カーソルの位置を、パラメータ二つ(カーソル本体・選択肢)を引数に取るブロックで実装する
    #位置は、テキストエリアをsnapしていると想定して実装する
    #デフォルトは、選択肢の左側に置かれる(left(:outside).middle)
    #(例)選択肢の右側 -> {|wc, choice| wc.right(:outside).middle }
    # 　 選択肢の真上 -> {|wc, choice| wc.centering }
    #ブロックを渡していなかったり、ブロックの引数が2個でなければエラーを返す
    #返却値:: 自分自身を返す
    def set_select_cursor_position(&proc)
      raise MiyakoError, "Can't find block!" unless proc
      raise MiyakoError, "This method must have two parameters!" unless proc.arity == 2
      @select_cursor_position = proc
      return self
    end

    #===入力待ち状態(ポーズ)に表示するカーソルの位置をデフォルトに戻す
    #デフォルトの位置は、テキストエリアの中下(center.bottom(:inside))に設定されている
    #返却値:: 自分自身を返す
    def reset_select_cursor_position
      @select_cursor_position = @default_select_cursor_position
      return self
    end

    #===入力待ち状態(ポーズ)にする
    #ポーズカーソルを表示する。pause?メソッドの結果がtrueになる
    #ポーズカーソルの位置は、set_wait_cursor_positionで設定したブロックが評価されて決定される
    #(デフォルトはテキストエリアの中下
    #返却値:: 自分自身を返す
    def pause
      @waiting = true
      return self unless @wait_cursor
      @wait_cursor_position.call(@wait_cursor, self)
      @on_pause.call
      return self
    end

    #===ポーズ時に行う処理を記述したブロックを登録する
    #処理を行うブロックはオブジェクトとして渡す。
    #ブロック引数の時は、そのブロックを処理している間のみ、そのオブジェクトを呼び出して処理させる
    #_event_:: ポーズ時処理するブロック
    #返却値:: 自分自身を返す
    def on_pause=(event)
      tpause = @on_pause
      @on_pause = event
      if block_given?
        yield
        @on_pause = tpause
      end
      return self
    end

    #===入力待ち状態を解除する
    #同時に、ポーズカーソルを隠蔽する。pause?メソッドの結果がfalseになる
    #返却値:: 自分自身を返す
    def release
      @waiting = false
      @on_release.call
      return self
    end

    #===ポーズ解除時に行う処理を記述したブロックを登録する
    #処理を行うブロックはオブジェクトとして渡す。
    #ブロック引数の時は、そのブロックを処理している間のみ、そのオブジェクトを呼び出して処理させる
    #_event_:: ポーズ解除時処理するブロック
    #返却値:: 自分自身を返す
    def on_release=(event)
      trelease = @on_release
      @on_release = event
      if block_given?
        yield
        @on_release = trelease
      end
      return self
    end

    #===入力待ち状態かを確認する
    #返却値:: 入力待ち状態の時はtrueを返す
    def pause?
      return @waiting
    end

    #===コマンド選択中かどうかを確認する
    #返却値:: 選択中の時はtrueを返す
    def selecting?
      return @selecting
    end

    #===選択結果を取得する
    #返却値:: コマンドの選択結果(選択中のnilを返す)
    def result
      return @choices.result
    end

    #===テキストエリアに描画している文字を消去する
    #透明色で消去したあと、描画開始位置を左上(0,0)に移動する
    #返却値:: 自分自身を返す
    def clear
      @textarea.bitmap.fillRect(0, 0, @size[0], @size[1], [0, 0, 0, 0])
      @locate = Point.new(0, 0)
      @max_height = @font.line_height
      return self
    end

    #===縦方向のスペースを空ける
    #現在描画可能な位置から、指定したピクセルで下方向に移動する
    #但し、文字の大きさもピクセル数に含むことに注意すること
    #_height_:: スペースを空けるピクセル数
    #返却値:: 自分自身を返す
    def cr(height = @max_height)
      @locate.x = 0
      @locate.y += height
      @max_height = @font.line_height
      return self
    end

    #===横方向のスペースを空ける
    #現在描画可能な位置から、指定したピクセルで右方向に移動する
    #_length_:: スペースを空けるピクセル数
    #返却値:: 自分自身を返す
    def space(length)
      @locate.x += length
      return self
    end

    #===情報を解放する
    def dispose
      @textarea.dispose
      @textarea = nil
      @@windows.delete(self)
    end

    def_delegators(:@pos, :x, :y)
  end
end
