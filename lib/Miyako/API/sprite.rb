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

# スプライト関連クラス群
module Miyako

  #==スプライト出力情報クラス(構造体)
  SpriteUnit = Struct.new(:dp, :bitmap, :ox, :oy, :ow, :oh, :x, :y, :effect, :viewport)

  #==スプライト出力情報クラス(構造体)
  class SpriteUnit
    #===スプライト出力情報を取得する
    #ダックタイピング用のメソッド
    #返却値:: 自分自身
    def to_unit
      return self
    end
  end
  
  #==ビットマップ(画像)管理クラス
  #SDLのSurfaceクラスインスタンスを管理するクラス
  class Bitmap
    @@cache = Array.new
    @@max_cache_size = 2000
    @@struct = Struct.new("BitmapCache", :key, :bitmap)
    def Bitmap.create(w, h, flag=SDL::HWSURFACE | SDL::SRCCOLORKEY | SDL::SRCALPHA) #:nodoc:
      return SDL::Surface.new(flag, w, h, $miyako_bpp, Screen.screen.Rmask, Screen.screen.Gmask, Screen.screen.Bmask, Screen.screen.Amask)
    end
    def Bitmap.cache(filename) #:nodoc:
      c = @@cache.find{|b| b.key == filename}
      if c
        c = @@cache.delete(c)
        @@cache.push(c)
      else
        c = @@struct.new(filename, SDL::Surface.load(filename))
        @@cache.unshift if @@cache.size == @@max_cache_size
        @@cache.push(c)
      end
      return c.bitmap
    end
    def Bitmap.max_cache_size #:nodoc:
      return @@max_cache_size
    end
    def Bitmap.max_cache_size=(val) #:nodoc:
      @@bitmap_cache = @@bitmap_cache[0..(val-1)] if val < @@bitmap_cache.size
      @@max_cache_size = val
    end
  end

  #==スプライト管理クラス
  class Sprite
    include SpriteBase
    include Animation
    include Layout
    include SingleEnumerable
    include MiyakoTap
    extend Forwardable

    attr_accessor :visible #スプライトの表示状態を取得・設定する
    attr_reader :id        #スプライト固有のID番号を取得する(内部使用)
    attr_reader :alpha     #スプライト全体のα値(非αチャネル)を取得する。値は0～255の整数
    attr_reader :tr_color  #カラーキーが有向になっている場合のRGB値。[R,G,B]の配列(各要素は0～255の整数)
    attr_reader :collision #当たり判定クラス(Collisionクラス)インスタンスを取得する
    attr_reader :type      #画像の透明度・透過タイプを取得する(詳細はSprite.newメソッドを参照)

    @@abb = {:ck => :color_key, :as => :alpha_surface, :ac => :alpha_channel}
    @@sprites = Array.new
    @@idcnt = 1

    def setup #:nodoc:
      @unit = SpriteUnit.new(0, nil, 0, 0, 0, 0, 0, 0, nil, Screen.rect)
      @alpha = 255
      @aa = false
      @tr_color = Color[:black]
      @update = nil
      @w = 0
      @h = 0
      @collision = Collision.new(Rect.new(0, 0, 0, 0), Point.new(0, 0))
      @visible = false
      @draw_list = nil
    end

    private :setup

    def reset_draw_rect #:nodoc:
      @draw_list = {:line    => {:normal => {:solid         => @unit.bitmap.method(:draw_line),
                                             :anti_aliasing => @unit.bitmap.method(:draw_aa_line)},
                                 :fill   => {:solid         => @unit.bitmap.method(:draw_line),
                                             :anti_aliasing => @unit.bitmap.method(:draw_aa_line)}},
                    :rect    => {:normal => {:solid         => @unit.bitmap.method(:draw_rect),
                                             :anti_aliasing => @unit.bitmap.method(:draw_rect)},
                                 :fill   => {:solid         => @unit.bitmap.method(:fill_rect),
                                             :anti_aliasing => @unit.bitmap.method(:fill_rect)}},
                    :circle  => {:normal => {:solid         => @unit.bitmap.method(:draw_circle),
                                             :anti_aliasing => @unit.bitmap.method(:draw_aa_circle)},
                                 :fill   => {:solid         => @unit.bitmap.method(:draw_filled_circle),
                                             :anti_aliasing => @unit.bitmap.method(:draw_aa_filled_circle)}},
                    :ellipse => {:normal => {:solid         => @unit.bitmap.method(:draw_ellipse),
                                             :anti_aliasing => @unit.bitmap.method(:draw_aa_ellipse)},
                                 :fill   => {:solid         => @unit.bitmap.method(:draw_filled_ellipse),
                                             :anti_aliasing => @unit.bitmap.method(:drawAAFilledEllipse)}}}
    end
    
    private :reset_draw_rect

    #===インスタンス生成
    #スプライトをファイルや画像サイズから生成します。
    #
    #ファイルからスプライトを生成するときは、ファイル名で画像が共有されることにご注意ください。
    #
    #（たとえば、画像が共有されているスプライトでは、draw_lineメソッドなどを使って画像が直接変更されると、共有されているスプライトにも影響を与えます）
    #
    #（しかし、dec_alphaメソッドなどで、新しい画像を作成した場合はその限りではありません）
    #
    #ファイルの共有は、”同じファイルパス”であることが条件になっています。
    #
    #（たとえば、同じファイルを指しているファイルとしても、"/home/hoge/game/fuga.png" と "./game/fuga.png" では画像は共有されません。
    #
    #_param_:: 各種設定(ハッシュ引数。詳細は後述)
    #返却値:: 生成したインスタンス
    #
    #<引数の内容>
    #* 1.画像の元データ(括弧内は省略形)。以下の３種類のどれかを必ず指定する。
    #  * 画像ファイル(ファイル名)から生成。　(書式):filename(:file)=>画像ファイル名　(例):file=>"image.png"
    #  * 画像サイズ(2要素の整数の配列もしくはSize構造体)から生成。　(書式1):size=>２要素の配列((例):size=>[100,100])　(書式2):size=>Size構造体((例):size=>Size.new(100,100))
    #  * SDL::Surfaceクラスのインスタンスから生成。　(書式):bitmap(:bmp)=>SDL::Surfaceクラスのインスタンス((例):bmp=>@surface)
    #* 2.透過設定(括弧内は省略形)。以下の３種類のどれかを必ず指定する。
    #  * 画像全体の透明度のみ設定可能。カラーキー・αチャネルの透過は行わない　(書式):type=>:alpha_surface(:as)
    #  * カラーキーの指定。　(書式):type=>:color_key(:ck)　カラーキー指定の方法は以下のとおり
    #    * 透明色にするピクセルの位置(2要素の整数の配列、Point構造体)　(書式1):point=>２要素の配列((例):type=>:ck, :point=>[20,20])　(書式2):point=>Point構造体((例):type=>:ck, :point=>Point.new(20,20))
    #    * 色を直接指定　(書式):tr_color=>色情報(Color.to_rgbメソッドで生成できるパラメータ)((例1):type=>:ck, :tr_color=>[255,0,255] # 紫色を透明色に　(例2):type=>:ck, :tr_color=>:red # 赤色を透明色に)
    #    * デフォルト：画像の[0,0]の位置にあるピクセルの色
    #* 3. αチャネル付き画像を使用(設定変更不可)　(書式):type=>:alpha_channel(:ac)
    def initialize(param)
      raise MiyakoError, "Sprite parameter is not Hash!" unless param.kind_of?(Hash)
      setup
      init_layout

      bitmap = nil
      @tr_color = nil

      param[:type] ||= :color_key
      param[:type] = @@abb[param[:type]] if @@abb.has_key?(param[:type])
      param[:point]  ||= Point.new(0, 0)
      param[:tr_color]  ||= Color[:black]
      param[:alpha] ||= 255
      param[:is_fill] ||= false
      
      if param.has_key?(:bitmap) || param.has_key?(:bmp)
        bitmap = param[:bitmap] || param[:bmp]
      elsif param.has_key?(:size)
        bitmap = Bitmap.create(*(param[:size].to_a))
        param[:is_fill] = true
      elsif param.has_key?(:filename) || param.has_key?(:file)
        bitmap = Bitmap.cache(param[:filename] || param[:file])
      else
        raise MiyakoError, "Illegal Sprite parameter!"
      end

      case param[:type]
      when :color_key
        if param.has_key?(:point)
          @tr_color = Color.to_rgb(bitmap.get_rgb(bitmap.getPixel(*(param[:point].to_a))))
        else
          @tr_color = Color.to_rgb(param[:tr_color])
        end
        @tr_color[3] = 0 unless param[:alpha]
        bitmap.setColorKey(SDL::SRCCOLORKEY|SDL::SRCALPHA|SDL::RLEACCEL, @tr_color)
        bitmap.setAlpha(SDL::SRCALPHA|SDL::RLEACCEL, param[:alpha])
        self.bitmap = bitmap.display_format
        self.alpha  = param[:alpha]
        @unit.bitmap.fill_rect(0,0,@unit.bitmap.w,@unit.bitmap.h,[0, 0, 0, 0]) if param[:is_fill]
      when :alpha_surface
        bitmap.setAlpha(SDL::SRCALPHA|SDL::RLEACCEL, param[:alpha]) 
        self.bitmap = bitmap.display_format
        self.alpha  = param[:alpha]
      when :alpha_channel
        self.alpha  = nil
        self.bitmap = bitmap.display_format_alpha
        @unit.bitmap.fill_rect(0,0,@unit.bitmap.w,@unit.bitmap.h,[0, 0, 0, 0]) if param[:is_fill]
      when :movie
        self.alpha  = nil
        self.bitmap = bitmap.display_format
      end
      @type = param[:type]

      reset_draw_rect

      @id = @@idcnt
      @@idcnt = @@idcnt + 1
      @@sprites.push(self)
    end

    def_delegators(:@unit, :ox, :oy, :ow, :oh, :x, :y, :effect, :effect=, :dp)

    def update_layout_position #:nodoc:
      @unit.x = @layout.pos[0]
      @unit.y = @layout.pos[1]
      @collision.pos.x = @unit.x
      @collision.pos.y = @unit.y
    end

    #===画像の幅を取得する
    #返却値:: 画像の幅(ピクセル)
    def w
      return @unit.bitmap.w
    end

    #===画像の高さを取得する
    #返却値:: 画像の高さ(ピクセル)
    def h
      return @unit.bitmap.h
    end

    def bitmap #:nodoc:
      return @unit.bitmap
    end

    def bitmap=(bmp) #:nodoc:
      @unit.bitmap = bmp
      @unit.ow = @unit.bitmap.w
      @unit.oh = @unit.bitmap.h
      @w = @unit.bitmap.w
      @h = @unit.bitmap.h
      @collision.rect.w = @unit.ow
      @collision.rect.h = @unit.oh
      set_layout_size(@unit.ow, @unit.oh)
      reset_draw_rect
    end

    #===画像全体を指定の色で塗りつぶす
    #_color_:: 塗りつぶす色。Color.to_rgbメソッドのパラメータでの指定が可能
    #返却値:: 自分自身を返す
    def fill(color)
      @draw_list[:rect][:fill][:solid][0,0,self.w,self.h,Color.to_rgb(color)]
      return self
    end

    #===画像内に直線を引く
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normal固定。
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def draw_line(rect, color, attribute = :normal, aa = :solid)
      color = Color.to_rgb(color)
      @draw_list[:line][attribute][aa][*(rect.to_a << color)] if @draw_list[:line][attribute] && @draw_list[:line][attribute][aa]
      return self
    end

    #===画像内に矩形を描画する
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normalで縁のみ描画、:fillで内部も塗りつぶす
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def draw_rect(rect, color, attribute = :normal, aa = :solid)
      color = Color.to_rgb(color)
      @draw_list[:rect][attribute][aa][*(rect.to_a << color)] if @draw_list[:rect][attribute] && @draw_list[:rect][attribute][aa]
      return self
    end

    #===画像内に円を描画する
    #_point_:: 中心の位置。2要素の整数の配列、もしくはPoint構造体を使用可能
    #_r_:: 円の半径。整数を使用可能。
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normalで縁のみ描画、:fillで内部も塗りつぶす
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def draw_circle(point, r, color, attribute = :normal, aa = :solid)
      color = Color.to_rgb(color)
      @draw_list[:circle][attribute][aa][*(point.to_a << r << color)] if @draw_list[:circle][attribute] && @draw_list[:circle][attribute][aa]
      return self
    end

    #===画像内に楕円を描画する
    #_rect_:: 描画する矩形。画像の左上を[0,0]とする。4要素の整数の配列かRect構造体を使用
    #_color_:: 描画色。Color.to_rgbメソッドのパラメータでの指定が可能
    #_attribute_:: 描画の属性。:normalで縁のみ描画、:fillで内部も塗りつぶす
    #_aa_:: アンチエイリアスの指定。:solidでオフ、:anti_aliasingでオン
    #返却値:: 自分自身を返す
    def draw_ellipse(rect, color, attribute = :normal, aa = :solid)
      color = Color.to_rgb(color)
      @draw_list[:ellipse][attribute][aa][*(rect.to_a << color)] if @draw_list[:ellipse][attribute] && @draw_list[:ellipse][attribute][aa]
    end

    #===スプライトの透明度(画像全体)を設定する
    #画像全体の透明度を設定する。0で透明、255で完全不透明になる。
    #
    #但し、スプライトがαチャネルを持つ場合(Sprite.newの引数で:type=>:acを指定している場合)は、何も行われない
    #_val_:: 透明度。0?255までの整数
    def alpha=(val)
      return unless @alpha
      @alpha = val
      if @alpha
        @unit.bitmap.setAlpha(SDL::SRCALPHA|SDL::RLEACCEL, @alpha)
        @unit.bitmap = @unit.bitmap.display_format
      end
    end

    #===画像の表示順を指定する。
    #画像の表示順を指定する。値が大きくなるごとに前面に表示する
    #
    #ただし、renderメソッドを使用している場合はこのメソッドの効果は無視される
    #_val_:: 画像の表示順。整数を指定
    #返却値:: あとで書く
    def dp=(val)
      odp = @unit.dp
      @unit.dp = val
    end

    #===画像の表示開始位置(X座標)を指定する
    #oxを指定すると、表示の左上位置が変更される。
    #_v_:: 表示開始位置。整数で指定
    def ox=(v)
      @unit.ox = v
    end
    
    #===画像の表示開始位置(Y座標)を指定する
    #oyを指定すると、表示の左上位置が変更される。
    #_v_:: 表示開始位置。整数で指定
    def oy=(v)
      @unit.oy = v
    end
    
    #===画像の表示幅を指定する
    #owを指定すると、横方向の一部のみ表示される。
    #_v_:: 表示幅。整数で指定
    def ow=(v)
      @unit.ow = v
      @collision.rect.w = @unit.ow
      set_layout_size(v, @unit.oh)
    end

    #===画像の表示高を指定する
    #ohを指定すると、縦方向の一部のみ表示される。
    #_v_:: 表示高。整数で指定
    def oh=(v)
      @unit.oh = v
      @collision.rect.h = @unit.oh
      set_layout_size(@unit.ow, v)
    end

    #===画像の表示矩形を取得する
    #画像が表示されているときの矩形を取得する。矩形は、[x,y,ow,oh]で取得する。
    #返却値:: 生成された矩形
    def rect
      return Rect.new(@unit.x, @unit.y, @unit.ow, @unit.oh)
    end

    def update  #:nodoc:
      @update.call(self) if @update
      yield self if block_given?
      return self
    end

    def update=(u) #:nodoc:
      @update = u
    end

    #===画像が表示されている状態をフラグ形式で取得する
    #返却値:: 表示状態のときはtrue、非表示状態のときはfalseを返す
    def visible?
      return @visible
    end

    #===画像を表示する
    #Screen.updateメソッドを使用して画面を更新するときに画像を画面に描画する。
    #
    #ただし、renderメソッドを使用している場合はこのメソッドの効果は無視される
    #返却値:: 自分自身を返す
    def show
      org_visible = @visible
      @visible = true
      if block_given?
        res = Proc.new.call
        hide unless org_visible
        return res
      end
      return self
    end

    #===画像を表示しない
    #Screen.updateメソッドを使用して画面を更新するときに画像を画面に描画しない。
    #
    #ただし、renderメソッドを使用している場合はこのメソッドの効果は無視される
    #返却値:: 自分自身を返す
    def hide
      @visible = false
      return self
    end

    #===ビューポートを取得する
    #ビューポート(画像の画面内での表示範囲。Rect構造体)を取得する
    #返却値:: ビューポート(Rect構造体)
    def viewport
      return @unit.viewport
    end
    
    #===ビューポートを設定する
    #ビューポート(Rect構造体)を設定する
    #_vp_:: ビューポート(Rect構造体)
    #返却値:: 自分自身を帰す
    def viewport=(vp)
      @layout.viewport = vp
      @unit.viewport = vp
      return self
    end
    
    #===画像を解放する
    #内部で使用しているデータをインスタンスから解放する
    def dispose
      layout_dispose
      @@sprites.delete(self)
      @unit.bitmap = nil
    end

    #===インスタンスをSpriteUnit構造体化する
    #返却値:: SpriteUnit化したスプライト
    def to_unit
      return @unit
    end

    #===インスタンスをスプライト化して返す
    #返却値:: 自分自身を返す
    def to_sprite
      return self
    end

    #===画面に描画を指示する
    #現在の画像を、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      Screen.sprite_list.push(@unit)
      return self
    end

    #===画像を回転させる
    #画像を回転させる。回転後の中心は画像の中心に固定している。
    #
    #is_force引数がfalseのとき、回転する際の画像の削れを防止するため、回転後の画像の大きさが、長辺の1.5倍の正方形になることに注意。
    #
    #_radian_:: 回転する角度。ラジアン単位。0<=radian<2πの間に指定する
    #_is_force_:: trueを指定すると、画像を回転させる際に、画像の大きさを変えない。但し、返還後の画像が崩れる恐れがある
    #返却値:: 回転させたあとの画像を持つSpriteクラスのインスタンス
    def rotate(radian, is_force = false)
      return Sprite.new(:bitmap=>self.bitmap.miyako_rotate(radian, is_force), :type=>@type)
    end
    
    #===画像を拡大・縮小・反転させる
    #画像の大きさを変更・反転させる。
    #
    #値::効果
    #1.0<scale:: 拡大
    #scale==1.0:: 等倍
    #0<scale<1.0:: 縮小
    #scale==0.0:: 等倍
    #scale<0.0:: 反転(scale==-1.0のときはミラー反転)
    #
    #但し、変換の結果、大きさが0ピクセルになる場合(もともと0ピクセルの場合)や、
    #32768ピクセル以上になる場合(もともと32768ピクセル以上)のときは、返還前のスプライトを返す
    #_sc_x_:: X軸拡大率(実数で指定)
    #_sc_y_:: Y軸拡大率(実数で指定)
    #返却値:: 変換したあとのSpriteクラスのインスタンス
    def scale(sc_x, sc_y)
      return Sprite.new(:bitmap=>self.bitmap.miyako_scale(sc_x, sc_y), :type=>@type)
    end
    
    #===画像を回転・拡大・縮小・反転させる
    #引数・返却値はSprite#rotate, Sprite#scaleメソッドを参照。
    def transform(radian, sc_x, sc_y, is_force = false)
      return Sprite.new(:bitmap=>self.bitmap.miyako_transform(radian, sc_x, sc_y, is_force), :type=>@type)
    end
    
    #===画像の色相を変換する
    #画像の色相を、色相環を元に変換させる。
    #
    #返還後のイメージは、各種書籍や情報を参照
    #_radian_:: 色相の変換角度。0<=radian<2PIの間に指定する
    #返却値:: 色相を変換したあとのSpriteクラスのインスタンス
    def hue(radian)
      return Sprite.new(:bitmap=>self.bitmap.miyako_hue(radian), :type=>@type)
    end
    
    #===画像の彩度を変換する
    #画像の彩度を、割合で補正する。
    #
    #0.0?1.0の間の少数を設定する。変換の結果、範囲外になるときは、範囲内に丸める(0.0もしくは1.0に丸める)
    #_value_:: 補正する値。0.0?1.0の間の実数
    #返却値:: 変換したあとのSpriteクラスのインスタンス
    def saturation(value)
      return Sprite.new(:bitmap=>self.bitmap.miyako_saturation(value), :type=>@type)
    end
    
    #===画像の明度を変換する
    #画像の明度を、割合で補正する。
    #
    #0.0?1.0の間の少数を設定する。変換の結果、範囲外になるときは、範囲内に丸める(0.0もしくは1.0に丸める)
    #_value_:: 補正する値。0.0?1.0の間の実数
    #返却値:: 変換したあとのSpriteクラスのインスタンス
    def value(value)
      return Sprite.new(:bitmap=>self.bitmap.miyako_value(value), :type=>@type)
    end
    
    #===画像の色相・彩度・明度を変換する
    #画像の色相を、色相環を元に変換、彩度・明度を、割合で補正する。
    #
    #_hue_:: 色相の変換角度。0<=radian<2PIの間に指定する
    #_saturaiton_:: 補正する彩度値。0.0?1.0の間の実数
    #_value_:: 補正する明度値。0.0?1.0の間の実数
    #返却値:: 変換したあとのSpriteクラスのインスタンス
    def hsv(hue, saturation, value)
      return Sprite.new(:bitmap=>self.bitmap.miyako_hsv(hue, saturation, value), :type=>@type)
    end

    def Sprite::clear #:nodoc:
      @@sprites.clear
    end
    
    def update_sprite #:nodoc:
      Screen.sprite_list.push(@unit) if @visible
    end
    
    def Sprite::update_sprite #:nodoc:
      @@sprites.compact.each{|s| s.update_sprite }
    end
    
    def Sprite::get_list #:nodoc:
      ulist = Array.new
      @@sprites.compact!
      @@sprites.each{|s|
        if s.visible
          s.update
          ulist.push(s.to_unit)
        end
      }
      return ulist
    end
    
    def Sprite::recalc_layout #:nodoc:
      @@sprites.compact!
      @@sprites.each{|s| s.calc_layout }
    end
    
    def Sprite::reset_viewport #:nodoc:
      @@sprites.compact!
      @@sprites.each{|s| s.viewport = Screen.rect }
    end
  end
end
