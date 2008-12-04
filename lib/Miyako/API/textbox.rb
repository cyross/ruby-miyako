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
    include Layout
    include SpriteBase
    include Animation
    extend Forwardable

    @@windows = Array.new
    @@select_margin = {:left => 1, :over => 0}

    attr_accessor :textarea
    attr_accessor :pause_type, :select_type, :waiting, :selecting
    attr_accessor :font
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

      @pos = Point.new(0, 0)

      set_layout_size(*@size)

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

    #===画面に描画を指示する
    #現在のテキストエリア・カーソルを、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      @textarea.render
      @wait_cursor.render if (@wait_cursor && @waiting)
      if @selecting 
        @choices.render
        @select_cursor.render if @select_cursor
      end
      return self
    end

    #===テキストエリアに文字を描画する
    #_text_:: 描画する文字列
    #返却値:: 自分自身を返す
    def draw_text(text)
      @locate.x = @font.draw_text(@textarea, text, @locate.x, @locate.y)
      @max_height = [@max_height, @font.line_height].max
      return self
    end

    #===あとで書く
    #_choices_:: あとで書く
    #返却値:: あとで書く
    def create_choices_chain(choices)
      choices = choices.map{|v|
        @font.color = Color[:white]
        body = v[0].to_sprite(@font)
        @font.color = Color[:red]
        body_selected = v[1] ? v[1].to_sprite(@font) : body
        choice = Choices.create_choice(body, body_selected)
        choice.result = v[2]
        next choice
      }
      if block_given?
        return yield(choices)
      end
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

    #===あとで書く
    #_dx_:: あとで書く
    #_dy_:: あとで書く
    #返却値:: あとで書く
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

    #===あとで書く
    #返却値:: あとで書く
    def update_layout_position
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
