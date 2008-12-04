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
    end

    @@shape_executer = Shape.new

    #===テキストを描画した画像を作成
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:font => 描画するフォントのインスタンス(デフォルトはFont.sans_serif),
    #(:align => 複数行描画するときの文字列のアライン(:left,:center,:rightの三種。デフォルトは:left))
    #_&block_:: 描画するテキスト(Ｙｕｋｉ形式)
    #返却値:: テキストを描画したスプライト
    def Shape.text(param, &block)
      @@shape_executer.create_text(param, block)
    end

    #===テキストを高橋メソッド形式で描画した画像を作成
    #_param_:: 設定パラメータ。ハッシュ形式。
    #(:font => 描画するフォントのインスタンス(デフォルトはFont.sans_serif),
    #(:align => 複数行描画するときの文字列のアライン(:left,:center,:rightの三種。デフォルトは:left),
    #(:size => 描画するサイズ(ピクセル単位、Size構造体のインスタンス、デフォルトは[100,100]))
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
      @locate = Point.new(0, 0)
      area_size = calc(text_block)
      area_size.w += @font.shadow_margin[0] if @font.use_shadow
      @sprite = Sprite.new({:size => area_size, :type => :alpha_channel, :is_fill => true})
      case @align
        when :left
        @margins = @margins.map{|v| 0 }
        when :center
        @margins = @margins.map{|v| (area_size.w - v) / 2  }
        when :right
        @margins = @margins.map{|v| area_size.w - v  }
      end
      @locate = Point.new(@margins.shift, 0)
      text instance_eval(&text_block)
      @font.size = org_size
      @font.color = org_color
      return @sprite
    end

    def takahashi(param, text_block) #:nodoc:
      init_parameter(param)
      org_size = @font.size
      org_color = @font.color
      @margins = []
      @locate = Point.new(0, 0)
      area_size = calc_takahashi(text_block)
      @font.size = @font.get_fit_size([(@size[0] - (@font.use_shadow ? @font.shadow_margin[0] : 0)) / area_size.w,
                    @size[1] / area_size.h.to_i].min)
      area_size = Size.new(area_size.w * @font.size, area_size.h * @font.line_height)
      case @align
        when :left
        @margins = @margins.map{|v| 0 }
        when :center
        @margins = @margins.map{|v| (area_size.w - v * @font.size) / 2  }
        when :right
        @margins = @margins.map{|v| area_size.w - v * @font.size  }
      end
      @sprite = Sprite.new({:size => area_size, :type => :alpha_channel, :is_fill => true})
      @locate = Point.new(@margins.shift, 0)
      @max_height = @font.line_height
      text instance_eval(&text_block)
      @font.size = org_size
      @font.color = org_color
      return @sprite
    end

    def calc(block) #:nodoc:
      @calc_mode = true
      @img_size = Size.new(0, 0)
      @max_height = @font.line_height
      text instance_eval(&block)
      @calc_mode = false
      if @locate.x != 0
        @margins << @locate.x
        @img_size.w = [@locate.x, @img_size.w].max
        @img_size.h += @max_height
      end
      return @img_size
    end

    def calc_takahashi(block) #:nodoc:
      @takahashi_calc_mode = true
      @img_size = Size.new(0, 0)
      text instance_eval(&block)
      @takahashi_calc_mode = false
      if @locate.x != 0
        @margins << @locate.x
        @img_size.w = [@locate.x, @img_size.w].max
        @img_size.h += 1
      end
      return @img_size
    end

    #===Shape.text/takahashiメソッドのブロック内で使用する、文字描画指示メソッド
    #(例)Shape.text(){ text "abc" }
    #(例)Shape.takahashi(:size=>[200,200]){ text "名前重要" }
    #_text_:: 描画するテキスト
    #返却値:: 自分自身
    def text(txt)
      return self if txt.eql?(self)
      txt = txt.gsub(/[\n\r\t\f]/,"")
      if @takahashi_calc_mode
        @locate.x += txt.split(//).length
      elsif @calc_mode
        @locate.x += @font.text_size(txt)[0]
      else
        @font.draw_text(@sprite, txt, @locate.x, @locate.y)
        @locate.x += @font.text_size(txt)[0]
      end
      return self
    end
    
    #===Shape.text/takahashiメソッドのブロック内で使用する、文字色指示メソッド
    #ブロック内で指定した範囲でのみ色が変更される
    #(例)Shape.text(){ text "abc"; cr; color(:red){"def"} }
    #_color_:: 変更する色([r,g,b])もしくはColor[]メソッドの引数
    #返却値:: 自分自身
    def color(color, &block)
      tcolor = @font.color
      @font.color = Color.to_rgb(color)
      text instance_eval(&block)
      @font.color = tcolor
      return self
    end

    #===Shape.textメソッドのブロック内で使用する、文字サイズ指示メソッド
    #ブロック内で指定した範囲でのみサイズが変更される
    #(例)Shape.text(){ text "abc"; cr; size(16){"def"} }
    #_size_:: 変更するサイズ(整数)
    #返却値:: 自分自身
    def size(size, &block)
      tsize = @font.size
      @font.size = size
      @max_height = [@max_height, @font.line_height].max
      text instance_eval(&block)
      @font.size = tsize
      return self
    end
  
    #===Shape.textメソッドのブロック内で使用する、太文字指示メソッド
    #ブロック内で指定した範囲でのみ太文字になる
    #(例)Shape.text(){ text "abc"; cr; bold{"def"} }
    #返却値:: 自分自身
    def bold(&block)
      tbold = @font.bold?
      @font.bold = true
      text instance_eval(&block)
      @font.bold = tbold
      return self
    end
  
    #===Shape.textメソッドのブロック内で使用する、斜体指示メソッド
    #ブロック内で指定した範囲でのみ斜体文字になる
    #(例)Shape.text(){ text "abc"; cr; italic{"def"} }
    #返却値:: 自分自身
    def italic(&block)
      titalic = @font.bold?
      @font.italic = true
      text instance_eval(&block)
      @font.italic = titalic
      return self
    end
  
    #===Shape.textメソッドのブロック内で使用する、下線指示メソッド
    #ブロック内で指定した範囲でのみ文字に下線が付く
    #(例)Shape.text(){ text "abc"; cr; bold{"def"} }
    #返却値:: 自分自身
    def under_line(&block)
      tunder_line = @font.under_line?
      @font.under_line = true
      text instance_eval(&block)
      @font.under_line = tunder_line
      return self
    end

    #===Shape.text/takahashiメソッドのブロック内で使用する、改行指示メソッド
    #(例)Shape.text(){ text "abc"; cr; bold{"def"} }
    #返却値:: 自分自身
    def cr
      if @calc_mode
        @margins << @locate.x
        @img_size.w = [@locate.x, @img_size.w].max
        @img_size.h += @max_height
        @locate.x = 0
      elsif @takahashi_calc_mode
        @margins << @locate.x
        @img_size.w = [@locate.x, @img_size.w].max
        @img_size.h += 1
        @locate.x = 0
      else
        @locate.x = @margins.shift
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
  #_data_:: 描画するフォント(Fontクラスのインスタンス)
  def to_sprite(data)
    return Miyako::Shape.text({:text => self, :font => data})
  end
end
