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

# フォント関連クラス(群)
module Miyako

=begin rdoc
==フォント管理クラス
フォントは、等幅フォント奨励(プロポーショナルフォントを選ぶと、文字が正しく描画されない可能性あり）
=end
  class Font
    extend Forwardable

#    OS_MAC_OS_X = "mac_osx"
#    ORG_ENC = "UTF-8"
#    NEW_ENC = "UTF-8-MAC"
    
    attr_reader :size, :line_skip, :height, :ascent, :descent
    attr_accessor :color, :use_shadow, :shadow_color, :shadow_margin, :vspace, :hspace

    @@font_cache = {}

    @@name_2_font_path = Hash.new

    @@font_base_path = Hash.new
    @@font_base_path["win"] = ENV['SystemRoot'] ? ["./", ENV['SystemRoot'].tr("\\", "/") + "/fonts/"] : ["./"]
    @@font_base_path["linux"] = ["./", "/usr/share/fonts/", "/usr/X11R6/lib/X11/fonts/"]
    @@font_base_path["mac_osx"] = ["./", "~/Library/Fonts/", "/Library/Fonts/", "/System/Library/Fonts/",
                                      "/ライブラリ/Fonts/", "/システム/ライブラリ/Fonts/"]

    @@font_base_name = Hash.new
    @@font_base_name["win"] = [{:serif=>"msmincho.ttc", :sans_serif=>"msgothic.ttc"},
                               {:serif=>"VL-Gothic-Regular.ttf", :sans_serif=>"VL-Gothic-Regular.ttf"},
                               {:serif=>"umeplus-gothic.ttf", :sans_serif=>"umeplus-gothic.ttf"},
                               {:serif=>"msmincho.ttc", :sans_serif=>"meiryo.ttc"}]
    @@font_base_name["linux"] = [{:serif=>"sazanami-mincho.ttf", :sans_serif=>"sazanami-gothic.ttf"},
                                    {:serif=>"VL-Gothic-Regular.ttf", :sans_serif=>"VL-Gothic-Regular.ttf"},
                                    {:serif=>"umeplus-gothic.ttf", :sans_serif=>"umeplus-gothic.ttf"}]
    @@font_base_name["mac_osx"] = [{:serif=>"Hiragino Mincho Pro W3.otf", :sans_serif=>"Hiragino Kaku Gothic Pro W3.otf"},
                                      {:serif=>"Hiragino Mincho Pro W6.otf", :sans_serif=>"Hiragino Kaku Gothic Pro W6.otf"},
                                      {:serif=>"ヒラギノ明朝 Pro W3.otf", :sans_serif=>"ヒラギノ角ゴ Pro W3.otf"},
                                      {:serif=>"ヒラキ゛ノ明朝 Pro W3.otf", :sans_serif=>"ヒラキ゛ノ角コ゛ Pro W3.otf"},
                                      {:serif=>"ヒラギノ明朝 Pro W6.otf", :sans_serif=>"ヒラギノ角ゴ Pro W6.otf"},
                                      {:serif=>"ヒラキ゛ノ明朝 Pro W6.otf", :sans_serif=>"ヒラキ゛ノ角コ゛ Pro W6.otf"},
                                      {:serif=>"VL-Gothic-Regular.ttf", :sans_serif=>"VL-Gothic-Regular.ttf"},
                                      {:serif=>"umeplus-gothic.ttf", :sans_serif=>"umeplus-gothic.ttf"}]

    def Font.search_font_path_file(hash, path) #:nodoc:
      Dir.glob(path+"*"){|d|
        hash = Font.search_font_path_file(hash, d+"/") if test(?d, d)
        d = d.encode(Encoding::UTF_8) if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
        d = d.tr("\\", "\/")
        hash[$1] = d if (d =~ /\/([^\/\.]+\.tt[fc])\z/ || d =~ /\/([^\/\.]+\.otf)\z/) # MacOSX対応
      }
      return hash
    end

    def Font.create_font_path #:nodoc:
      osn = Miyako::getOSName
      @@font_base_path[osn].each{|path|
        path = path.encode(Encoding::UTF_8) if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
        path = path.tr("\\", "\/")
        @@name_2_font_path = Font.search_font_path_file(@@name_2_font_path, path)
      }
    end

    def Font.findFontPath(fname) #:nodoc:
      fname = fname.encode(Encoding::UTF_8) if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
      return @@name_2_font_path.fetch(fname, nil)
    end

    def Font.get_font_inner(fname, fpath, size=16) #:nodoc:
      if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
        fname = fname.encode(Encoding::UTF_8)
        fpath = fpath.encode(Encoding::UTF_8)
      end
      @@font_cache[fname] ||= {}
      @@font_cache[fname][size] ||= SDL::TTF.open(fpath, size)
      return @@font_cache[fname][size]
    end

    def init_height #:nodoc:
      @line_skip = @font.line_skip
      @height    = @font.height
      @ascent    = @font.ascent
      @descent   = @font.descent
    end

    private :init_height

    #===インスタンス生成
    #指定したフォントファイル名から、フォントインスタンスを生成する。
    #フォントファイルのパスは、Miyako2.0起動時にファイルパス(カレントディレクトリとシステムのフォントディレクトリ)を
    #再帰的に検索し、先に見つけた方を採用する(同一ファイル名がカレントディレクトリとシステムのディレクトリに両方
    #存在するときは、カレントディレクトリを優先する)
    #そのため、フォントファイル名は、パスを指定する必要がない(逆に言うと、パスを指定すると例外が発生する)。
    #_fname_:: フォントファイル名(フォントファミリー名不可)。パス指定不可
    #_size_:: フォントの大きさ。単位はピクセル。デフォルトは 16
    #返却値:: 生成されたインスタンスを返す
    def initialize(fname, size=16)
      @size = size
      @color = [255, 255, 255]
      @fname = fname
      @vspace = 0
      @hspace = 0
      @bold = false
      @italic = false
      @under_line = false
      @fpath = Font.findFontPath(@fname) or raise MiyakoError, "Cannot Find Font! : #{@fname}"
      @font = Font.get_font_inner(@fname, @fpath, @size)
      @font.style = SDL::TTF::STYLE_NORMAL
      init_height
      @use_shadow = false
      @shadow_color = [128, 128, 128]
      @shadow_margin = [2, 2]
      @unit = SpriteUnitFactory.create
    end

    #===フォントの大きさを変更する
    #_sz_:: 変更するフォントの大きさ(単位：ピクセル)
    #返却値:: 変更されたフォントのインスタンス
    def size=(sz)
      @size = sz
      @font = Font.get_font_inner(@fname, @fpath, @size)
      @font.style = (@bold ? SDL::TTF::STYLE_BOLD : 0) | (@italic ? SDL::TTF::STYLE_ITALIC : 0) | (@under_line ? SDL::TTF::STYLE_UNDERLINE : 0)
      init_height
      return self
    end

    #===ブロック評価中のみ、フォントの大きさを変更する
    #_sz_:: 変更するフォントの大きさ(単位：ピクセル)
    #返却値:: 自分自身を返す
    def size_during(sz)
      raise MiyakoError, "not given block!" unless block_given?
      tsize = @size
      self.size = sz
      yield
      self.size = tsize
      return self
    end

    #===ブロック評価中のみ、フォントの文字の色を変更する
    #_color_:: 変更する色([r,g,b]の3要素の配列(値:0～255))
    #返却値:: 自分自身を返す
    def color_during(color)
      raise MiyakoError, "not given block!" unless block_given?
      tcolor, self.color = @color, color
      yield
      self.color = tcolor
      return self
    end

    #===ブロック評価中のみ、影文字文字の色・マージンを変更する
    #また、ブロック評価中は影文字が強制的に有効になる
    #_color_:: 変更する色([r,g,b]の3要素の配列(値:0～255))、デフォルトはFont#shadow_colorメソッドの値([128,128,128])
    #_margin_:: 変更する色(2要素の整数の配列、デフォルトはFont#shadow_marginメソッドの値([2,2])
    #返却値:: 自分自身を返す
    def shadow_during(color = @shadow_color, margin = @shadow_margin)
      raise MiyakoError, "not given block!" unless block_given?
      tflag, @use_shadow = @use_shadow, true
      tcolor, @shadow_color = @shadow_color, color
      tmargin, @shadow_margin = @shadow_margin, margin
      yield
      @use_shadow = tflag
      @shadow_color = tcolor
      @shadow_margin = tmargin
      return self
    end

    #===指定したピクセル数のフォントが十分(欠けることなく)収まるピクセル数を取得する
    #_size_:: フォントの大きさ(単位：ピクセル)
    #返却値:: 算出されたピクセル数
    def get_fit_size(size)
      path = Font.findFontPath(@fname)
      font = SDL::TTF.open(path, size)
      return (size.to_f * (size.to_f / font.line_skip.to_f)).to_i 
    end
    
    #===フォントサイズ(yやjなどの下にはみ出る箇所も算出)を取得する
    #返却値:: 算出されたフォントサイズ
    def line_height
      return @line_skip + @vspace + (@use_shadow ? @shadow_margin[1] : 0)
    end

    #===フォントインスタンスを解放する
    def dispose
      @font = nil
    end

    #===フォントの属性をbold(太文字)に設定する
    #ブロックを渡したときは、ブロック評価中のみ太字になる
    #文字が領域外にはみ出る場合があるので注意！
    #返却値:: 自分自身
    def bold
      if block_given?
        tbold, self.bold = self.bold?, true
        yield
        self.bold = tbold
      else
        self.bold = true
      end
      return self
    end
    
    #===フォントのbold属性の有無を返す
    #返却値:: bold属性かどうか(true/false)
    def bold?
      return @bold
    end
    
    #===フォントのbold属性を設定する
    #_f_:: bold属性かどうか(true/false)
    def bold=(f)
      @bold = f
      @font.style |= SDL::TTF::STYLE_BOLD
      @font.style -= SDL::TTF::STYLE_BOLD unless @bold
      return self
    end
    
    #===フォントの属性をitalic(斜め)に設定する
    #ブロックを渡したときは、ブロック評価中のみ斜体文字になる
    #文字が領域外にはみ出る場合があるので注意！
    #返却値:: 自分自身
    def italic
      if block_given?
        titalic, self.italic = self.italic?, true
        yield
        self.italic = titalic
      else
        self.italic = true
      end
      return self
    end
    
    #===フォントのitalic属性の有無を返す
    #返却値:: italic属性かどうか(true/false)
    def italic?
      return @italic
    end
    
    #===フォントのitalic属性を設定する
    #_f_:: italic属性かどうか(true/false)
    def italic=(f)
      @italic = f
      @font.style |= SDL::TTF::STYLE_ITALIC
      @font.style -= SDL::TTF::STYLE_ITALIC unless @italic
      return self
    end
    
    #===フォントの属性をunder_line(下線)に設定する
    #ブロックを渡したときは、ブロック評価中のみ下線付き文字になる
    #返却値:: 自分自身
    def under_line
      if block_given?
        tunder_line, self.under_line = self.under_line?, true
        yield
        self.under_line = tunder_line
      else
        self.under_line = true
      end
      return self
    end
    
    #===フォントのunder_line属性の有無を返す
    #返却値:: under_line属性かどうか(true/false)
    def under_line?
      return @under_line
    end
    
    #===フォントのunder_line属性を設定する
    #_f_:: under_line属性かどうか(true/false)
    def under_line=(f)
      @under_line = f
      @font.style |= SDL::TTF::STYLE_UNDERLINE
      @font.style -= SDL::TTF::STYLE_UNDERLINE unless @under_line
      return self
    end

    #===フォントの属性をすべてクリアする
    #_f_:: 自分自身
    def normal
      @font.style = 0
      return self
    end
    
    #===文字列を描画する
    #対象のスプライトに文字列を描画する
    #_dst_:: 描画先スプライト
    #_str_:: 描画する文字列
    #_x_:: 描画位置x軸
    #_y_:: 描画位置Y軸
    def draw_text(dst, str, x, y)
      str = str.encode(Encoding::UTF_8)
      str.chars{|c|
        if @use_shadow
          src2 = @font.renderBlendedUTF8(c, @shadow_color[0], @shadow_color[1], @shadow_color[2])
          if src2
            SpriteUnitFactory.apply(@unit, {:bitmap=>src2, :ow=>src2.w, :oh=>src2.h})
            Miyako::Bitmap.blit_aa!(@unit, dst.to_unit, x+@shadow_margin[0], y+@shadow_margin[1])
          else
            break x
          end
        end
        src = @font.renderBlendedUTF8(c, @color[0], @color[1], @color[2])
        if src
          SpriteUnitFactory.apply(@unit, {:bitmap=>src, :ow=>src.w, :oh=>src.h})
          Miyako::Bitmap.blit_aa!(@unit, dst.to_unit, x, y)
        else
          break x
        end
        x += chr_size_inner(c)
      }
      return x
    end

    #===文字列描画したときの大きさを取得する
    #現在のフォントの設定で指定の文字列を描画したとき、予想される描画サイズを返す。実際に描画は行われない。
    #_txt_:: 算出したい文字列
    #返却値:: 文字列を描画したときの大きさ([w,h]の配列)
    def chr_size_inner(char)
      return (char.bytesize == 1 ? @size >> 1 : @size) + (@use_shadow ? @shadow_margin[0] : 0) + @hspace
    end
    
    private :chr_size_inner

    #===文字列描画したときの大きさを取得する
    #現在のフォントの設定で指定の文字列を描画したとき、予想される描画サイズを返す。実際に描画は行われない。
    #_txt_:: 算出したい文字列
    #返却値:: 文字列を描画したときの大きさ([w,h]の配列)
    def text_size(txt)
      width = txt.chars.inject(0){|r, c| r += (c.bytesize == 1 ? @size >> 1 : @size) } + ((@use_shadow ? @shadow_margin[0] : 0) + @hspace) * (txt.chars.to_a.length - 1)
      return [width, self.line_height]
    end
    
    #===指定した高さで描画する際のマージンを求める
    #現在のフォントの設定で指定の文字列を描画したとき、予想される描画サイズを返す。実際に描画は行われない。
    #第1引数に渡す"align"は、以下の3種類のシンボルのどれかを渡す
    #:top:: 上側に描画(マージンはゼロ)
    #:middle:: 中間に描画
    #:bottom:: 下部に描画
    #
    #_align_:: 描画位置
    #_height_:: 描画する高さ
    #返却値:: マージンの値
    def margin_height(align, height)
      case align
        when :top
          return 0
        when :middle
          return (height - self.line_height) >> 1
        when :bottom
          return height - self.line_height
      end
      #else
      raise MiyakoError, "Illegal margin_height align! : #{align}"
    end

    Font.create_font_path

    #===Serifフォント(明朝フォント)を取得する
    #マルチプラットフォームのソフトを作る際、OS間の差異を吸収するため、共通の名称でフォントインスタンスを取得するときに使う(主に明朝フォント)
    #返却値:: OSごとに設定されたフォントイン寸タンス(フォントサイズは16)
    def Font::serif
      filename = @@font_base_name[Miyako::getOSName].detect{|base| Font.findFontPath(base[:serif]) }[:serif]
      return Font.new(filename)
    end

    #===Sans Serifフォント(ゴシックフォント)を取得する
    #マルチプラットフォームのソフトを作る際、OS間の差異を吸収するため、共通の名称でフォントインスタンスを取得するときに使う(主にゴシックフォント)
    #返却値:: OSごとに設定されたフォントイン寸タンス(フォントサイズは16)
    def Font::sans_serif
      filename = @@font_base_name[Miyako::getOSName].detect{|base| Font.findFontPath(base[:sans_serif]) }[:sans_serif]
      return Font.new(filename)
    end

    def Font::system_font #:nodoc:
      return Font.serif
    end
  end
end
