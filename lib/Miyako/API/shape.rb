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
	@@modes = [:text, :txt_calc, :takahashi, :tk_calc]
		
  #==テキストや図形を描画するクラス
  #図形は、長方形・丸み付き長方形・円・楕円が描画可能
  #文字列は、通常の文字列と高橋メソッド形式文字列が描画可能
  class Shape
    def init_parameter(parameter)
      @text = parameter[:text]
      @size = parameter[:size] ||= Size.new(100,100)
      @color = parameter[:color] ||= Color[:white]
      @font = parameter[:font] ||= Font.sans_serif
      @ray = parameter[:ray] ||= 0
      @edge = parameter[:edge] ||= nil
      @align = parameter[:align] ||= :left
      @valign = parameter[:valign] ||= :middle
			@lines = parameter[:lines] ||= 2
    end

    @@shape_executer = Shape.new

    #===テキストを描画した画像を作成
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:font => 描画するフォントのインスタンス(デフォルトはFont.sans_serif),
    #(:align => 複数行描画するときの文字列のアライン(:left,:center,:rightの三種。デフォルトは:left))
    #(:valign => 行中の小さい文字を描画するときの縦の位置(:top,:middle,:bottomの三種。デフォルトは:middle))
    #_&block_:: 描画するテキスト(Ｙｕｋｉ形式)
    #返却値:: テキストを描画したスプライト
    def Shape.text(param, &block)
      raise MiyakoError, "Cannot find any text(:text parameter)!" unless (param[:text] || block)
      @@shape_executer.create_text(param, block)
    end

    #===テキストを高橋メソッド形式で描画した画像を作成
		#指定した大きさの矩形・行数で文字を描画する。
		#指定した行数で描画を基準に文字サイズを算出する。
    #但し、文字列が長すぎる時は、その文字数を基準に文字サイズを算出する。
    #ブロックに渡した行数が指定数より多くなると文字列がはみ出るため、注意すること。
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:font => 描画するフォントのインスタンス(デフォルトはFont.sans_serif),
    #(:align => 複数行描画するときの文字列のアライン(:left,:center,:rightの三種。デフォルトは:left),
    #(:size => 描画するサイズ(ピクセル単位、Size構造体のインスタンス、デフォルトは[100,100]))
    #(:valign => 行中の小さい文字を描画するときの縦の位置(:top,:middle,:bottomの三種。デフォルトは:middle))
    #(:lines => 描画する行数(デフォルトは2))
    #_&block_:: 描画するテキスト(Ｙｕｋｉ形式)
    #返却値:: テキストを描画したスプライト
    def Shape.takahashi(param, &block)
      @@shape_executer.takahashi(param, block)
    end

    #===長方形を描画する(エッジ付きも可。そのとき、エッジは指定したサイズより内側に描画する)
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:size => 描画するサイズ(ピクセル単位、Size構造体のインスタンス、デフォルトは[100,100]),
    #:color => 長方形の色[r,g,b(,a)]、デフォルトはColor[:white],
    #:edge] => エッジを設定する。値は{:color=>色, :width=>幅}のハッシュを割り付ける)
    #返却値:: 描画したスプライト
    def Shape.box(param)
      @@shape_executer.box(param)
    end

    #===丸み付き長方形を描画する(エッジ付きも可。そのとき、エッジは指定したサイズより内側に描画する)
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:size => 描画するサイズ(ピクセル単位、Size構造体のインスタンス、デフォルトは[100,100]),
    #:ray => 丸みの半径の大きさ(ピクセル単位。デフォルトは0),
    #:color => 長方形の色[r,g,b(,a)]、デフォルトはColor[:white],
    #:edge => エッジを設定する。値は{:color=>色, :width=>幅}のハッシュを割り付ける)
    #返却値:: 描画したスプライト
    def Shape.roundbox(param)
      @@shape_executer.roundbox(param)
    end

    #===円を描画する(エッジ付きも可。そのとき、エッジは指定したサイズより内側に描画する)
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:ray => 円の半径の大きさ(ピクセル単位。デフォルトは0),
    #:color => 円の色[r,g,b(,a)]、デフォルトはColor[:white],
    #:edge => エッジを設定する。値は{:color=>色, :width=>幅}のハッシュを割り付ける)
    #返却値:: 描画したスプライト
    def Shape.circle(param)
      @@shape_executer.circle(param)
    end

    #===楕円を描画する(エッジ付きも可。そのとき、エッジは指定したサイズより内側に描画する)
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:size => 楕円の半径の横・縦の大きさ(ピクセル単位。デフォルトは0),
    #:color => 円の色[r,g,b(,a)]、デフォルトはColor[:white],
    #:edge => エッジを設定する。値は{:color=>色, :width=>幅}のハッシュを割り付ける)
    #返却値:: 描画したスプライト
    def Shape.ellipse(param)
      @@shape_executer.ellipse(param)
    end

    def create_text(param, text_block) #:nodoc:
      init_parameter(param)
      text_block = lambda{ @text } if @text
      org_size = @font.size
      org_color = @font.color
      @margins = []
      @heights = []
      area_size = calc(text_block)
      @sprite = Sprite.new({:size => area_size, :type => :alpha_channel, :is_fill => true})
      case @align
        when :left
          @margins = @margins.map{|v| 0 }
        when :center
          @margins = @margins.map{|v| (area_size.w - v) >> 1 }
        when :right
          @margins = @margins.map{|v| area_size.w - v }
      end
			@lines = @margins.length
      vmargin = 0
      case @valign
        when :top
          vmargin = 0
        when :middle
          vmargin = (area_size.h - @heights.inject(:+)) >> 1
        when :bottom
          vmargin = area_size.h - @heights.inject(:+)
      end
      @locate = Point.new(@margins.shift, vmargin)
      text instance_eval(&text_block)
      @font.size = org_size
      @font.color = org_color
      return @sprite
    end

    def takahashi(param, text_block) #:nodoc:
      init_parameter(param)
      org_size = @font.size
      org_color = @font.color
      olines = @lines
			# calc font size
      @font.size = @size[1] / @lines
			# calc font size incldue line_height
      @font.size = @font.size * @font.size / @font.line_height
      set_font_size_inner(text_block)
      # over lines?
      if @lines > olines
        @font.size = @size[1] / @lines
        @font.size = @font.size * @font.size / @font.line_height
        set_font_size_inner(text_block)
      end
      # over width?
      if @img_size.w > @size[0]
        @font.size = @font.size * @size[0] / @img_size.w
        set_font_size_inner(text_block)
      end
      case @align
        when :left
          @margins = @margins.map{|v| 0 }
        when :center
          @margins = @margins.map{|v| (@size[0] - v) / 2 }
        when :right
          @margins = @margins.map{|v| @size[0] - v }
      end
      vmargin = 0
      case @valign
        when :top
          vmargin = 0
        when :middle
          vmargin = (@size[1] - @heights.inject(:+)) >> 1
        when :bottom
          vmargin = @size[1] - @heights.inject(:+)
      end
      @sprite = Sprite.new({:size => @size, :type => :alpha_channel, :is_fill => true})
      @locate = Point.new(@margins.shift, vmargin)
      text instance_eval(&text_block)
      @font.size = org_size
      @font.color = org_color
      return @sprite
    end
    
    def set_font_size_inner(text_block) #:nodoc:
      @max_height = @font.line_height
      @margins = []
      @heights = []
      @lines = 1
      tcalc(text_block)
    end

    def calc(block) #:nodoc:
      @locate = Point.new(0, 0)
      @img_size = Size.new(0, 0)
      @max_height = @font.line_height
      @lines = 1
      @calc_mode = true
      text instance_eval(&block)
      @calc_mode = false
      if @locate.x != 0
        @margins << @locate.x
        @img_size.w = [@locate.x, @img_size.w].max
        @img_size.h += @max_height
        @heights << @max_height
      end
      return @img_size
    end

    def tcalc(block) #:nodoc:
      @locate = Point.new(0, 0)
      @img_size = Size.new(0, 0)
      @calc_mode = true
      text instance_eval(&block)
      @calc_mode = false
      if @locate.x != 0
        @margins << @locate.x if @locate.x != 0
        @heights << @max_height
      end
      @img_size.w = [@locate.x, @img_size.w].max
    end
		
    #===Shape.textメソッドのブロック内で使用する、文字描画指示メソッド
    #(例)Shape.text(){ text "abc" }
    #(例)Shape.takahashi(:size=>[200,200]){ text "名前重要" }
    #_text_:: 描画するテキスト
    #返却値:: 自分自身
    def text(txt)
      return self if txt.eql?(self)
      txt = txt.gsub(/[\n\r\t\f]/,"")
      @font.draw_text(@sprite, txt, @locate.x, @locate.y) unless @calc_mode
      @locate.x += @font.text_size(txt)[0]
      return self
    end
    
    #===Shape.text/takahashiメソッドのブロック内で使用する、文字色指示メソッド
    #ブロック内で指定した範囲でのみ色が変更される
    #(例)Shape.text(){ text "abc"; cr; color(:red){"def"} }
    #_color_:: 変更する色([r,g,b])もしくはColor[]メソッドの引数
    #返却値:: 自分自身
    def color(color, &block)
      @font.color_during(Color.to_rgb(color)){ text instance_eval(&block) }
      return self
    end

    #===Shape.textメソッドのブロック内で使用する、文字サイズ指示メソッド
    #ブロック内で指定した範囲でのみサイズが変更される
    #(例)Shape.text(){ text "abc"; cr; size(16){"def"} }
    #_size_:: 変更するサイズ(整数)
    #返却値:: 自分自身
    def size(size, &block)
      @font.size_during(size){
        @max_height = [@max_height, @font.line_height].max
        size_inner(@font.margin_height(@valign, @max_height), &block)
      }
      return self
    end
  
    def size_inner(margin, &block) #:nodoc:
      @locate.y += margin
      text instance_eval(&block)
      @locate.y -= margin
    end

    #===Shape.textメソッドのブロック内で使用する、太文字指示メソッド
    #ブロック内で指定した範囲でのみ太文字になる
    #(使用すると文字の端が切れてしまう場合あり！)
    #(例)Shape.text(){ text "abc"; cr; bold{"def"} }
    #返却値:: 自分自身
    def bold(&block)
      @font.bold{ text instance_eval(&block) }
      return self
    end
  
    #===Shape.textメソッドのブロック内で使用する、斜体指示メソッド
    #ブロック内で指定した範囲でのみ斜体文字になる
    #(使用すると文字の端が切れてしまう場合あり！)
    #(例)Shape.text(){ text "abc"; cr; italic{"def"} }
    #返却値:: 自分自身
    def italic(&block)
      @font.italic{ text instance_eval(&block) }
      return self
    end
  
    #===Shape.textメソッドのブロック内で使用する、下線指示メソッド
    #ブロック内で指定した範囲でのみ文字に下線が付く
    #(例)Shape.text(){ text "abc"; cr; bold{"def"} }
    #返却値:: 自分自身
    def under_line(&block)
      @font.under_line{ text instance_eval(&block) }
      return self
    end

    #===Shape.text/takahashiメソッドのブロック内で使用する、改行指示メソッド
    #(例)Shape.text(){ text "abc"; cr; bold{"def"} }
    #返却値:: 自分自身
    def cr
      if @calc_mode
        @margins << @locate.x
        @heights << @max_height
        @img_size.w = [@locate.x, @img_size.w].max
        @img_size.h += @max_height
        @locate.x = 0
        @lines += 1
      else
        @locate.x = @margins.shift || 0
      end
      @locate.y += @max_height
      return self
    end
    
    def box(param) #:nodoc:
      init_parameter(param)
      s = Sprite.new({:size => [w, h], :type => :alpha_channel, :is_fill => true})
      w = @size[0]
      h = @size[1]
      if @edge
        width = @edge[:width]
        s.bitmap.fill_rect(0, 0, w-1, h-1, Color.to_rgb(@edge[:color]))
        s.bitmap.fill_rect(width, width, w-width*2-1, h-width*2-1, Color.to_rgb(@color))
      else
        s.bitmap.fill_rect(0, 0, w-1, h-1, Color.to_rgb(@color))
      end
      return s
    end

    def roundbox_basic(s, x, y, w, h, r, c) #:nodoc:
      color = Color.to_rgb(c)
      s.bitmap.draw_aa_filled_circle(r+x, r+y, r, color)
      s.bitmap.draw_aa_filled_circle(w-r-x-1, r+y, r, color)
      s.bitmap.draw_aa_filled_circle(r+x, h-r-y-1, r, color)
      s.bitmap.draw_aa_filled_circle(w-r-x-1, h-r-y-1, r, color)
      s.bitmap.fill_rect(x, y+r, w-x*2, h-y*2-r*2, color)
      s.bitmap.fill_rect(x+r, y, w-x*2-r*2, h-x*2, color)
    end

    def roundbox(param) #:nodoc:
      init_parameter(param)
      w = @size[0]
      h = @size[1]
      s = Sprite.new(@size, nil, nil)
      s.fill([0, 0, 0, 0])
      if @edge
        roundbox_basic(s, 0, 0, w, h, @ray, Color.to_rgb(@edge[:color]))
        roundbox_basic(s, @edge[:width], @edge[:width], w, h, @ray, Color.to_rgb(@color))
      else
        roundbox_basic(s, 0, 0, w, h, @ray, Color.to_rgb(@color))
      end
      return s
    end

    def circle(param) #:nodoc:
      init_parameter(param)
      s = Sprite.new({:size => [@ray*2+1, @ray*2+1], :type => :alpha_channel, :is_fill => true})
      if @edge
        et, ec = sp.get_param(:edge)[0..1]
        s.bitmap.draw_aa_filled_circle(@ray, @ray, @ray, Color.to_rgb(@edge[:color]))
        s.bitmap.draw_aa_filled_circle(@ray, @ray, @ray-@edge[:width], Color.to_rgb(@color))
      else
        s.bitmap.draw_aa_filled_circle(@ray, @ray, @ray, Color.to_rgb(@color))
      end
      return s
    end

    def ellipse(param) #:nodoc:
      init_parameter(param)
      w = @size[0]
      w2 = w * 2 + 1
      h = @size[1]
      h2 = h * 2 + 1
      s = Sprite.new({:size => [w2, h2], :type => :alpha_channel, :is_fill => true})
      if @edge
        s.bitmap.drawAAFilledEllipse(w, h, w, h, Color.to_rgb(@edge[:color]))
        s.bitmap.drawAAFilledEllipse(w, h, w-@edge[:width], h-@edge[:width], Color.to_rgb(@color))
      else
        s.bitmap.drawAAFilledEllipse(w, h, w, h, Color.to_rgb(@color))
      end
      return s
    end

    private :roundbox_basic
  end
end

class String
  #===文字列から、その文字を描画したスプライトを作成する
  #自分自身が持つ文字列をShape.textメソッドを使用して画像を作成する
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
  #_data_:: 描画するフォント(Fontクラスのインスタンス)
  def to_sprite(data)
    sprite = Miyako::Shape.text({:text => self, :font => data})
    yield sprite if block_given?
    return sprite
  end
end
