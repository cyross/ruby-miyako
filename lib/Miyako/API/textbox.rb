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
    @@select_margin = {:left => 1, :over => 0}

    attr_accessor :textarea
    attr_accessor :pause_type, :select_type, :waiting, :selecting
    attr_accessor :font, :margin
    attr_reader :wait_cursor, :select_cursor, :choices
    attr_reader :draw_type, :locate, :size, :max_height

    #===インスタンスの作成
    #テキストボックスを生成する。パラメータは以下の通り。
    #(括弧内は省略形)
    #:font:: 描画フォント(Fontクラスのインスタンス)　デフォルトはFont.sans_serif
    #:size:: 描画文字数(2要素の配列またはSize構造体のインスタンス)　デフォルトはSize(20,8)
    #:wait_cursor(:wc):: ボタン入力待ちを示すカーソル(SpriteもしくはSpriteAnimationクラスのインスタンス)
    #:select_cursor(:sc):: 選択カーソル(SpriteもしくはSpriteAnimationクラスのインスタンス)
    #:page_size:: 一度にテキストボックスに表示させる選択肢の数(縦方向、デフォルトは8)
    #
    #_params_:: 生成時のパラメータ(ハッシュ引数)
    #返却値:: TextBoxクラスのインスタンス
    def initialize(params = {})
      init_layout
      @font = params[:font] || Font.sans_serif
      @max_height = @font.line_height
      @locate     = Point.new(0, 0)

      @base = params[:size] || Size.new(20, 8)
      @size = Size.new(@font.size * @base[0] +
                        (@font.use_shadow ? @font.shadow_margin[0] : 0),
                       @font.line_height *
                        @base[1] - @font.vspace)
      @pos = Point.new(0, 0)
      set_layout_size(*@size)

      @margin = 0

      @textarea = Sprite.new({:size => @size, :type => :ac, :is_fill => true})

      @wait_cursor = params[:wait_cursor] || params[:wc] || nil
      @select_cursor = params[:select_cursor] || params[:sc] || nil

      @command_page_size = params[:page_size] || @base[1]

      @choices = Choices.new
      @now_choice = nil
      
      @pause_type = :bottom
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
    #返却値:: 自分自身を返す
    def render(&block)
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
    #返却値:: 自分自身を返す
    def render_to(dst, &block)
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
    #:top:: 上側に描画(マージンはゼロ)
    #:middle:: 中間に描画
    #:bottom:: 下部に描画
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
        omax = @max_height
        @max_height = @font.line_height if @max_height < @font.line_height
        yield
        @max_height = omax
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
        @font.color = Color[:white]
        body = v[0].to_sprite(@font)
        @font.color = Color[:red]
        body_selected = v[1] ? v[1].to_sprite(@font) : body
        choice = Choices.create_choice(body, body_selected)
        choice.result = v[2]
        next choice
      }
      list = []
      pos = 0
      choices2 = []
      while cpart = choices[pos, @command_page_size]
        break if cpart.length == 0
        choices2.push(cpart)
        pos += @command_page_size
      end
      choices2.each_with_index{|cc, x|
        len = cc.length
        right = choices2[(x + 1) % choices2.length]
        left = choices2[x - 1]
        yp = @textarea.y + @locate.y
        cc.each_with_index{|v, y|
          v.down = cc[(y + 1) % len]
          v.up = cc[y - 1]
          v.right = (y >= right.length ? right.last : right[y])
          v.left = (y >= left.length ? left.last : left[y])
          v.body.move_to(@textarea.x + 
                           @locate.x + 
                           @select_cursor.ow *
                           @@select_margin[@select_type],
                          yp)
          if v.body_selected
            v.body_selected.move_to(@textarea.x + 
                                     @locate.x + 
                                     @select_cursor.ow *
                                     @@select_margin[@select_type],
                                     yp)
          end
          yp += v.body.oh
        }
        list.push(cc)
      }
      return list
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
        @select_cursor.move_to(@choices.body.x -
                                @select_cursor.ow * 
                                @@select_margin[@select_type],
                              @choices.body.y +
                                (@choices.body.oh - @select_cursor.oh) / 2)
        @select_cursor.start
      end
      @choices.start
      @selecting = true
      return self
    end

    #===コマンド選択を終了する
    #返却値:: 自分自身を返す
    def finish_command
      @choices.stop
      @select_cursor.stop
      @selecting = false
      return self
    end

    #===選択肢・選択カーソルを移動させる
    #_dx_:: 移動量(x軸方向)。-1,0,1の3種類
    #_dy_:: 移動量(y軸方向)。-1,0,1の3種類
    #返却値:: 自分自身を返す
    def move_cursor(dx, dy)
      @move_list[dy][dx].call
      if @select_cursor
        @select_cursor.move_to(@choices.body.x -
                                @select_cursor.ow *
                                @@select_margin[@select_type],
                               @choices.body.y +
                                (@choices.body.oh - @select_cursor.oh) / 2)
      end
      return self
    end

    #===マウスカーソルの位置とコマンドを照合する
    #選択肢・選択カーソルを、マウスカーソルが当たっているコマンドに移動させる
    #_x_:: マウスカーソルの位置(x軸方向)
    #_y_:: マウスカーソルの位置(y軸方向)
    #返却値:: 自分自身を返す
    def attach_cursor(x, y)
      return self unless @choices.attach(x, y)
      if @select_cursor
        @select_cursor.move_to(@choices.body.x -
                                @select_cursor.ow *
                                @@select_margin[@select_type],
                               @choices.body.y +
                                (@choices.body.oh - @select_cursor.oh) / 2)
      end
      return self
    end

    def update_layout_position #:nodoc:
      @pos.move_to(*@layout.pos)
    end

    #===入力待ち状態(ポーズ)にする
    #ポーズカーソルを表示する。pause?メソッドの結果がtrueになる
    #ポーズカーソルの位置は、pause_type=メソッドの結果に依る(デフォルトは:bottom)
    #返却値:: 自分自身を返す
    def pause
      @waiting = true
      return self unless @wait_cursor
      case @pause_type
      when :bottom
        @wait_cursor.move_to(@textarea.x +
                              (@textarea.w - @wait_cursor.ow) / 2,
                             @textarea.y + @textarea.h - @wait_cursor.oh)
      when :out
        @wait_cursor.move_to(@textarea.x +
                              (@textarea.w - @wait_cursor.ow) / 2,
                             @textarea.y + @textarea.h)
      when :last
        @wait_cursor.move_to(@textarea.x + @locate.x, @textarea.y + @locate.y)
      end
      @wait_cursor.start
      return self
    end

    #===入力待ち状態を解除する
    #同時に、ポーズカーソルを隠蔽する。pause?メソッドの結果がfalseになる
    #返却値:: 自分自身を返す
    def release
      @waiting = false
      @wait_cursor.stop if @wait_cursor
      return self
    end

    #===入力待ち状態かを確認する
    #返却値:: 入力待ち状態の時はtrueを返す
    def pause?
      return @waiting
    end

    #===あとで書く
    #返却値:: あとで書く
    def selecting?
      return @selecting
    end

    #===あとで書く
    #返却値:: あとで書く
    def result
      return @choices.result
    end

    #===あとで書く
    #返却値:: あとで書く
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

    #===ブロックで指定した描画処理を非同期に行う
    #ブロックを渡すと、描画処理を非同期に行う。
    #更新処理はスレッドを使うが、現在、終了を確認する方法が無いため、扱いに注意すること
    #（確実にスレッド処理が終わるコードになっているか確認すること）
    #返却値:: 自分自身を返す
    def exec
      Thread.new(Proc.new){|proc| proc.call } if block_given?
      return self
    end

    #===あとで書く
    #返却値:: あとで書く
    def dispose
      @textarea.dispose
      @textarea = nil
      @@windows.delete(self)
    end

    def_delegators(:@pos, :x, :y)
  end
end
