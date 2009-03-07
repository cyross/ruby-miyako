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

# スプライト関連クラス群
module Miyako
  #==スプライト管理クラス
  class Sprite
    include SpriteBase
    include Animation
    include Layout
    include SingleEnumerable
    extend Forwardable

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
    attr_reader :tr_color  #カラーキーが有向になっている場合のRGB値。[R,G,B]の配列(各要素は0～255の整数)
    attr_reader :type      #画像の透明度・透過タイプを取得する(詳細はSprite.newメソッドを参照)

    @@abb = {:ck => :color_key, :as => :alpha_surface, :ac => :alpha_channel}

    def setup #:nodoc:
      @unit = SpriteUnitFactory.create
      @aa = false
      @tr_color = Color[:black]
      @update = nil
      @w = 0
      @h = 0
      @draw_list = nil
      @visible = true
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
    #  * カラーキーによる透過は行わない方式(デフォルトの方式)　(書式):type=>:alpha_surface(:as)
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
        # カラーキーのα値を0にしたビットマップを作成
        tbitmap = bitmap.display_format
        tunit   = SpriteUnitFactory.create(:bitmap => tbitmap)
        bitmap  = Bitmap.create(bitmap.w, bitmap.h, SDL::HWSURFACE)
        bitmap  = bitmap.display_format_alpha
        nunit = SpriteUnitFactory.create(:bitmap => bitmap)
        Bitmap.normal_to_ac!(tunit, nunit)
        self.bitmap = bitmap
        @unit.bitmap.fill_rect(0,0,@unit.bitmap.w,@unit.bitmap.h,[0, 0, 0, 0]) if param[:is_fill]
        tbitmap = nil
      when :alpha_channel
        self.bitmap = bitmap.display_format_alpha
        @unit.bitmap.fill_rect(0,0,@unit.bitmap.w,@unit.bitmap.h,[0, 0, 0, 0]) if param[:is_fill]
      when :movie
        self.bitmap = bitmap.display_format
      end
      @type = param[:type]

      if param.has_key?(:unit)
        SpriteUnitFactory.apply(@unit, :ow=>param[:unit].ow, :oh=>param[:unit].oh,
                                       :cx => param[:unit].cx, :cy => param[:unit].cy)
        self.move_to(param[:unit].x, param[:unit].y)
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

    #===画像の表示開始位置(X座標)を指定する
    #oxを指定すると、表示の左上位置が変更される。
    #値が画像の幅の範囲外(値がマイナス、画像の幅を超える値)のときは例外が発生する
    #_v_:: 表示開始位置。整数で指定
    def ox=(v)
      raise MiyakoError, "Illegal ox parameter! : #{v}" if (v < 0 || (v+@unit.ow) > @w)
      @unit.ox = v
    end
    
    #===画像の表示開始位置(Y座標)を指定する
    #oyを指定すると、表示の左上位置が変更される。
    #値が画像の高さの範囲外(値がマイナス、画像の高さを超える値)のときは例外が発生する
    #_v_:: 表示開始位置。整数で指定
    def oy=(v)
      raise MiyakoError, "Illegal oy parameter! : #{v}" if (v < 0 || (v+@unit.oh) > @h)
      @unit.oy = v
    end
    
    #===画像の表示幅を指定する
    #owを指定すると、横方向の一部のみ表示される。
    #値が画像の幅の範囲外(値がマイナス、画像の幅を超える値)のときは例外が発生する
    #_v_:: 表示幅。整数で指定
    def ow=(v)
      raise MiyakoError, "Illegal ox parameter! : #{v}" if (v < 0 || (@unit.ox+v) > @w)
      @unit.ow = v
      set_layout_size(v, @unit.oh)
    end

    #===画像の表示高を指定する
    #ohを指定すると、縦方向の一部のみ表示される。
    #値が画像の高さの範囲外(値がマイナス、画像の高さを超える値)のときは例外が発生する
    #_v_:: 表示高。整数で指定
    def oh=(v)
      raise MiyakoError, "Illegal ox parameter! : #{v}" if (v < 0 || (@unit.oy+v) > @h)
      @unit.oh = v
      set_layout_size(@unit.ow, v)
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #x方向の中心座標を取得する
    #返却値:: 中心座標。
    def center_x
      return @unit.cx
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #x方向の中心座標を取得する
    #_pos_:: 中心座標
    def center_x=(pos)
      @unit.cx = pos
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #y方向の中心座標を取得する
    #返却値:: 中心座標。
    def center_y
      return @unit.cy
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #y方向の中心座標を取得する
    #_pos_:: 中心座標
    def center_y=(pos)
      @unit.cy = pos
    end

    #===画像の表示矩形を取得する
    #画像が表示されているときの矩形(Rect構造体)を取得する
    #返却値:: 生成された矩形(Rect構造体インスタンス)
    def rect
      return Rect.new(@unit.x, @unit.y, @unit.ow, @unit.oh)
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #但し、Spriteの場合は最大の大きさ=スプライトの大きさなので、rectと同じ値が得られる
    #返却値:: 画像の大きさ(Rect構造体のインスタンス)
    def broad_rect
      return self.rect
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

    #===インスタンスをSpriteUnit構造体に変換して取得する
    #得られるインスタンスは複写していないので、インスタンスの値を調整するには、dupメソッドで複製する必要がある
    #返却値:: SpriteUnit化したスプライト
    def to_unit
      return @unit
    end

    #===インスタンスをスプライト化して返す
    #インスタンスの複製を行う(画像インスタンスも複製)
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #注意事項：
    #１．複製のため、呼び出していくとメモリ使用量が著しく上がる
    #２．レイアウト情報がリセットされる(snapの親子関係が解消される)
    #返却値:: 自分自身を返す
    def to_sprite
      unit = @unit.dup
      unit.bitmap = Bitmap.create(unit.bitmap.w, unit.bitmap.h)
      Bitmap.blit_aa!(@unit, unit, 0, 0)
      sprite = Sprite.new(:unit=>unit, :type=>:ac)
      yield sprite if block_given?
      return sprite
    end

    #===インスタンスの内容を別のインスタンスに描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #ブロックの引数は、|転送元のSpriteUnit,転送先のSpriteUnit|となる。
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 自分自身を返す
    def Sprite.render_to(src, dst)
    end

    #===インスタンスの内容を画面に描画する
    #現在の画像を、現在の状態で描画するよう指示する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit, 画面のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #返却値:: 自分自身を返す
    def render
    end

    #===インスタンスの内容を別のインスタンスに描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit,転送先のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 自分自身を返す
    def render_to(dst)
    end

    #===インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。回転の中心はsrc側(ox,oy)を起点に、src側(cx,cy)が中心になるように設定する。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、画面側SpriteUnitの(cx,cy)が中心になるように設定にする。
    #回転角度が正だと右回り、負だと左回りに回転する
    #変形の度合いは、src側SpriteUnitのxscale, yscaleを使用する(ともに実数で指定する)。それぞれ、x方向、y方向の度合いとなる
    #度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
    #また、変形元の幅・高さのいずれかが32768以上の時は回転・転送を行わない
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit,画面のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
    #_xscale_:: 拡大率(x方向)
    #_yscale_:: 拡大率(y方向)
    #返却値:: 自分自身を返す
    def render_transform(radian, xscale, yscale)
    end

    #===インスタンスの内容を画面に描画する(回転/拡大/縮小/鏡像付き)
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。回転の中心はsrc側(ox,oy)を起点に、src側(cx,cy)が中心になるように設定する。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に、画面側SpriteUnitの(cx,cy)が中心になるように設定にする。
    #回転角度が正だと右回り、負だと左回りに回転する
    #変形の度合いは、src側SpriteUnitのxscale, yscaleを使用する(ともに実数で指定する)。それぞれ、x方向、y方向の度合いとなる
    #度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
    #また、変形元の幅・高さのいずれかが32768以上の時は回転・転送を行わない
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit,転送先のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
    #_xscale_:: 拡大率(x方向)
    #_yscale_:: 拡大率(y方向)
    #返却値:: 自分自身を返す
    def render_to_transform(dst, radian, xscale, yscale)
    end

    #===２つの画像のandを取り、別の画像へ転送する
    #重ね合わせの式は、"src and self -> dst"で表される。自分自身と転送先画像は同じ大きさとなる。
    #範囲は、インスタンス側とsrc側との(ow,oh)の小さい方の範囲で転送する。
    #src側の(x,y)をインスタンス側の起点として、src側の(ow,oh)の範囲で転送する。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の新しい画像インスタンス
    def and(src)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.blit_and!(src, self, dst)
      return dst
    end

    #===２つの画像のandを破壊的に行う
    #重ね合わせの式は、"src and self -> self"で表される。
    #範囲は、インスタンス側とsrc側との(ow,oh)の小さい方の範囲で転送する。
    #src側の(x,y)をインスタンス側の起点として、src側の(ow,oh)の範囲で転送する。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の自分自身を返す
    def and!(src)
      raise MiyakoError, "illegal range!" unless Bitmap.blit_and!(src, self, self)
      return self
    end

    #===２つの画像のorを取り、別の画像へ転送する
    #重ね合わせの式は、"src or self -> dst"で表される。自分自身と転送先画像は同じ大きさとなる。
    #範囲は、インスタンス側とsrc側との(ow,oh)の小さい方の範囲で転送する。
    #src側の(x,y)をインスタンス側の起点として、src側の(ow,oh)の範囲で転送する。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の新しい画像インスタンス
    def or(src)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.blit_or!(src, self, dst)
      return dst
    end

    #===２つの画像のorを破壊的に行う
    #重ね合わせの式は、"src or self -> self"で表される。
    #範囲は、インスタンス側とsrc側との(ow,oh)の小さい方の範囲で転送する。
    #src側の(x,y)をインスタンス側の起点として、src側の(ow,oh)の範囲で転送する。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の自分自身を返す
    def or!(src)
      raise MiyakoError, "illegal range!" unless Bitmap.blit_or!(src, self, self)
      return self
    end

    #===２つの画像のxorを取り、別の画像へ転送する
    #重ね合わせの式は、"src xor self -> dst"で表される。自分自身と転送先画像は同じ大きさとなる。
    #範囲は、インスタンス側とsrc側との(ow,oh)の小さい方の範囲で転送する。
    #src側の(x,y)をインスタンス側の起点として、src側の(ow,oh)の範囲で転送する。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の新しい画像インスタンス
    def xor(src)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.blit_xor!(src, self, dst)
      return dst
    end

    #===２つの画像のxorを破壊的に行う
    #重ね合わせの式は、"src xor self -> self"で表される。
    #範囲は、インスタンス側とsrc側との(ow,oh)の小さい方の範囲で転送する。
    #src側の(x,y)をインスタンス側の起点として、src側の(ow,oh)の範囲で転送する。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の自分自身を返す
    def xor!(src)
      raise MiyakoError, "illegal range!" unless Bitmap.blit_xor!(src, self, self)
      return self
    end

    #===画像のαチャネルの値を一定の割合で変化させて転送する
    #degreeの値が1.0に近づけば近づくほど透明に近づき、
    #degreeの値が-1.0に近づけば近づくほど不透明に近づく(値が-1.0のときは完全不透明、値が0.0のときは変化なし、1.0のときは完全に透明になる)
    #但し、元々αの値がゼロの時は変化しない
    #_degree_:: 減少率。-1.0<=degree<=1.0までの実数
    #返却値:: 変更後の新しい画像インスタンス
    def dec_alpha(degree)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.dec_alpha!(self, dst, degree)
      return dst
    end

    #===画像のαチャネルの値を一定の割合で破壊的に変化させる
    #degreeの値が1.0に近づけば近づくほど透明に近づき、
    #degreeの値が-1.0に近づけば近づくほど不透明に近づく(値が-1.0のときは完全不透明、値が0.0のときは変化なし、1.0のときは完全に透明になる)
    #但し、元々αの値がゼロの時は変化しない
    #_degree_:: 減少率。-1.0<=degree<=1.0までの実数
    #返却値:: 変更後の自分自身を返す
    def dec_alpha!(degree)
      raise MiyakoError, "illegal range!" unless Bitmap.dec_alpha!(self, self, degree)
      return self
    end

    #===画像の色を一定の割合で黒に近づける(ブラックアウト)
    #赤・青・緑・αの各要素を一定の割合で下げ、黒色に近づける。
    #degreeの値が1.0に近づけば近づくほど黒色に近づく(値が0.0のときは変化なし、1.0のときは真っ黒になる)
    #αの値が0のときは変わらないことに注意！
    #_degree_:: 変化率。0.0<=degree<=1.0までの実数
    #返却値:: 変更後の新しい画像インスタンス
    def black_out(degree)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.black_out!(self, dst, degree)
      return dst
    end

    #===画像の色を一定の割合で黒に近づける(ブラックアウト)
    #赤・青・緑・αの各要素を一定の割合で下げ、黒色に近づける。
    #degreeの値が1.0に近づけば近づくほど黒色に近づく(値が0.0のときは変化なし、1.0のときは真っ黒になる)
    #αの値が0のときは変わらないことに注意！
    #_degree_:: 変化率。0.0<=degree<=1.0までの実数
    #返却値:: 変更後の自分自身を返す
    def black_out!(degree)
      raise MiyakoError, "illegal range!" unless Bitmap.black_out!(self, self, degree)
      return self
    end

    #===画像の色を一定の割合で白に近づける(ホワイトアウト)
    #赤・青・緑・αの各要素を一定の割合で上げ、白色に近づける。
    #degreeの値が1.0に近づけば近づくほど白色に近づく(値が0.0のときは変化なし、1.0のときは真っ白になる)
    #αの値が0のときは変わらないことに注意！
    #_degree_:: 変化率。0.0<=degree<=1.0までの実数
    #返却値:: 変更後の新しい画像インスタンス
    def white_out(degree)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.white_out!(self, dst, degree)
      return dst
    end

    #===画像の色を一定の割合で白に近づける(ホワイトアウト)
    #赤・青・緑・αの各要素を一定の割合で上げ、白色に近づける。
    #degreeの値が1.0に近づけば近づくほど白色に近づく(値が0.0のときは変化なし、1.0のときは真っ白になる)
    #αの値が0のときは変わらないことに注意！
    #_degree_:: 変化率。0.0<=degree<=1.0までの実数
    #返却値:: 変更後の自分自身を返す
    def white_out!(degree)
      raise MiyakoError, "illegal range!" unless Bitmap.white_out!(self, self, degree)
      return self
    end

    #===画像のRGB値を反転させる
    #αチャネルの値は変更しない
    #返却値:: 変更後の新しい画像インスタンス
    def inverse
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.inverse!(self, dst)
      return dst
    end

    #===画像のRGB値を反転させる
    #αチャネルの値は変更しない
    #返却値:: 変更後の自分自身を返す
    def inverse!
      raise MiyakoError, "illegal range!" unless Bitmap.inverse!(self, self)
      return self
    end

    #===2枚の画像の加算合成を行う
    #範囲は、src側の(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側の(x,y)を左上とする。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の新しい画像インスタンス
    def additive(src)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      self.render_to(dst)
      raise MiyakoError, "illegal range!" unless Bitmap.additive!(src, dst)
      return dst
    end

    #===2枚の画像の加算合成を行う
    #範囲は、src側の(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側の(x,y)を左上とする。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の自分自身を返す
    def additive!(src)
      raise MiyakoError, "illegal range!" unless Bitmap.additive!(src, self)
      return self
    end

    #===2枚の画像の減算合成を行う
    #範囲は、src側の(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側の(x,y)を左上とする。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の新しい画像インスタンス
    def subtraction(src)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      self.render_to(dst)
      raise MiyakoError, "illegal range!" unless Bitmap.subtraction!(src, dst)
      return dst
    end

    #===2枚の画像の減算合成を行う
    #範囲は、src側の(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側の(x,y)を左上とする。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 変更後の自分自身を返す
    def subtraction!(src)
      raise MiyakoError, "illegal range!" unless Bitmap.subtraction!(src, self)
      return self
    end

    #===画像の色相を変更する
    #_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
    #返却値:: 変更後の新しい画像インスタンス
    def hue(degree)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.hue!(self, dst, degree)
      return dst
    end

    #===画像の色相を変更する
    #_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
    #返却値:: 変更後の画像インスタンス
    #返却値:: 変更後の自分自身を返す
    def hue!(degree)
      raise MiyakoError, "illegal range!" unless Bitmap.hue!(self, self, degree)
      return self
    end

    #===画像の彩度を変更する
    #_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 変更後の新しい画像インスタンス
    def saturation(saturation)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.saturation!(self, dst, saturation)
      return dst
    end

    #===画像の彩度を変更する
    #_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 変更後の自分自身を返す
    def saturation!(saturation)
      raise MiyakoError, "illegal range!" unless Bitmap.saturation!(self, self, saturation)
      return self
    end

    #===画像の明度を変更する
    #_value_:: 明度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 変更後の新しい画像インスタンス
    def value(value)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.value!(self, dst, value)
      return dst
    end

    #===画像の明度を変更する
    #_value_:: 明度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 変更後の画像インスタンス
    def value!(value)
      raise MiyakoError, "illegal range!" unless Bitmap.value!(self, self, value)
      return self
    end

    #===画像の色相・彩度・明度を変更する
    #_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
    #_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
    #_value_:: 明度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 変更後の新しい画像インスタンス
    def hsv(degree, saturation, value)
      dst = Sprite.new(:size=>self.size, :type=>:ac)
      raise MiyakoError, "illegal range!" unless Bitmap.hsv!(self, dst, degree, saturation, value)
      return dst
    end

    #===画像の色相・彩度・明度を変更する
    #_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
    #_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
    #_value_:: 明度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 変更後の画像インスタンス
    def hsv!(degree, saturation, value)
      raise MiyakoError, "illegal range!" unless Bitmap.hsv!(self, self, degree, saturation, value)
      return self
    end
  end
end
