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

require 'csv'
require 'forwardable'

module Miyako
  #==スクロールしないマップクラス
  class FixedMap
    include Layout
    
    @@idx_ix = [-1, 2, 4]
    @@idx_iy = [-1, 0, 6]

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
    attr_reader :name, :map_layers, :mapchips, :pos, :size, :w, :h

    #==あとで書く
    class FixedMapLayer #:nodoc: all
      extend Forwardable

      @@use_chip_list = Hash.new(nil)
      
      attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
      attr_accessor :mapchip, :mapchip_units
      attr_reader :pos

      def round(v, max) #:nodoc:
        v = max + (v % max) if v < 0
        v %= max if v >= max
        return v
      end

      def reSize #:nodoc:
        @cw = @real_size.w % @ow == 0 ? @real_size.w / @ow : (@real_size.w + @ow - 1)/ @ow + 1
        @ch = @real_size.h % @oh == 0 ? @real_size.h / @oh : (@real_size.h + @oh - 1)/ @oh + 1
      end

      def initialize(mapchip, mapdat, layer_size) #:nodoc:
        @mapchip = mapchip
        @pos = Point.new(0, 0)
        @size = layer_size.dup
        @ow = @mapchip.chip_size.w
        @oh = @mapchip.chip_size.h
        @real_size = Size.new(@size.w * @ow, @size.h * @oh)
        @mapdat = mapdat
        @baseimg = nil
        @baseimg = @mapchip.chip_image
        @units = nil
        @visible = true
        @divpx = get_div_array(0, @real_size.w, @ow)
        @divpy = get_div_array(0, @real_size.h, @oh)
        @modpx = get_mod_array(0, @real_size.w, @ow)
        @modpy = get_mod_array(0, @real_size.h, @oh)
        @modpx2 = get_mod_array(0, @size.w * 2 + 1, @size.w)
        @modpy2 = get_mod_array(0, @size.h * 2 + 1, @size.h)
        @cdivsx = get_div_array(0, @mapchip.chips, @mapchip.size.w)
        @cmodsx = get_mod_array(0, @mapchip.chips, @mapchip.size.w)
        @cdivsy = get_div_array(0, @mapchip.chips, @mapchip.size.h)
        @cmodsy = get_mod_array(0, @mapchip.chips, @mapchip.size.h)
        @cdivsx = @cdivsx.map{|v| v * @ow }
        @cdivsy = @cdivsy.map{|v| v * @oh }
        @cmodsx = @cmodsx.map{|v| v * @ow }
        @cmodsy = @cmodsy.map{|v| v * @oh }
        @mapchip_units = Array.new(@mapchip.chips){|idx|
          SpriteUnitFactory.create(:bitmap=>@baseimg.bitmap,
                                   :ox => (idx % @mapchip.size.w) * @ow, :oy => (idx / @mapchip.size.w) * @oh,
                                   :ow => @ow, :oh => @oh)
        }
        reSize
      end

      def get_div_array(s, t, v) #:nodoc:
        a = Array.new
        (s..t).each{|i| a.push(i / v)}
        return a
      end

      def get_mod_array(s, t, v) #:nodoc:
        a = Array.new
        (s..t).each{|i| a.push(i % v)}
        return a
      end

      def convert_position(x, y) #:nodoc:
        return Point.new(@modpx2[round(x, @size.w)],
                         @modpy2[round(y, @size.h)])
      end

      #===指定の矩形のキャラクタに掛かるマップチップの左上位置の組み合わせを返す
      #但し、引数には、Rect(x,y,w,h)形式のインスタンスを渡す
      #_rect_:: キャラクタの矩形
      #返却値:: マップチップ左上位置の配列(キャラクタに掛かる位置の組み合わせ)
      def product_position(rect)
        return Utility.product_position(rect, @mapchip.chip_size)
      end

      #===指定の矩形のキャラクタに掛かるマップチップの左上位置の組み合わせを返す
      #但し、引数には、Square([x1,y1,x2,y2])形式のインスタンスを渡す
      #_square_:: キャラクタの矩形
      #返却値:: マップチップ左上位置の配列(キャラクタに掛かる位置の組み合わせ)
      def product_position_by_square(square)
        return Utility.product_position_by_square(square, @mapchip.chip_size)
      end

      #===実座標を使用して、指定のレイヤー・位置のマップチップ番号を取得
      #イベントレイヤーでの番号はイベント番号と一致する
      #_x_:: マップチップ単位での位置(ピクセル単位)
      #_y_:: マップチップ単位での位置(ピクセル単位）
      #返却値:: マップチップ番号(マップチップが設定されている時は0以上の整数、設定されていない場合は-1が返る)
      def get_code(x, y)
        pos = convert_position(x / @mapchip.chip_size[0], y / @mapchip.chip_size[1])
        return @mapdat[pos.y][pos.x]
      end

      #===キャラクタとマップチップが重なっているかどうか問い合わせる
      #指定の矩形のキャラクタが、指定の位置のマップチップのコリジョンと重なっているかどうか問い合わせる
      #引数は、Rect(x,y,w,h)形式(Rect構造体、[x,y,w,h]の配列)で渡す
      #指定の位置のマップチップ番号が-1(未定義)のときはfalseを返す
      #_type_:: 移動形式(0以上の整数)
      #_pos_:: 調査対象のマップチップの位置
      #_collision_:: キャラクタのコリジョン
      #_rect_:: キャラクタの矩形
      #返却値:: コリジョンが重なっていればtrueを返す
      def collision?(type, pos, collision, rect)
        code = get_code(*pos.to_a)
        return false if code == -1
        return @mapchip.collision_table[type][code].collision?(pos, collision, rect)
      end

      #===キャラクタとマップチップが隣り合っているかどうか問い合わせる
      #指定の矩形のキャラクタが、指定の位置のマップチップのコリジョンと隣り合っているかどうか問い合わせる
      #引数は、Rect(x,y,w,h)形式(Rect構造体、[x,y,w,h]の配列)で渡す
      #指定の位置のマップチップ番号が-1(未定義)のときはfalseを返す
      #_type_:: 移動形式(0以上の整数)
      #_pos_:: 調査対象のマップチップの位置
      #_collision_:: キャラクタのコリジョン
      #_rect_:: キャラクタの矩形
      #返却値:: コリジョンが隣り合っていればtrueを返す
      def meet?(type, pos, collision, rect)
        code = get_code(*pos.to_a)
        return false if code == -1
        return @mapchip.collision_table[type][code].meet?(pos, collision, rect)
      end

      #===キャラクタとマップチップが覆い被さっているかどうか問い合わせる
      #指定の矩形のキャラクタが、指定の位置のマップチップのコリジョンを覆い被さっているかどうか問い合わせる
      #引数は、Rect(x,y,w,h)形式(Rect構造体、[x,y,w,h]の配列)で渡す
      #指定の位置のマップチップ番号が-1(未定義)のときはfalseを返す
      #_type_:: 移動形式(0以上の整数)
      #_pos_:: 調査対象のマップチップの位置
      #_collision_:: キャラクタのコリジョン
      #_rect_:: キャラクタの矩形
      #返却値:: どちらかのコリジョンが覆い被さっていればtrueを返す
      def cover?(type, pos, collision, rect)
        code = get_code(*pos.to_a)
        return false if code == -1
        return @mapchip.collision_table[type][code].cover?(pos, collision, rect)
      end

      #===キャラクタとマップチップが重なっているかどうか問い合わせる
      #指定の位置と方向で、指定の位置のマップチップ上で移動できるかどうか問い合わせる
      #指定の位置のマップチップ番号が-1(未定義)のとき、移動していない(dx==0 and dy==0)ときはtrueを返す
      #_type_:: 移動形式(0以上の整数)
      #_inout_:: 入退形式(:in もしくは :out)
      #_pos_:: 調査対象のマップチップの位置
      #_dx_:: 移動量(x座標)
      #_dy_:: 移動量(y座標)
      #返却値:: 移動可能ならばtrueを返す
      def can_access?(type, inout, pos, dx, dy)
        code = get_code(pos[0]+dx, pos[1]+dy)
        return true if code == -1
        index = AccessIndex.index2(inout, dx, dy)
        return true if index == -1
        return @mapchip.access_table[type][code][index]
      end

      def dispose #:nodoc:
        @mapdat = nil
        @baseimg = nil
      end

      #===マップレイヤーを画面に描画する
      #すべてのマップチップを画面に描画する
      #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
      #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
      #ブロックの引数は、|画面のSpriteUnit|となる。
      #visibleメソッドの値がfalseのときは描画されない。
      #返却値:: 自分自身を返す
      def render
      end

      #===マップを画像に描画する
      #すべてのマップチップを画像に描画する
      #各レイヤ－を、レイヤーインデックス番号の若い順に描画する
      #但し、マップイベントは描画しない
      #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
      #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
      #ブロックの引数は、|転送先のSpriteUnit|となる。
      #visibleメソッドの値がfalseのときは描画されない。
      #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
      #返却値:: 自分自身を返す
      def render_to(dst)
      end

      def_delegators(:@size, :w, :h)
    end


    #===インスタンスを生成する
    #各レイヤにMapChip構造体を渡す
    #但し、すべてのレイヤーに同一のMapChip構造体を使うときは、単体で渡すことも可能
    #第1引数にto_aメソッドが実装されていれば、配列化した要素をMapChip構造体として各レイヤに渡す
    #また、各レイヤにMapChip構造体を渡すとき、レイヤ数より要素数が少ないときは、
    #先頭に戻って繰り返し渡す仕様になっている
    #各MapChip構造体のマップチップの大きさを同じにしておく必要がある
    #_mapchips_:: マップチップ構造体群(MapChip構造体単体もしくは配列)
    #_layer_csv_:: レイヤーファイル(CSVファイル)
    #_event_manager_:: MapEventManagerクラスのインスタンス
    #返却値:: 生成したインスタンス
    def initialize(mapchips, layer_csv, event_manager)
      init_layout
      @visible = true
      @event_layers = []
      @em = event_manager.dup
      @em.set(self)
      @mapchips = mapchips.to_a
      layer_data = CSV.readlines(layer_csv)

      raise MiyakoError, "This file is not Miyako Map Layer file! : #{layer_csv}" unless layer_data.shift[0] == "Miyako Maplayer"

      tmp = layer_data.shift # 空行の空読み込み

      @size = Size.new(tmp[0].to_i, tmp[1].to_i)
      @w = @size.w * @mapchips.first.chip_size.w
      @h = @size.h * @mapchips.first.chip_size.h

      layers = layer_data.shift[0].to_i

      evlist = []
      brlist = []
      layers.times{|n|
        name = layer_data.shift[0]
        values = []
        @size.h.times{|y|
          values << layer_data.shift.map{|m| m.to_i}
        }
        if name == "<event>"
          evlist << values
        else
          brlist << values
        end
      }

      @event_layer = nil

      evlist.each{|events|
        event_layer = Array.new
        events.each_with_index{|ly, y|
          ly.each_with_index{|code, x|
            next unless @em.include?(code)
            event_layer.push(@em.create(code, x * @mapchips.first.chip_size.w, y * @mapchips.first.chip_size.h))
          }
        }
        @event_layers << event_layer
      }

      mc = @mapchips.cycle
      @mapchips = mc.take(layers)
      @map_layers = []
      brlist.each{|br|
        br = br.map{|b| b.map{|bb| bb >= @mapchips.first.chips ? -1 : bb } }
        @map_layers.push(FixedMapLayer.new(mc.next, br, @size))
      }
      set_layout_size(@w, @h)
    end

    #===マップにイベントを追加する
    #_idx_:: 追加するイベントレイヤの指標
    #_code_:: イベント番号(Map.newメソッドで渡したイベント番号に対応)
    #_x_:: マップ上の位置(x方向)
    #_y_:: マップ常温位置(y方向)
    #返却値:: 自分自身を返す
    def add_event(idx, code, x, y)
      return self unless @em.include?(code)
      @event_layers[idx].push(@em.create(code, x, y))
      return self
    end

    def update_layout_position #:nodoc:
      @map_layers.each{|ml| ml.pos.move_to(*@layout.pos) }
    end

    def [](idx) #:nodoc:
      return @map_layers[idx]
    end

    #===実座標を使用して、指定のレイヤー・位置のマップチップ番号を取得
    #イベントレイヤーでの番号はイベント番号と一致する
    #ブロックを渡すと、求めたマップチップ番号をブロック引数として受け取る評価を行える
    #_idx_:: マップレイヤー配列のインデックス
    #_x_:: マップチップ単位での位置(ピクセル単位)
    #_y_:: マップチップ単位での位置(ピクセル単位）
    #返却値:: マップチップ番号(マップチップが設定されている時は0以上の整数、設定されていない場合は-1が返る)
    def get_code(idx, x = 0, y = 0)
      code = @map_layers[idx].get_code(x, y)
      yield code if block_given?
      return code
    end

    #===対象のマップチップ番号の画像を置き換える
    #_idx_:: 置き換えるマップチップレイヤー番号
    #_code_:: 置き換えるマップチップ番号
    #_base_:: 置き換え対象の画像・アニメーション
    #返却値:: 自分自身を返す
    def set_mapchip_base(idx, code, base)
      @map_layers[idx].mapchip_units[code] = base
      return self
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #但し、FixedMapの場合は最大の大きさ=画面の大きさなので、rectと同じ値が得られる
    #返却値:: 画像の大きさ(Rect構造体のインスタンス)
    def broad_rect
      return self.rect
    end

    #===スプライトに変換した画像を表示する
    #すべてのパーツを貼り付けた、１枚のスプライトを返す
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 描画したスプライト
    def to_sprite
      rect = self.broad_rect
      sprite = Sprite.new(:size=>rect.to_a[2,2], :type=>:ac)
      Drawing.fill(sprite, [0,0,0])
      Bitmap.ck_to_ac!(sprite, [0,0,0])
      self.render_to(sprite){|sunit, dunit| sunit.x -= rect.x; sunit.y -= rect.y }
      yield sprite if block_given?
      return sprite
    end

    #===SpriteUnit構造体を生成する
    #いったんSpriteインスタンスを作成し、それをもとにSpriteUnit構造体を生成する。
    #返却値:: 生成したSpriteUnit構造体
    def to_unit
      return self.to_sprite.to_unit
    end

    #===マップチップ１枚の大きさを取得する
    #マップチップの大きさが32×32ピクセルの場合は、[32,32]のSize構造体が返る
    #返却値:: マップチップのサイズ(Size構造体)
    def chipSize
      return @mapchips.first.chip_size
    end

    #===すべてのマップイベントを終了させる
    #マップに登録しているイベントすべてのfinalメソッドを呼び出す
    def final
      @event_layers.each{|ee| ee.each{|e| e.final }}
    end

    #===マップ情報を解放する
    def dispose
      @map_layers.each{|l|
        l.dispose
        l = nil
      }
      @map_layers = Array.new

      @event_layers.each{|ee|
        ee.each{|e| e.dispose }
        ee.clear
      }
      @event_layers.clear

      @mapchips.clear
      @mapchips = nil
    end

    #===マップに登録しているイベントインスタンス(マップイベント)を取得する
    #返却値:: マップイベントの配列
    def events
      return @event_layers
    end

    #===マップを画面に描画する
    #すべてのマップチップを画面に描画する
    #各レイヤ－を、レイヤーインデックス番号の若い順に描画する
    #但し、マップイベントは描画しない
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|画面のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #返却値:: 自分自身を返す
    def render
    end

    #===マップレイヤーを画像に転送する
    #すべてのマップチップを画像に描画する
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|転送先のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 自分自身を返す
    def render_to(dst)
    end
  end
end
