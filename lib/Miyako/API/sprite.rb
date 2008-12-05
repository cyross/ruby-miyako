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

# スプライト関連クラス群
module Miyako
  #==スプライト管理クラス
  class Sprite
    include SpriteBase
    include Animation
    include Layout
    include SingleEnumerable
    extend Forwardable

    attr_reader :alpha     #スプライト全体のα値(非αチャネル)を取得する。値は0～255の整数
    attr_reader :tr_color  #カラーキーが有向になっている場合のRGB値。[R,G,B]の配列(各要素は0～255の整数)
    attr_reader :type      #画像の透明度・透過タイプを取得する(詳細はSprite.newメソッドを参照)

    @@abb = {:ck => :color_key, :as => :alpha_surface, :ac => :alpha_channel}

    def setup #:nodoc:
      @unit = SpriteUnitFactory.create
      @alpha = 255
      @aa = false
      @tr_color = Color[:black]
      @update = nil
      @w = 0
      @h = 0
      @draw_list = nil
    end

    private :setup

    #===インスタンス生成
    #スプライトをファイルや画像サイズから生成します。
    #
    #v1.5以前は、ファイルからスプライトを生成するときは、ファイル名で画像が共有されていましたが、
    #v2.0では廃止されました。
    #
    #_param_:: 各種設定(ハッシュ引数。詳細は後述)
    #返却値:: 生成したインスタンス
    #
    #<引数の内容>
    #* 1.画像の元データ(括弧内は省略形)。以下の３種類のどれかを必ず指定する。
    #  * 画像ファイル(ファイル名)から生成。　(書式):filename(:file)=>画像ファイル名　(例):file=>"image.png"
    #  * 画像サイズ(2要素の整数の配列もしくはSize構造体)から生成。　(書式1):size=>２要素の配列((例):size=>[100,100])　(書式2):size=>Size構造体((例):size=>Size.new(100,100))
    #  * SDL::Surfaceクラスのインスタンスから生成。　(書式):bitmap(:bmp)=>SDL::Surfaceクラスのインスタンス((例):bmp=>@surface)
    #  * SpriteUnit構造体のインスタンスから生成(ビットマップ以外のUnitの値は引き継がれる。しかし、snapの親子関係は引き継がれない)。
    #　(書式):unit=>SpriteUnit構造体のインスタンス((例):unit=>@spr.to_unit)
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
        bitmap = Bitmap.load(param[:filename] || param[:file])
      elsif param.has_key?(:unit)
        bitmap = param[:unit].bitmap
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
        # カラーキーのα値を0にしたビットマップを作成
        tbitmap = bitmap.display_format
        tunit   = SpriteUnitFactory.create(:bitmap => tbitmap)
        bitmap  = Bitmap.create(bitmap.w, bitmap.h, SDL::HWSURFACE)
        bitmap  = bitmap.display_format_alpha
        nunit = SpriteUnitFactory.create(:bitmap => bitmap)
        Bitmap.ck_to_ac!(tunit, nunit, @tr_color)
        self.bitmap = bitmap
        @unit.bitmap.fill_rect(0,0,@unit.bitmap.w,@unit.bitmap.h,[0, 0, 0, 0]) if param[:is_fill]
        tbitmap = nil
      when :alpha_surface
        bitmap.setAlpha(SDL::SRCALPHA|SDL::RLEACCEL, param[:alpha]) 
        self.bitmap = bitmap.display_format
      when :alpha_channel
        self.bitmap = bitmap.display_format_alpha
        @unit.bitmap.fill_rect(0,0,@unit.bitmap.w,@unit.bitmap.h,[0, 0, 0, 0]) if param[:is_fill]
      when :movie
        self.bitmap = bitmap.display_format
      end
      @type = param[:type]

      if param.has_key?(:unit)
        @unit.ow = param[:unit].ow
        @unit.oh = param[:unit].oh
        self.move_to(param[:unit].x, param[:unit].y)
        @unit.dx = param[:unit].dx
        @unit.dy = param[:unit].dy
        @unit.angle = param[:unit].angle
        @unit.px = param[:unit].px
        @unit.py = param[:unit].py
        @unit.qx = param[:unit].qx
        @unit.qy = param[:unit].qy
      end
    end

    def_delegators(:@unit, :ox, :oy, :ow, :oh, :x, :y)

    def update_layout_position #:nodoc:
      @unit.move_to(*@layout.pos)
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
      set_layout_size(@unit.ow, @unit.oh)
    end

    #===画像全体を指定の色で塗りつぶす
    #_color_:: 塗りつぶす色。Color.to_rgbメソッドのパラメータでの指定が可能
    #返却値:: 自分自身を返す
    def fill(color)
      @unit.bitmap.fill_rect(0,0,self.w,self.h,Color.to_rgb(color))
      return self
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
      set_layout_size(v, @unit.oh)
    end

    #===画像の表示高を指定する
    #ohを指定すると、縦方向の一部のみ表示される。
    #_v_:: 表示高。整数で指定
    def oh=(v)
      @unit.oh = v
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

    #===画像を解放する
    #内部で使用しているデータをインスタンスから解放する
    def dispose
      layout_dispose
      @unit.bitmap = nil
      @unit = nil
    end

    #===インスタンスをSpriteUnit構造体化する
    #返却値:: SpriteUnit化したスプライト
    def to_unit
      return @unit.dup
    end

    #===インスタンスをスプライト化して返す
    #返却値:: 自分自身を返す
    def to_sprite
      return self
    end

    #===インスタンスの複製を行う(画像インスタンスも複製)
    #返却値:: 自分自身の複製を返す
    def duplicate
      unit = @unit.dup
      unit.bitmap = Bitmap.create(unit.bitmap.w, unit.bitmap.h)
      Bitmap.blit_aa!(@unit, unit, 0, 0)
      return Sprite.new(:unit=>unit, :type=>:ac)
    end

    #===画面に描画を指示する
    #現在の画像を、現在の状態で描画するよう指示する
    #但し、実際に描画されるのはScreen.renderメソッドが呼び出された時
    #返却値:: 自分自身を返す
    def render
      Screen.render_screen(@unit.dup)
      return self
    end
    
    #===画面に描画を指示する(回転/拡大/縮小付き)
    #現在の画像を、回転/拡大/縮小を付けながら描画するよう指示する
    #描画時、スプライトのow,ohを無視することに注意する(ow=w,oh=hのときのみ想定通りの結果が出る)
    #但し、実際に描画されるのはScreen.renderメソッドが呼び出された時
    #params:: 描画パラメータ。省略時はnil
    #返却値:: 自分自身を返す
    def render_transform
      unit = @unit.dup
      Bitmap.transform!(unit.bitmap, Screen.screen, 
                        unit.ox, unit.oy, unit.ow, unit.oh, unit.px, unit.py,
                        unit.angle, unit.xscale, unit.yscale)
      return self
    end

    #===スプライトに画像を転送して貼り付ける
    #srcのスプライトの内容を、dstのスプライトに貼り付ける
    #このメソッドは、画面へのrenderと違い、メソッドを呼び出した時点で描画が行われる
    #描画範囲は、転送元は(src.ox,src.oy)-(src.ox+src.ow-1,src.oy+src.oh-1)の範囲のみ有効。転送先は(dst.ox+x,dst.oy+y)-(dst.ox+x+src.ow-1,dst.oy+y+src.oh-1)の範囲で描画される
    #なお、転送後のαチャネルは、転送先のαチャネルの値がそのまま残ること、転送先のow,ohを考慮していない(転送先ow,ohの範囲を超えて転送する)ことに注意する
    #そのため、転送元・転送先スプライトは、αチャネルを使わない画像の方が、想定外の結果にならず好ましい
    #_src_:: 転送元スプライト
    #_dst_:: 転送先スプライト
    #_sx_:: 転送元スプライトの左上位置(src.ox+sxが転送開始位置)
    #_sy_:: 転送元スプライトの左上位置(src.oy+dyが転送開始位置)
    #_w_:: 転送元スプライトの転送幅(src.oxが転送開始位置)
    #_h_:: 転送元スプライトの転送高さ(src.oyが転送開始位置)
    #_dx_:: 転送元スプライトの左上座標にあたる転送先位置(dst.ox+dxが転送開始位置)
    #_dy_:: 転送元スプライトの左上座標にあたる転送先位置(dst.oy+dyが転送開始位置)
    def Sprite::render_sprite(src, dst, sx, sy, w, h, dx, dy)
      loop do 
        begin
          SDL::Surface.blit(src.bitmap, src.ox + sx, src.oy + sy, w, h, dst.bitmap, dst.ox + dx, dst.oy + dy)
          break
        rescue 
        end
      end
    end
    
    #===スプライトに画像を転送して貼り付ける
    #srcのスプライトの内容を、dstのスプライトに貼り付ける
    #転送元画像の指定矩形の中心を軸にして変形した画像を、転送先画像の指定位置を中心として貼り付ける
    #このメソッドは、画面へのrenderと違い、メソッドを呼び出した時点で描画が行われる
    #描画時、双方のスプライトのow,ohを無視することに注意する(双方、ow=w,oh=hのときのみ想定通りの結果が出る)
    #なお、転送後のαチャネルは、転送先のαチャネルの値がそのまま残ることに注意する
    #そのため、転送元・転送先スプライトは、αチャネルを使わない画像の方が、想定外の結果にならず好ましい
    #また、変形元の幅・高さのいずれかが32768以上の時は回転・転送を行わない
    #_src_:: 転送元スプライト
    #_dst_:: 転送先スプライト
    #_x_:: 転送先の位置(中心位置、x方向)
    #_y_:: 転送先の位置(中心位置、y方向)
    #_angle_:: 回転する角度。単位は度(ラジアンではないことに注意。実数)
    #_xscale_:: x軸方向拡大率。実数。-1を指定すると、x軸方向のミラー反転となる
    #_yscale_:: y軸方向拡大率。実数。-1を指定すると、y軸方向のミラー反転となる
    def Sprite::render_sprite_transform(src, dst, angle, xscale, yscale)
      Bitmap.transform!(src.to_unit, dst.to_unit, angle, xscale, yscale)
    end
  end
end
