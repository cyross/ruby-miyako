# -*- encoding: utf-8 -*-
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

require 'csv'
require 'forwardable'

module Miyako
  #==スクロールしないマップクラス
  class FixedMap
    include SpriteBase
    include Animation
    include Layout

    @@idx_ix = [-1, 2, 4]
    @@idx_iy = [-1, 0, 6]

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
    attr_reader :name, :map_layers, :mapchips, :map_size, :map_w, :map_h

    #==あとで書く
    class FixedMapLayer #:nodoc: all
      include SpriteBase
      include Animation
      extend Forwardable

      @@use_chip_list = Hash.new(nil)

      attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
      attr_accessor :mapchip, :mapchip_units
      attr_reader :pos, :ignore_list

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
        @def_ignore = -1
        @ignore_list = []
        reSize
      end

      def initialize_copy(obj) #:nodoc:
        @mapchip = @mapchip.dup
        @size = @size.dup
        @mapchip_unit = @mapchip_unit.dup
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

      #===レイヤー配列を取得する
      #レイヤーを構成している配列を取得する
      #取得した配列にアクセスするときの書式は、以下のようになる。
      #layer[y][x]
      #返却値:: 所持しているレイヤー配列
      def layer
        @mapdat
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
      #指定の位置のマップチップ番号が以下の時はfalseを返す
      #1)-1(未定義)のとき
      #2)FixexMapLayer#ignore_listに含まれているとき
      #3)引数ignoresに含まれているとき
      #_type_:: 移動形式(0以上の整数)
      #_pos_:: 調査対象のマップチップの位置
      #_collision_:: キャラクタのコリジョン
      #_cpos_:: キャラクタの位置
      #_ignores_:: コリジョンの対象にしないマップチップ番号のリスト
      #返却値:: コリジョンが重なっていればtrueを返す
      def collision?(type, pos, collision, cpos, *ignores)
        code = get_code(*pos.to_a)
        return false if (code == @def_ignore or @ignore_list.include?(code) or ignores.flatten.include?(code))
        return @mapchip.collision_table[type][code].collision?(pos, collision, cpos)
      end

      #===キャラクタとマップチップが隣り合っているかどうか問い合わせる
      #指定の矩形のキャラクタが、指定の位置のマップチップのコリジョンと隣り合っているかどうか問い合わせる
      #引数は、Rect(x,y,w,h)形式(Rect構造体、[x,y,w,h]の配列)で渡す
      #指定の位置のマップチップ番号が以下の時はfalseを返す
      #1)-1(未定義)のとき
      #2)FixexMapLayer#ignore_listに含まれているとき
      #3)引数ignoresに含まれているとき
      #_type_:: 移動形式(0以上の整数)
      #_pos_:: 調査対象のマップチップの位置
      #_collision_:: キャラクタのコリジョン
      #_cpos_:: キャラクタの位置
      #_ignores_:: コリジョンの対象にしないマップチップ番号のリスト
      #返却値:: コリジョンが隣り合っていればtrueを返す
      def meet?(type, pos, collision, rect, *ignores)
        code = get_code(*pos.to_a)
        return false if (code == @def_ignore or @ignore_list.include?(code) or ignores.flatten.include?(code))
        return @mapchip.collision_table[type][code].meet?(pos, collision, cpos)
      end

      #===キャラクタとマップチップが覆い被さっているかどうか問い合わせる
      #指定の矩形のキャラクタが、指定の位置のマップチップのコリジョンを覆い被さっているかどうか問い合わせる
      #引数は、Rect(x,y,w,h)形式(Rect構造体、[x,y,w,h]の配列)で渡す
      #指定の位置のマップチップ番号が以下の時はfalseを返す
      #1)-1(未定義)のとき
      #2)FixexMapLayer#ignore_listに含まれているとき
      #3)引数ignoresに含まれているとき
      #_type_:: 移動形式(0以上の整数)
      #_pos_:: 調査対象のマップチップの位置
      #_collision_:: キャラクタのコリジョン
      #_cpos_:: キャラクタの位置
      #_ignores_:: コリジョンの対象にしないマップチップ番号のリスト
      #返却値:: どちらかのコリジョンが覆い被さっていればtrueを返す
      def cover?(type, pos, collision, rect, *ignores)
        code = get_code(*pos.to_a)
        return false if (code == @def_ignore or @ignore_list.include?(code) or ignores.flatten.include?(code))
        return @mapchip.collision_table[type][code].cover?(pos, collision, cpos)
      end

      #===キャラクタとマップチップが重なっているかどうか問い合わせる
      #指定の位置と方向で、指定の位置のマップチップ上で移動できるかどうか問い合わせる
      #指定の位置のマップチップ番号が以下の時はtrueを返す
      #1)-1(未定義)のとき
      #2)FixexMapLayer#ignore_listに含まれているとき
      #3)引数ignoresに含まれているとき
      #また、dx==0, dy==0のときもtrueを返す
      #_type_:: 移動形式(0以上の整数)
      #_inout_:: 入退形式(:in もしくは :out)
      #_pos_:: 調査対象のマップチップの位置
      #_dx_:: 移動量(x座標)
      #_dy_:: 移動量(y座標)
      #_ignores_:: チェックの対象にしないマップチップ番号のリスト。番号に含まれているときはtrueを返す
      #返却値:: 移動可能ならばtrueを返す
      def can_access?(type, inout, pos, dx, dy, *ignores)
        return true if dx == 0 and dy == 0
        code = get_code(pos[0]+dx, pos[1]+dy)
        return true if (code == @def_ignore or @ignore_list.include?(code) or ignores.flatten.include?(code))
        index = MapDir.index2(inout, dx, dy)
        return true if index == -1
        return @mapchip.access_table[type][code][index]
      end

      def dispose #:nodoc:
        @mapdat = nil
        @baseimg = nil
        @ignore_list.clear
        @ignore_list = []
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
    #_map_struct_:: MapStruct構造体のインスタンス
    #_event_manager_:: MapEventManagerクラスのインスタンス。省略時（イベントを使わない時）はnil
    #返却値:: 生成したインスタンス
    def initialize(mapchips, map_struct, event_manager=nil)
      init_layout
      @visible = true
      if event_manager
        @em = event_manager.dup
        @em.set(self)
      else
        @em = nil
      end
      @mapchips = mapchips.to_a

      @map_size = map_struct.size
      @map_w = @map_size.w * @mapchips.first.chip_size.w
      @map_h = @map_size.h * @mapchips.first.chip_size.h

      @event_layers = []

      if map_struct.elayers
        raise MiyakoError "Event Manager is not registered!" unless @em
        map_struct.elayers.each{|events|
          event_layer = Array.new
          events.each_with_index{|ly, y|
            ly.each_with_index{|code, x|
              next unless @em.include?(code)
              event_layer.push(@em.create(code, x * @mapchips.first.chip_size.w, y * @mapchips.first.chip_size.h))
            }
          }
          @event_layers << event_layer
        }
      end

      @event_layers << [] if @event_layers.empty?

      mc = @mapchips.cycle
      @mapchips = mc.take(map_struct.layer_num)
      @map_layers = []
      map_struct.layers.each{|br|
        br = br.map{|b| b.map{|bb| bb >= @mapchips.first.chips ? -1 : bb } }
        @map_layers.push(FixedMapLayer.new(mc.next, br, @map_size))
      }
      set_layout_size(@map_w, @map_h)
    end

    def initialize_copy(obj) #:nodoc:
      @map_layers = @map_layers.dup
      @event_layers = @event_layers.dup
      @em = @em.dup if @em
      @mapchips = @mapchips.dup
      @map_size = @map_size.dup
      copy_layout
    end

    #===マップにイベントを追加する
    #イベントレイヤーでの番号はイベント番号と一致する
    #ブロックを渡すと、求めたマップチップ番号をブロック引数として受け取る評価を行える
    #_idx_:: 追加するイベントレイヤの指標
    #_code_:: イベント番号(Map.newメソッドで渡したイベント番号に対応)
    #_x_:: マップ上の位置(x方向)
    #_y_:: マップ常温位置(y方向)
    #返却値:: 自分自身を返す
    def add_event(idx, code, x, y)
      raise MiyakoError "Event Manager is not registered!" unless @em
      raise MiyakoError "Unregisted event code! : #{code}" unless @em.include?(code)
      @event_layers[idx].push(@em.create(code, x, y))
      return self
    end

    #===マップに生成済みのイベントを追加する
    #_idx_:: 追加するイベントレイヤの指標
    #_event_:: イベント番号(Map.newメソッドで渡したイベント番号に対応)
    #返却値:: 自分自身を返す
    def append_event(idx, event)
      @event_layers[idx].push(event)
      return self
    end


    #===指定のレイヤーのイベントに対してupdateメソッドを呼び出す
    #イベントレイヤーidxの全てのイベントに対してupdateメソッドを呼び出す
    #_idx_:: 更新するイベントレイヤーの番号
    #_params_:: イベントのupdateメソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def event_update(idx, *params)
      @event_layers[idx].each{|event| event.update(self, @event_layers[idx], *params) }
      self
    end

    #===全てのイベントに対してupdateメソッドを呼び出す
    #全レイヤーのイベントを呼び出すことに注意
    #_params_:: イベントのupdateメソッドを呼び出すときに渡す引数。可変個数
    def all_event_update(*params)
      @event_layers.each{|el| el.each{|event| event.update(self, el, *params) } }
      self
    end

    #===指定のレイヤーのイベントに対してupdate2メソッドを呼び出す
    #イベントレイヤーidxの全てのイベントに対してupdateメソッドを呼び出す
    #_idx_:: 更新するイベントレイヤーの番号
    #_params_:: イベントのupdateメソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def event_update2(idx, *params)
      @event_layers[idx].each{|event| event.update2(*params) }
      self
    end

    #===全てのイベントに対してupdate2メソッドを呼び出す
    #全レイヤーのイベントを呼び出すことに注意
    #_params_:: イベントのupdate2メソッドを呼び出すときに渡す引数。可変個数
    def all_event_update2(*params)
      @event_layers.each{|el| el.each{|event| event.update2(*params) } }
      self
    end

    #===指定のレイヤーのイベントに対してmove!メソッドを呼び出す
    #イベントレイヤーidxの全てのイベントに対してmove!メソッドを呼び出す
    #_idx_:: 更新するイベントレイヤーの番号
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_params_:: イベントのmove!メソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def event_move!(idx, dx, dy, *params)
      @event_layers[idx].each{|event| event.move!(dx, dy, *params) }
      self
    end

    #===全てのイベントに対してmove!メソッドを呼び出す
    #全レイヤーのイベントを呼び出すことに注意
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_params_:: イベントのmove!メソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def all_event_move!(dx, dy, *params)
      @event_layers.each{|el| el.each{|event| event.move!(dx, dy, *params) } }
      self
    end

    #===指定のレイヤーのイベントに対してsprite_move!メソッドを呼び出す
    #イベントレイヤーidxの全てのイベントに対してsprite_move!メソッドを呼び出す
    #_idx_:: 更新するイベントレイヤーの番号
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_params_:: イベントのmove!メソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def event_sprite_move!(idx, dx, dy, *params)
      @event_layers[idx].each{|event| event.sprite_move!(dx, dy, *params) }
      self
    end

    #===全てのイベントに対してsprite_move!メソッドを呼び出す
    #全レイヤーのイベントを呼び出すことに注意
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_params_:: イベントのmove!メソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def all_event_sprite_move!(dx, dy, *params)
      @event_layers.each{|el| el.each{|event| event.sprite_move!(dx, dy, *params) } }
      self
    end

    #===指定のレイヤーのイベントに対してsprite_move!メソッドを呼び出す
    #イベントレイヤーidxの全てのイベントに対してsprite_move!メソッドを呼び出す
    #_idx_:: 更新するイベントレイヤーの番号
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_params_:: イベントのmove!メソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def event_pos_move!(idx, dx, dy, *params)
      @event_layers[idx].each{|event| event.pos_move!(dx, dy, *params) }
      self
    end

    #===全てのイベントに対してsprite_move!メソッドを呼び出す
    #全レイヤーのイベントを呼び出すことに注意
    #_dx_:: x座標の移動量
    #_dy_:: y座標の移動量
    #_params_:: イベントのmove!メソッドを呼び出すときに渡す引数。可変個数
    #返却値:: レシーバ
    def all_event_pos_move!(dx, dy, *params)
      @event_layers.each{|el| el.each{|event| event.pos_move!(dx, dy, *params) } }
      self
    end

    def update_layout_position #:nodoc:
      @map_layers.each{|ml| ml.pos.move_to!(*@layout.pos) }
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
