# encoding: utf-8
=begin
--
Miyako v2.1
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
  class Font
    include SpriteBase
    include Animation
    include Layout
    extend Forwardable

#    OS_MAC_OS_X = "mac_osx"
#    ORG_ENC = "UTF-8"
#    NEW_ENC = "UTF-8-MAC"

    attr_reader :size, :line_skip, :height, :ascent, :descent, :text
    attr_accessor :color, :use_shadow, :shadow_color, :shadow_margin, :vspace, :hspace

    @@font_cache = {}

    @@name_2_font_path = Hash.new

    # check font directory in gem directory
    base_pathes = []
    gpath = nil
    searcher = Gem::GemPathSearcher.new
    spec = searcher.find("miyako")
    gpath = spec.full_gem_path if spec
    if spec && gpath =~ /ruby\-miyako/
      gpath = File.join(gpath,"lib","Miyako","fonts")
      base_pathes << gpath if File.exist?(gpath)
    end

    # check font directory in library(site_ruby) directory
    lpath = $LOAD_PATH.find{|path| File.exist?(File.join(path,"Miyako","fonts")) }
    base_pathes << File.join(lpath,"Miyako","fonts") if lpath
    
    @@font_base_path = Hash.new
    @@font_base_path["win"] = base_pathes + (ENV['SystemRoot'] ? ["./", File.join(ENV['SystemRoot'], "fonts")] : ["./"])
    @@font_base_path["linux"] = base_pathes + ["./", "/usr/share/fonts/", "/usr/X11R6/lib/X11/fonts/"]
    @@font_base_path["mac_osx"] = base_pathes + ["./",
                                      "~/Library/Fonts/", "/Library/Fonts/", "/System/Library/Fonts/"]

    @@font_base_name = Hash.new
    @@font_base_name["win"] = [{:serif=>"ume-tms3.ttf", :sans_serif=>"umeplus-gothic.ttf"}]
    @@font_base_name["linux"] = [{:serif=>"ume-tms3.ttf", :sans_serif=>"umeplus-gothic.ttf"}]
    @@font_base_name["mac_osx"] = [{:serif=>"ume-tms3.ttf", :sans_serif=>"umeplus-gothic.ttf"}]
    @@initialized = false

    def Font.init
      raise MiyakoError, "Already initialized!" if @@initialized
      SDL::TTF.init
      Font.create_font_path
      @@initialized = true
    end

    def Font.initialized?
      @@initialized
    end

    def Font.search_font_path_file(hash, path) #:nodoc:
      Dir.glob(File.join(path,"*")){|d|
        hash = Font.search_font_path_file(hash, d) if test(?d, d)
        if Miyako.getOSName == "win" and RUBY_VERSION >= '1.9.0' and RUBY_VERSION < '1.9.2'
          d.force_encoding(Encoding::WINDOWS_31J)
        end
        d = d.encode(Encoding::UTF_8)
        fname = File.split(d)[1]
#        puts fname
#        puts fname.encoding
        hash[fname] = d if (fname =~ /\.tt[fc]\z/ || fname =~ /\.otf\z/) # for MacOSX
      }
      return hash
    end

    def Font.create_font_path #:nodoc:
      osn = Miyako::getOSName
      @@font_base_path[osn].each{|path|
        @@name_2_font_path = Font.search_font_path_file(@@name_2_font_path, path)
      }
    end

    def Font.findFontPath(fname) #:nodoc:
      fname = fname.encode(Encoding::UTF_8)
      return @@name_2_font_path.fetch(fname, nil)
    end

    def Font.get_font_inner(fname, fpath, size=16) #:nodoc:
      if Miyako.getOSName == "win" and RUBY_VERSION >= '1.9.0' and RUBY_VERSION < '1.9.2'
        fname.force_encoding(Encoding::WINDOWS_31J)
        fpath.force_encoding(Encoding::WINDOWS_31J)
      end
      fname = fname.encode(Encoding::UTF_8)
      fpath = fpath.encode(Encoding::UTF_8)
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

    def initialize(fname, size=16)
      init_layout
      @size = size
      @color = [255, 255, 255]
      @fname = fname
      @vspace = 0
      @hspace = 0
      @bold = false
      @italic = false
      @under_line = false
      @fpath = Font.findFontPath(@fname) or raise MiyakoIOError.new(@fname)
      @font = Font.get_font_inner(@fname, @fpath, @size)
      @font.style = SDL::TTF::STYLE_NORMAL
      init_height
      @use_shadow = false
      @shadow_color = [128, 128, 128]
      @shadow_margin = [2, 2]
      @unit = SpriteUnitFactory.create
      @text = ""
      @visible = true
      set_layout_size(*self.text_size(@text))
    end

    def initialize_copy(obj) #:nodoc:
      @size = @size.dup
      @color = @color.dup
      @fname = @fname.dup
      @fpath = @fpath.dup
      @shadow_color = @shadow_color.dup
      @shadow_margin = @shadow_margin.dup
      @unit = @unit.dup
      @text = @text.dup
    end

    def visible
      return @visible
    end

    def visible=(v)
      @visible = v
      return self
    end

    def text=(str)
      @text = str.to_s
      @text = @text.encode(Encoding::UTF_8)
      set_layout_size(*self.text_size(@text))
      return self
    end

    def size=(sz)
      @size = sz
      @font = Font.get_font_inner(@fname, @fpath, @size)
      @font.style = (@bold ? SDL::TTF::STYLE_BOLD : 0) |
                    (@italic ? SDL::TTF::STYLE_ITALIC : 0) |
                    (@under_line ? SDL::TTF::STYLE_UNDERLINE : 0)
      init_height
      set_layout_size(*self.text_size(@text))
      return self
    end

    def size_during(sz)
      raise MiyakoError, "not given block!" unless block_given?
      tsize = @size
      self.size = sz
      yield
      self.size = tsize
      return self
    end

    def color_during(color)
      raise MiyakoError, "not given block!" unless block_given?
      tcolor, self.color = @color, color
      yield
      self.color = tcolor
      return self
    end

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

    def get_fit_size(size)
      path = Font.findFontPath(@fname)
      font = SDL::TTF.open(path, size)
      return (size.to_f * (size.to_f / font.line_skip.to_f)).to_i
    end

    def line_height
      return @line_skip + @vspace + (@use_shadow ? @shadow_margin[1] : 0)
    end

    def dispose
      @font = nil
    end

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

    def bold?
      return @bold
    end

    def bold=(f)
      @bold = f
      @font.style |= SDL::TTF::STYLE_BOLD
      @font.style -= SDL::TTF::STYLE_BOLD unless @bold
      return self
    end

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

    def italic?
      return @italic
    end

    def italic=(f)
      @italic = f
      @font.style |= SDL::TTF::STYLE_ITALIC
      @font.style -= SDL::TTF::STYLE_ITALIC unless @italic
      return self
    end

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

    def under_line?
      return @under_line
    end

    def under_line=(f)
      @under_line = f
      @font.style |= SDL::TTF::STYLE_UNDERLINE
      @font.style -= SDL::TTF::STYLE_UNDERLINE unless @under_line
      return self
    end

    def normal
      @font.style = 0
      return self
    end

    def draw_text(dst, str, x, y)
      str = str.encode(Encoding::UTF_8)
      str.chars{|c|
        if @use_shadow
          src2 = @font.renderBlendedUTF8(c, @shadow_color[0], @shadow_color[1], @shadow_color[2])
          if src2
            SpriteUnitFactory.apply(@unit, {:bitmap=>src2, :ow=>src2.w, :oh=>src2.h})
            Miyako::Bitmap.blit_aa(@unit, dst.to_unit, x+@shadow_margin[0], y+@shadow_margin[1])
          else
            break x
          end
        end
        src = @font.renderBlendedUTF8(c, @color[0], @color[1], @color[2])
        if src
          SpriteUnitFactory.apply(@unit, {:bitmap=>src, :ow=>src.w, :oh=>src.h})
          Miyako::Bitmap.blit_aa(@unit, dst.to_unit, x, y)
        else
          break x
        end
        x += chr_size_inner(c)
      }
      return x
    end

    def render
      return self unless @visible
      draw_text(Screen, @text, @layout[:pos][0], @layout[:pos][1])
      return self
    end

    def render_to(dst)
      return self unless @visible
      draw_text(dst, @text, @layout[:pos][0], @layout[:pos][1])
      return self
    end

    def render_xy(x, y)
      return self unless @visible
      draw_text(Screen, @text, x, y)
      return self
    end

    def render_xy_to(dst, x, y)
      return self unless @visible
      draw_text(dst, @text, x, y)
      return self
    end

    def render_str(text)
      return self unless @visible
      draw_text(Screen, text.to_s, @layout[:pos][0], @layout[:pos][1])
      return self
    end

    def render_str_to(dst, text)
      return self unless @visible
      draw_text(dst, text.to_s, @layout[:pos][0], @layout[:pos][1])
      return self
    end

    def chr_size_inner(char)
      return (char.bytesize == 1 ? @size >> 1 : @size) + (@use_shadow ? @shadow_margin[0] : 0) + @hspace
    end

    private :chr_size_inner

    def text_size(txt)
      width = txt.chars.inject(0){|r, c|
        r += (c.bytesize == 1 ? @size >> 1 : @size) } +
             ((@use_shadow ? @shadow_margin[0] : 0) + @hspace) * (txt.chars.to_a.length - 1)
      return [width, self.line_height]
    end

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

    def Font::serif
      filename = @@font_base_name[Miyako::getOSName].detect{|base| Font.findFontPath(base[:serif]) }[:serif]
      return Font.new(filename)
    end

    def Font::sans_serif
      filename = @@font_base_name[Miyako::getOSName].
                   detect{|base|
                     Font.findFontPath(base[:sans_serif])
                   }[:sans_serif]
      return Font.new(filename)
    end

    def Font::system_font #:nodoc:
      return Font.serif
    end
  end
end
