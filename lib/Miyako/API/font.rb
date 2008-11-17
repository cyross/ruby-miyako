=begin
--
Miyako v1.5
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

# フォント関連クラス(群)
module Miyako

=begin rdoc
==フォント管理クラス
=end
  class Font
    include MiyakoTap
    extend Forwardable

    attr_reader :size, :line_skip, :height, :ascent, :descent
    attr_accessor :color, :use_shadow, :shadow_color, :shadow_margin, :vspace, :draw_type

    @@font_cache = {}

    @@name_2_font_path = Hash.new

    @@font_base_path = Hash.new
    @@font_base_path["win"] = ENV['SystemRoot'] ? ["./", ENV['SystemRoot'].tr("\\", "/") + "/fonts/"] : ["./"]
    @@font_base_path["linux"] = ["./", "/usr/share/fonts/", "/usr/X11R6/lib/X11/fonts/"]
    @@font_base_path["mac_osx"] = ["./", "~/Library/Fonts/", "/Library/Fonts/", "/System/Library/Fonts/",
                                      "/ライブラリ/Fonts/", "/システム/ライブラリ/Fonts/"]

    @@font_base_name = Hash.new
    @@font_base_name["win"] = [{:serif=>"msmincho.ttc", :sans_serif=>"meiryo.ttc"},
                               {:serif=>"msmincho.ttc", :sans_serif=>"msgothic.ttc"},
                               {:serif=>"VL-Gothic-Regular.ttf", :sans_serif=>"VL-Gothic-Regular.ttf"},
                               {:serif=>"umeplus-gothic.ttf", :sans_serif=>"umeplus-gothic.ttf"}]
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
        d = Iconv.conv("UTF-8-MAC", "UTF-8", d.toutf8) if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
        d = d.tr("\\", "\/")
        hash[$1] = d if (d =~ /\/([^\/\.]+\.tt[fc])\z/ || d =~ /\/([^\/\.]+\.otf)\z/) # MacOSX対応
      }
      return hash
    end

    def Font.create_font_path #:nodoc:
      osn = Miyako::getOSName
      @@font_base_path[osn].each{|path|
        path = Iconv.conv("UTF-8-MAC", "UTF-8", path.toutf8) if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
        path = path.tr("\\", "\/")
        @@name_2_font_path = Font.search_font_path_file(@@name_2_font_path, path)
      }
    end

    def Font.findFontPath(fname) #:nodoc:
      fname = Iconv.conv("UTF-8-MAC", "UTF-8", fname.toutf8) if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
      return @@name_2_font_path.fetch(fname, nil)
    end

    def Font.get_font_inner(fname, fpath, size=16) #:nodoc:
      if Miyako.getOSName == "mac_osx" # MacOSXはパス名がUTF-8固定のため
        fname = Iconv.conv("UTF-8-MAC", "UTF-8", fname.toutf8)
        fpath = Iconv.conv("UTF-8-MAC", "UTF-8", fpath.toutf8)
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
    #_fname_:: フォントファイル名(フォントファミリー名不可)。システムフォントのときはディレクトリ指定不要
    #_size_:: フォントの大きさ。単位はピクセル。デフォルトは 16
    #返却値:: 生成されたインスタンスを返す
    def initialize(fname, size=16)
      @size = size
      @color = [255, 255, 255]
      @fname = fname
      @vspace = 0
      @bold = false
      @italic = false
      @under_line = false
      @draw_type = :mild
      @fpath = Font.findFontPath(@fname) or raise MiyakoError, "Cannot Find Font! : #{@fname}"
      @font = Font.get_font_inner(@fname, @fpath, @size)
      @font.style = SDL::TTF::STYLE_NORMAL
      init_height
      @draw_text = {:solid => self.method(:_draw_text), :mild => self.method(:_draw_text_mild)}
      @use_shadow = false
      @shadow_color = [128, 128, 128]
      @shadow_margin = [2, 2]
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
    #返却値:: 自分自身
    def bold
      self.bold = true
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
    #返却値:: 自分自身
    def italic
      self.italic = true
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
    #返却値:: 自分自身
    def under_line
      self.under_line = true
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
      str = str.toutf8
      str = Iconv.conv("UTF-8-MAC", "UTF-8", str) if Miyako.getOSName == "mac_osx"
      return @draw_text[@draw_type][dst, str, x, y]
    end
    
    def _draw_text(dst, str, x, y) #:nodoc:
      @font.drawSolidUTF8(dst.bitmap, str, x + @shadow_margin[0], y + @shadow_margin[1], @shadow_color[0], @shadow_color[1], @shadow_color[2]) if @use_shadow
      @font.drawSolidUTF8(dst.bitmap, str, x, y, @color[0], @color[1], @color[2])
      return x + @font.textSize(str)[0]
    end

    def _draw_text_mild(dst, str, x, y) #:nodoc:
      #αチャネルを持たないときは、直接描画
      #αチャネルを持つときは、いったん中間画像に描画する
      if dst.alpha
        @font.drawBlendedUTF8(dst.bitmap, str, x + @shadow_margin[0], y + @shadow_margin[1], @shadow_color[0], @shadow_color[1], @shadow_color[2]) if @use_shadow
        @font.drawBlendedUTF8(dst.bitmap, str, x, y, @color[0], @color[1], @color[2])
      else
        src = @font.renderBlendedUTF8(str, @color[0], @color[1], @color[2])
        if src
         if @use_shadow
            src2 = @font.renderBlendedUTF8(str, @shadow_color[0], @shadow_color[1], @shadow_color[2])
            src2 = Miyako::Bitmap.miyako_blit_aa(src, src2, @shadow_margin[0], @shadow_margin[1])
         else
            src2 = src
         end
          dst.bitmap = Miyako::Bitmap.miyako_blit_aa2(src2, dst.bitmap, x, y)
        else
          return x
        end
      end
      return x + @font.textSize(str)[0]
    end

    #===文字列描画したときの大きさを取得する
    #現在のフォントの設定で指定の文字列を描画したとき、予想される描画サイズを返す。実際に描画は行われない。
    #_txt_:: 算出したい文字列
    #返却値:: 文字列を描画したときの大きさ([w,h]の配列)
    def text_size(txt)
      return @font.textSize(txt)
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
