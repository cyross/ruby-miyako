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

require 'csv'
require 'forwardable'

module Miyako
#==Miyako::Map class
#==Miyako::MapLayer class

=begin rdoc
=あとで書く
=end
  MapChip = Struct.new(:chip_image, :chips, :size, :chip_size, :access_types, :collision_table, :access_table)
=begin rdoc
=あとで書く
=end
  MapMoveAmount = Struct.new(:collisions, :amount)

=begin rdoc
=マップチップ作成ファクトリクラス
=end
  class MapChipFactory
  #===あとで書く
  #_csv_filename_:: あとで書く
  #_use_alpha_:: あとで書く
  #返却値:: あとで書く
    def MapChipFactory.load(csv_filename, use_alpha = true)
      lines = CSV.read(csv_filename)
      raise MiyakoError, "This file is not Miyako Map Chip file! : #{csv_filename}" unless lines.shift[0] == "Miyako Mapchip"
      spr = use_alpha ? Sprite.new({:filename => lines.shift[0], :type => :alpha_channel}) : Sprite.new({:file_name => lines.shift[0], :type => :color_key})
      tmp = lines.shift
      chip_size = Size.new(tmp[0].to_i, tmp[1].to_i)
      size = Size.new(spr.w / chip_size.w, spr.h / chip_size.h)
      chips = size.w * size.h
      access_types = lines.shift[0].to_i
      collision_table = []
      access_types.times{|at|
        tmp_list = []
        chips.times{|n| tmp_list << Collision.new(lines.shift.map{|s| s.to_i}, Point.new(0, 0)) }
        collision_table << tmp_list
      }
      access_table = []
      access_types.times{|at|
        tmp_list = []
        chips.times{|n| tmp_list << (lines.shift.map{|s| s.to_i} << 0 ) }
        access_table << tmp_list
      }
      return MapChip.new(spr, chips, size, chip_size, access_types, collision_table, access_table)
    end
  end

=begin rdoc
==あとで書く
=end
  class Map
    include MiyakoTap

    @@maps = Array.new
    @@idx_ix = [-1, 2, 4]
    @@idx_iy = [-1, 0, 6]

    attr_reader :map_layers, :pos, :view_pos, :size, :w, :h

    class MapLayer #:nodoc: all
      extend Forwardable

      attr_reader :mapchip_units, :pos, :view_pos, :size
      attr_accessor :visible, :dp

      def update #:nodoc:
        return unless @visible
        x2 = round(@view_pos.x, @real_size.w)
        y2 = round(@view_pos.y, @real_size.h)
        dx = @divpx[x2]
        mx = @modpx[x2]
        dy = @divpy[y2]
        my = @modpy[y2]

        pos = 0
        @ch.times{|y|
          m2 = @mapdat[@modpy2[dy + y]]
          @cw.times{|x|
            code = m2[@modpx2[dx + x]]
            next if code == -1 # change!
            mc = @mapchip_units[code].to_unit
            @units[pos].bitmap = mc.bitmap
            @units[pos].ow = mc.ow
            @units[pos].ox = mc.ox
            @units[pos].x = x * @baseimg.ow - mx
            @units[pos].oh = mc.oh
            @units[pos].oy = mc.oy
            @units[pos].y = y * @baseimg.oh - my
            pos += 1
          }
        }
        Screen.sprite_list.concat(@units[0...pos])
      end

      #===画面に描画を指示する
      #現在の画像を、現在の状態で描画するよう指示する
      #--
      #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
      #++
      #返却値:: 自分自身を返す
      def render
        org_visible = @visible
        @visible = true # updateメソッド内でvisibleチェックがあるため
        self.update
        @visible = org_visible
        return self
      end

      def round(v, max) #:nodoc:
        v = max + (v % max) if v < 0
        v %= max if v >= max
        return v
      end

      def resize #:nodoc:
        @cw = (Screen.w + @mapchip.chip_size.w - 1)/ @mapchip.chip_size.w + 1
        @ch = (Screen.h + @mapchip.chip_size.h - 1)/ @mapchip.chip_size.h + 1
        @units.clear if @units
        @units = Array.new
        @ch.times{|y|
          @cw.times{|x|
            @units.push(SpriteUnit.new(@baseimg.dp, @baseimg.bitmap, 0 , 0, 
                                       @baseimg.ow, @baseimg.oh, 0, 0, nil, Screen.rect))
          }
        }
      end

      def initialize(mapchip, mapdat, layer_size) #:nodoc:
        @mapchip = mapchip
        @pos = Point.new(0, 0)
        @view_pos = Point.new(0, 0)
        @size = layer_size.dup
        @real_size = Size.new(@size.w * @mapchip.chip_size.w, @size.h * @mapchip.chip_size.h)
        @mapdat = mapdat
        @baseimg = @mapchip.chip_image
        @baseimg.ow = @mapchip.chip_size.w
        @baseimg.oh = @mapchip.chip_size.h
        @units = nil
        @visible = false
        @divpx = get_div_array(0, @real_size.w, @mapchip.chip_size.w)
        @divpy = get_div_array(0, @real_size.h, @mapchip.chip_size.h)
        @modpx = get_mod_array(0, @real_size.w, @mapchip.chip_size.w)
        @modpy = get_mod_array(0, @real_size.h, @mapchip.chip_size.h)
        @modpx2 = get_mod_array(0, @size.w * 2 + 1, @size.w)
        @modpy2 = get_mod_array(0, @size.h * 2 + 1, @size.h)
        @cdivsx = get_div_array(0, @mapchip.chips, @mapchip.size.w)
        @cmodsx = get_mod_array(0, @mapchip.chips, @mapchip.size.w)
        @cdivsy = get_div_array(0, @mapchip.chips, @mapchip.size.h)
        @cmodsy = get_mod_array(0, @mapchip.chips, @mapchip.size.h)
        @cdivsx = @cdivsx.map{|v| v * @mapchip.chip_size.w }
        @cdivsy = @cdivsy.map{|v| v * @mapchip.chip_size.h }
        @cmodsx = @cmodsx.map{|v| v * @mapchip.chip_size.w }
        @cmodsy = @cmodsy.map{|v| v * @mapchip.chip_size.h }
        @mapchip_units = Array.new(@mapchip.chips){|idx|
          SpriteUnit.new(@baseimg.dp, @baseimg.bitmap,
                         (idx % @mapchip.size.w) * @mapchip.chip_size.w,
                         (idx / @mapchip.size.w) * @mapchip.chip_size.h, 
                         @baseimg.ow, @baseimg.oh, 0, 0, nil, Screen.rect)
        }
        resize
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

      def get_code(x, y) #:nodoc:
        pos = convert_position(x, y)
        return @mapdat[pos.y][pos.x]
      end

      def dispose #:nodoc:
        @mapdat = nil
        @baseimg = nil
      end

      def dp #:nodoc:
        return @baseimg.dp
      end

      def dp=(v) #:nodoc:
        @baseimg.dp = v
        @units.each{|u| u.dp = v }
      end

      def viewport=(vp) #:nodoc:
        @units.each{|u| u.viewport = vp }
      end
    end

  #===あとで書く
  #_mapchip_:: あとで書く
  #_layer_csv_:: あとで書く
  #返却値:: あとで書く
    def initialize(mapchip, layer_csv)
      @mapchip = mapchip
      @visible = false
      @pos = Point.new(0, 0)
      @view_pos = Point.new(0, 0)
      @viewport = Screen.rect
      @coll = Collision.new(Rect.new(0, 0, 0, 0), Point.new(0, 0))
      layer_data = CSV.readlines(layer_csv)
      raise MiyakoError, "This file is not Miyako Map Layer file! : #{layer_csv}" unless layer_data.shift[0] == "Miyako Maplayer"

      tmp = layer_data.shift # 空行の空読み込み

      layer_size = Size.new(*(tmp.map{|v| v.to_i}))
      @w = layer_size.w
      @h = layer_size.h
      
      layers = layer_data.shift[0].to_i
      
      brlist = {}
      layers.times{|n|
        name = layer_data.shift[0]
        if name == "<event>"
          name = :event
        else
          name = /\<(\d+)\>/.match(name).to_a[1].to_i
        end
        values = []
        layer_size.h.times{|y|
          values << layer_data.shift.map{|m| m.to_i}
        }
        brlist[name] = values
      }

      @map_layers = Array.new
      @event_layer = nil

      if brlist.has_key?(:event)
        @event_layer = Array.new
        brlist[:event].each_with_index{|ly, y|
          ly.each_with_index{|code, x|
            next unless MapEvent.include?(code)
            @event_layer.push(MapEvent.create(code, x * @mapchip.chip_size.w, y * @mapchip.chip_size.h))
          }
        }
        layers -= 1
      end

      @map_layers = []
      layers.times{|i|
        br = brlist[i].map{|b| b.map{|bb| bb >= @mapchip.chips ? -1 : bb } }
        @map_layers.push(MapLayer.new(@mapchip, br, layer_size))
      }
      @@maps.push(self)
    end

  #===あとで書く
  #_code_:: あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #返却値:: あとで書く
    def add_event(code, x, y)
      return unless MapEvent.include?(code)
      @event_layer.push(MapEvent.create(code, x, y))
    end

  #===あとで書く
  #_dx_:: あとで書く
  #_dy_:: あとで書く
  #_type_:: あとで書く
  #返却値:: あとで書く
    def move(dx,dy,type=:sync)
      unless type == :view
        @pos.x += dx
        @pos.y += dy
        @map_layers.each{|l|
          l.pos.x += dx
          l.pos.y += dy
        }
      end
      unless type == :position
        @view_pos.x += dx
        @view_pos.y += dy
        @map_layers.each{|l|
          l.view_pos.x += dx
          l.view_pos.y += dy
        }
      end
      return self
    end

  #===あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #_type_:: あとで書く
  #返却値:: あとで書く
    def move_to(x,y,type=:sync)
      px, py = @pos.x, @pos.y
      unless type == :view
        @pos.x = x
        @pos.y = y
        @map_layers.each{|l|
          l.pos.x = @pos.x
          l.pos.y = @pos.y
        }
      end
      unless type == :position
        @view_pos.x += x - px
        @view_pos.y += y - py
        @map_layers.each{|l|
          l.view_pos.x = @view_pos.x
          l.view_pos.y = @view_pos.y
        }
      end
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def sync
      @view_pos.x += @pos.x
      @view_pos.y += @pos.y
      @map_layers.each{|l|
        l.view_pos.x = @view_pos.x
        l.view_pos.y = @view_pos.y
      }
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def dp
       return @map_layers.collect{|l| l.dp }
    end

  #===あとで書く
  #_d_:: あとで書く
  #返却値:: あとで書く
    def dp=(d)
      dp = d
      @map_layers.each{|l|
        l.dp = dp
        dp += 100
      }
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def max_dp
      return @map_layers.map{|l| l.dp }.max
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def min_dp
      return @map_layers.map{|l| l.dp }.min
    end
    
  #===あとで書く
  #_dl_:: あとで書く
  #返却値:: あとで書く
    def set_dps(*dl)
      l = dl.length
      l = @map_layers.length if l > @map_layers.length
      l.length.each_with_index{|l, d| l.dp = dl[d] }
      return self
    end

    def layer(idx) #:nodoc:
      return @map_layers[idx]
    end

  #===あとで書く
  #返却値:: あとで書く
    def visible
      return @visible
    end

  #===あとで書く
  #_f_:: あとで書く
  #返却値:: あとで書く
    def visible=(f)
      @visible = f
      @map_layers.each{|ll| ll.visible = @visible }
    end

  #===あとで書く
  #返却値:: あとで書く
    def show
      self.visible = true
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def hide
      self.visible = false
      return self
    end

  #===あとで書く
  #_idx_:: あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #返却値:: あとで書く
    def get_code_real(idx, x = 0, y = 0)
      code = @map_layers[idx].get_code(x / @mapchip.chip_size[0], y / @mapchip.chip_size[1])
      yield code if block_given?
      return code
    end

  #===あとで書く
  #_idx_:: あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #返却値:: あとで書く
    def get_code(idx, x = 0, y = 0)
      code = @map_layers[idx].get_code(x, y)
      yield code if block_given?
      return code
    end
    
  #===あとで書く
  #_idx_:: あとで書く
  #_code_:: あとで書く
  #_base_:: あとで書く
  #返却値:: あとで書く
    def set_mapchip_base(idx, code, base)
      @map_layers[idx].mapchip_units[code] = base
      return self
    end

  #===あとで書く
  #_type_:: あとで書く
  #_size_:: あとで書く
  #_collision_:: あとで書く
  #返却値:: あとで書く
    def get_amount(type, size, collision)
      mma = MapMoveAmount.new([], collision.direction.dup)
      return mma if(mma.amount[0] == 0 && mma.amount[1] == 0)
      collision.pos  = Point.new(@pos[0], @pos[1])
      dx, dy = collision.direction[0]*collision.amount[0], collision.direction[1]*collision.amount[1]
      px1, px2 = (@pos[0]+dx) / @mapchip.chip_size[0], (@pos[0]+size[0]-1+dx) / @mapchip.chip_size[0]
      py1, py2 = (@pos[1]+dy) / @mapchip.chip_size[1], (@pos[1]+size[1]-1+dy) / @mapchip.chip_size[1]
      (py1..py2).each{|py|
        rpy = py * @mapchip.chip_size[1]
        (px1..px2).each{|px|
          rpx = px * @mapchip.chip_size[0]
          @map_layers.each_with_index{|ml, idx|
            code = ml.get_code(px, py)
            next if code == -1 # not use chip
            @coll.rect = @mapchip.collision_table[type][code]
            @coll.pos  = Point.new(rpx, rpy)
            atable = @mapchip.access_table[type][code]
            if @coll.into?(collision)
              mma.amount[0] = mma.amount[0] & atable[@@idx_ix[collision.direction[0]]]
              mma.amount[1] = mma.amount[1] & atable[@@idx_iy[collision.direction[1]]]
              mma.collisions << [idx, code, :into]
            end
          }
        }
      }
      mma.amount[0] *= collision.amount[0]
      mma.amount[1] *= collision.amount[1]
      yield mma if block_given?
      return mma
    end

  #===あとで書く
  #_type_:: あとで書く
  #_rect_:: あとで書く
  #_collision_:: あとで書く
  #返却値:: あとで書く
    def get_amount_by_rect(type, rect, collision)
      mma = MapMoveAmount.new([], collision.direction.dup)
      return mma if(mma.amount[0] == 0 && mma.amount[1] == 0)
      dx, dy = collision.direction[0]*collision.amount[0], collision.direction[1]*collision.amount[1]
      x, y = rect[0..1]
      collision.pos  = Point.new(x, y)
      px1, px2 = (x+dx) / @mapchip.chip_size[0], (x+rect[2]-1+dx) / @mapchip.chip_size[0]
      py1, py2 = (y+dy) / @mapchip.chip_size[1], (y+rect[3]-1+dy) / @mapchip.chip_size[1]
      (py1..py2).each{|py|
        rpy = py * @mapchip.chip_size[1]
        (px1..px2).each{|px|
          rpx = px * @mapchip.chip_size[0]
          @map_layers.each_with_index{|ml, idx|
            code = ml.get_code(px, py)
            next if code == -1 # not use chip
            @coll.rect = @mapchip.collision_table[type][code]
            @coll.pos  = Point.new(rpx, rpy)
            atable = @mapchip.access_table[type][code]
            if @coll.into?(collision)
              mma.amount[0] = mma.amount[0] & atable[@@idx_ix[collision.direction[0]]]
              mma.amount[1] = mma.amount[1] & atable[@@idx_iy[collision.direction[1]]]
              mma.collisions << [idx, code, :into]
            end
          }
        }
      }
      mma.amount[0] *= collision.amount[0]
      mma.amount[1] *= collision.amount[1]
      yield mma if block_given?
      return mma
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def chip_size
      return @mapchip.chip_size
    end

  #===あとで書く
  #返却値:: あとで書く
    def dispose
      @map_layers.each{|l|
        l.dispose
        l = nil
      }
      @map_layers = Array.new
      @event_layer.each{|e| e.final }
      @event_layer = nil
      @@maps.delete(self)
    end

    def re_size #:nodoc:
      @map_layers.each{|l| l.reSize }
      return self
    end

    def update(param = nil) #:nodoc:
      @map_layers.each{|l| l.update }
      if @visible && @event_layer
        @event_layer.each{|e|
          e.update(self, @event_layer, param)
        }
      end
    end

  #===あとで書く
  #返却値:: あとで書く
    def events
      return @event_layer || []
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def viewport
      return @viewport
    end
    
  #===あとで書く
  #_vp_:: あとで書く
  #返却値:: あとで書く
    def viewport=(vp)
      @viewport = vp
      @map_layers.each{|l| l.viewport = @viewport }
      @event_layer.each{|e| e.viewport = @viewport } if @event_layer
      return self
    end
    
    def Map::get_list #:nodoc:
      return @@maps
    end

    def Map::update #:nodoc:
      @@maps.each{|m| m.update}
    end

    def Map::reset_viewport #:nodoc:
      @@maps.each{|m| m.viewport = Screen.rect }
    end
  end

=begin rdoc
==あとで書く
=end
  class FixedMap
    include MiyakoTap
    include Layout
    
    @@maps = Array.new
    @@idx_ix = [-1, 2, 4]
    @@idx_iy = [-1, 0, 6]

    attr_reader :name, :map_layers, :pos, :w, :h

=begin rdoc
==あとで書く
=end
    class FixedMapLayer #:nodoc: all
      extend Forwardable

      @@use_chip_list = Hash.new(nil)
      
      attr_accessor :visible, :dp, :mapchip_units
      attr_reader :pos

      def update #:nodoc:
        return unless @visible
        pos = 0
        @ch.times{|y|
          m2 = @mapdat[@modpy2[y]]
          @cw.times{|x|
            code = m2[@modpx2[x]]
            next if code == -1
            mc = @mapchip_units[code].to_unit
            @units[pos].bitmap = mc.bitmap
            @units[pos].ow = mc.ow
            @units[pos].ox = mc.ox
            @units[pos].x = @pos.x + x * @baseimg.ow
            @units[pos].oh = mc.oh
            @units[pos].oy = mc.oy
            @units[pos].y = @pos.y + y * @baseimg.ow
            pos += 1
          }
        }
        Screen.sprite_list.concat(@units[0...pos])
      end

      #===画面に描画を指示する
      #現在の画像を、現在の状態で描画するよう指示する
      #--
      #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
      #++
      #返却値:: 自分自身を返す
      def render
        org_visible = @visible
        @visible = true # updateメソッド内でvisibleチェックがあるため
        self.update
        @visible = org_visible
        return self
      end

      def round(v, max) #:nodoc:
        v = max + (v % max) if v < 0
        v %= max if v >= max
        return v
      end

      def reSize #:nodoc:
        @cw = @real_size.w % @mapchip.chip_size.w == 0 ? @real_size.w / @mapchip.chip_size.w : (@real_size.w + @mapchip.chip_size.w - 1)/ @mapchip.chip_size.w + 1
        @ch = @real_size.h % @mapchip.chip_size.h == 0 ? @real_size.h / @mapchip.chip_size.h : (@real_size.h + @mapchip.chip_size.h - 1)/ @mapchip.chip_size.h + 1
        @units.clear if @units
        @units = Array.new
        if @baseimg
          @ch.times{|y|
            @cw.times{|x|
              @units.push(SpriteUnit.new(@baseimg.dp, @baseimg.bitmap, 0 , 0, 
                                         @baseimg.ow, @baseimg.oh, 0, 0, nil, Screen.rect))
            }
          }
        end
      end

      def initialize(mapchip, mapdat, layer_size, pos) #:nodoc:
        @mapchip = mapchip
        @pos = pos.dup
        @size = layer_size.dup
        @real_size = Size.new(@size.w * @mapchip.chip_size.w, @size.h * @mapchip.chip_size.h)
        @mapdat = mapdat
        @baseimg = nil
        @baseimg = @mapchip.chip_image
        @baseimg.ow = @mapchip.chip_size.w
        @baseimg.oh = @mapchip.chip_size.h
        @units = nil
        @visible = false
        @divpx = get_div_array(0, @real_size.w, @mapchip.chip_size.w)
        @divpy = get_div_array(0, @real_size.h, @mapchip.chip_size.h)
        @modpx = get_mod_array(0, @real_size.w, @mapchip.chip_size.w)
        @modpy = get_mod_array(0, @real_size.h, @mapchip.chip_size.h)
        @modpx2 = get_mod_array(0, @size.w * 2 + 1, @size.w)
        @modpy2 = get_mod_array(0, @size.h * 2 + 1, @size.h)
        @cdivsx = get_div_array(0, @mapchip.chips, @mapchip.size.w)
        @cmodsx = get_mod_array(0, @mapchip.chips, @mapchip.size.w)
        @cdivsy = get_div_array(0, @mapchip.chips, @mapchip.size.h)
        @cmodsy = get_mod_array(0, @mapchip.chips, @mapchip.size.h)
        @cdivsx = @cdivsx.map{|v| v * @mapchip.chip_size.w }
        @cdivsy = @cdivsy.map{|v| v * @mapchip.chip_size.h }
        @cmodsx = @cmodsx.map{|v| v * @mapchip.chip_size.w }
        @cmodsy = @cmodsy.map{|v| v * @mapchip.chip_size.h }
        @mapchip_units = Array.new(@mapchip.chips){|idx|
          SpriteUnit.new(@baseimg.dp, @baseimg.bitmap,
                         (idx % @mapchip.size.w) * @mapchip.chip_size.w,
                         (idx / @mapchip.size.w) * @mapchip.chip_size.h, 
                         @baseimg.ow, @baseimg.oh, 0, 0, nil, Screen.rect)
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

      def get_code(x, y) #:nodoc:
        pos = convert_position(x, y)
        return @mapdat[pos.y][pos.x]
      end

      def dispose #:nodoc:
        @mapdat = nil
        @baseimg = nil
      end

      def dp #:nodoc:
        return @baseimg.dp
      end

      def dp=(v) #:nodoc:
        @baseimg.dp = v
        @units.each{|u| u.dp = v}
      end

      def viewport=(vp) #:nodoc:
        @units.each{|u| u.viewport = vp }
      end

      def_delegators(:@size, :w, :h)
    end

  #===あとで書く
  #_mapchip_:: あとで書く
  #_layer_csv_:: あとで書く
  #_pos_:: あとで書く
  #返却値:: あとで書く
    def initialize(mapchip, layer_csv, pos = Point.new(0, 0))
      init_layout
      @mapchip = mapchip
      @visible = false
      @pos = Point.new(*(pos.to_a))
      @viewport = Screen.rect
      @coll = Collision.new(Rect.new(0, 0, 0, 0), Point.new(0, 0))
      layer_data = CSV.readlines(layer_csv)

      raise MiyakoError, "This file is not Miyako Map Layer file! : #{layer_csv}" unless layer_data.shift[0] == "Miyako Maplayer"

      tmp = layer_data.shift # 空行の空読み込み

      layer_size = Size.new(tmp[0].to_i, tmp[1].to_i)
      @w = layer_size.w * @mapchip.chip_size.w
      @h = layer_size.h * @mapchip.chip_size.h

      layers = layer_data.shift[0].to_i

      brlist = {}
      layers.times{|n|
        name = layer_data.shift[0]
        if name == "<event>"
          name = :event
        else
          name = /\<(\d+)\>/.match(name).to_a[1].to_i
        end
        values = []
        layer_size.h.times{|y|
          values << layer_data.shift.map{|m| m.to_i}
        }
        brlist[name] = values
      }

      @map_layers = Array.new
      @event_layer = nil
      if brlist.has_key?(:event)
        @event_layer = Array.new
        brlist[:event].each_with_index{|ly, y|
          ly.each_with_index{|code, x|
            next unless MapEvent.include?(code)
            @event_layer.push(MapEvent.create(code, x * @mapchip.chip_size.w, y * @mapchip.chip_size.h))
          }
        }
        layers -= 1
      end
      @map_layers = []
      layers.times{|i|
        br = brlist[i].map{|b| b.map{|bb| bb >= @mapchip.chips ? -1 : bb } }
        @map_layers.push(FixedMapLayer.new(@mapchip, br, layer_size, pos))
      }
      set_layout_size(@w, @h)
      @@maps.push(self)
    end

  #===あとで書く
  #_code_:: あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #返却値:: あとで書く
    def add_event(code, x, y)
      return unless MapEvent.include?(code)
      @event_layer.push(MapEvent.create(code, x, y))
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def update_layout_position
      d = Point.new(@layout.pos[0]-@pos.x, @layout.pos[1]-@pos.y)
      @pos.x = @layout.pos[0]
      @pos.y = @layout.pos[1]
      @map_layers.each{|ml| ml.pos.x, ml.pos.y = @pos.x, @pos.y }
      @event_layer.each{|e| e.update_position(d) }
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def dp
       return @map_layers.collect{|l| l.dp }
    end

  #===あとで書く
  #_d_:: あとで書く
  #返却値:: あとで書く
    def dp=(d)
      dp = d
      @map_layers.each{|l|
        l.dp = dp
        dp += 100
      }
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def max_dp
      return @map_layers.map{|l| l.dp }.max
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def min_dp
      return @map_layers.map{|l| l.dp }.min
    end
    
  #===あとで書く
  #_dl_:: あとで書く
  #返却値:: あとで書く
    def setDPs(*dl)
      l = dl.length
      l = @map_layers.length if l > @map_layers.length
      l.length.each_with_index{|l, d| l.dp = dl[d]}
      return self
    end

    def layer(idx) #:nodoc:
      return @map_layers[idx]
    end

  #===あとで書く
  #返却値:: あとで書く
    def visible
      return @visible
    end

  #===あとで書く
  #_f_:: あとで書く
  #返却値:: あとで書く
    def visible=(f)
      @visible = f
      @map_layers.each{|ll| ll.visible = @visible }
    end

  #===あとで書く
  #返却値:: あとで書く
    def show
      self.visible = true
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def hide
      self.visible = false
      return self
    end

  #===あとで書く
  #_idx_:: あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #返却値:: あとで書く
    def get_code_real(idx, x, y)
      code = @map_layers[idx].get_code((x-@pos[0]) / @mapchip.chip_size[0], (y-@pos[1]) / @mapchip.chip_size[1])
      yield code if block_given?
      return code
    end

  #===あとで書く
  #_idx_:: あとで書く
  #_x_:: あとで書く
  #_y_:: あとで書く
  #返却値:: あとで書く
    def get_code(idx, x, y)
      code = @map_layers[idx].get_code(x, y)
      yield code if block_given?
      return code
    end

  #===あとで書く
  #_idx_:: あとで書く
  #_code_:: あとで書く
  #_base_:: あとで書く
  #返却値:: あとで書く
    def set_mapchip_base(idx, code, base)
      @map_layers[idx].mapchip_units[code] = base
      return self
    end

  #===あとで書く
  #_type_:: あとで書く
  #_rect_:: あとで書く
  #_collision_:: あとで書く
  #返却値:: あとで書く
    def get_amount_by_rect(type, rect, collision)
      mma = MapMoveAmount.new([], collision.direction.dup)
      return mma if(mma.amount[0] == 0 && mma.amount[1] == 0)
      dx, dy = collision.direction[0]*collision.amount[0], collision.direction[1]*collision.amount[1]
      x, y = rect[0]-@pos[0], rect[1]-@pos[1]
      collision.pos = Point.new(x, y)
      px1, px2 = (x+dx) / @mapchip.chip_size[0], (x+rect[2]-1+dx) / @mapchip.chip_size[0]
      py1, py2 = (y+dy) / @mapchip.chip_size[1], (y+rect[3]-1+dy) / @mapchip.chip_size[1]
      (py1..py2).each{|py|
        rpy = py * @mapchip.chip_size[1]
        (px1..px2).each{|px|
          rpx = px * @mapchip.chip_size[0]
          @map_layers.each_with_index{|ml, idx|
            code = ml.get_code(px, py)
            next if code == -1 # not use chip
            @coll.rect = @mapchip.collision_table[type][code]
            @coll.pos  = Point.new(rpx, rpy)
            atable = @mapchip.access_table[type][code]
            if @coll.into?(collision)
              mma.amount[0] = mma.amount[0] & atable[@@idx_ix[collision.direction[0]]]
              mma.amount[1] = mma.amount[1] & atable[@@idx_iy[collision.direction[1]]]
              mma.collisions << [idx, code, :into]
            end
          }
        }
      }
      mma.amount[0] *= collision.amount[0]
      mma.amount[1] *= collision.amount[1]
      yield mma if block_given?
      return mma
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def chipSize
      return @mapchip.chip_size
    end

  #===あとで書く
  #_pos_:: あとで書く
  #返却値:: あとで書く
    def get_view_position(pos)
      return Point.new(pos[0] + @pos.x, pos[1] + @pos.y)
    end

  #===あとで書く
  #返却値:: あとで書く
    def dispose
      @map_layers.each{|l|
        l.dispose
        l = nil
      }
      @map_layers = Array.new
      @event_layer.each{|e| e.final }
      @event_layer = nil
      @@maps.delete(self)
    end

    def re_size #:nodoc:
      @map_layers.each{|l| l.reSize }
      return self
    end

    def update(param = nil) #:nodoc:
      @map_layers.each{|l| l.update }
      if @visible && @event_layer
        @event_layer.each{|e|
          e.update(self, @event_layer, param)
        }
      end
    end

  #===あとで書く
  #返却値:: あとで書く
    def events
      return @event_layer || []
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def viewport
      return @viewport
    end
    
  #===あとで書く
  #_vp_:: あとで書く
  #返却値:: あとで書く
    def viewport=(vp)
      @layout.viewport = vp
      @viewport = vp
      @map_layers.each{|l| l.viewport = @viewport }
      @event_layer.each{|e| e.viewport = @viewport } if @event_layer
      return self
    end
    
    def FixedMap::get_list #:nodoc:
      return @@maps
    end

    def FixedMap::update #:nodoc:
      @@maps.each{|m| m.update}
    end

    def FixedMap::reset_viewport #:nodoc:
      @@maps.each{|m| m.viewport = Screen.rect }
    end
  end

=begin
==マップ上のイベントを管理するクラス
=end
  module MapEvent
    
    @@id2event = Hash.new

    # イベントインスタンスに固有の名前
    attr_accessor :name

    #===イベントのインスタンスを作成する
    #引数として渡せるX,Y座標の値は、表示上ではなく理論上の座標位置
    #_x_:: マップ上のX座標の値。デフォルトは0
    #_y_:: マップ上のY座標の値。デフォルトは0
    #_name_:: インスタンス固有の名称。nameメソッドで参照・更新可能。
    #デフォルトはnil(自動的に、__id__.to_sが挿入される)
    #返却値:: 生成されたインスタンス
    def initialize(x = 0, y = 0, name = nil)
      @event_pos = Point.new(x, y)
      @delta = Point.new(0, 0)
      init
    end

    #===イベントクラスをマップに追加登録する
    #_id_:: マップ(イベントレイヤ)上の番号。
    #イベントレイヤ上に存在しない番号を渡してもエラーや警告は発しない
    #_event_:: イベントクラス。クラスのインスタンスではないことに注意！
    def MapEvent.add(id, event)
      @@id2event[id] = event
    end

    #===イベントが登録されているかを確認する
    #引数で渡した番号に対応するイベントクラスが登録されているかどうかを確認する
    #_id_:: イベントクラスに対応した番号
    #返却値:: イベントクラスが登録されている時はtrueを返す
    def MapEvent.include?(id)
      return @@id2event.has_key?(id)
    end

    #===イベントのインスタンスを生成する(番号指定)
    #インスタンス生成と同時に、マップ上の座標を渡して初期位置を設定する
    #
    #設置は、マップ上の座標に設置する。表示上の座標ではない事に注意。
    #_id_:: イベントクラスと登録した際の番号
    #_x_:: イベントを設置する位置(X座標)
    #_y_:: イベントを設置する位置(Y座標)
    #返却値:: 生成したインスタンス
    def MapEvent.create(id, x, y)
      return @@id2event[id].new(x, y)
    end

    #===すべての登録済みイベントクラスの登録を解除する
    def MapEvent.clear
      @@id2event.keys.each{|k|
        @@id2event[k] = nil
      }
    end

    #===イベント生成時のテンプレートメソッド
    #イベントクラスからインスタンスが生成された時の初期化処理を記述する
    def init
    end

    def update_position(new_pos) #:nodoc:
      @delta.x = new_pos.x
      @delta.y = new_pos.y
      update_pos
    end
    
    #===位置移動時の処理のテンプレートメソッド
    #指定のインスタンスの位置を移動した時に呼ばれる。
    # @delta(Point構造体)に移動量が設定されている
    def update_pos
    end
    
    #===インスタンス内の表示やデータを更新するテンプレートメソッド
    #マップ画像が更新された時に呼び出される
    #_map_obj_:: インスタンスが組み込まれているMap/FixedMapクラスのインスタンス
    #_events_:: マップに登録されているイベントインスタンスの配列
    #_params_:: 開発者が明示的に用意した引数。内容はハッシュ
    def update(map_obj, events, params)
    end

    #===あとで書く
    #_param_:: あとで書く
    #返却値:: あとで書く
    def met?(param)
    end
    
    #===画面に描画を指示する(テンプレートメソッド)
    #現在の画像を、現在の状態で描画するよう指示する
    #(イベント内部で用意している画像の描画指示するためのテンプレートメソッド)
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      return self
    end

    #===あとで書く
    #_param_:: あとで書く
    #返却値:: あとで書く
    def execute(param)
    end
    
    #===あとで書く
    #返却値:: あとで書く
    def final
    end

    #===あとで書く
    #返却値:: あとで書く
    def dispose
    end

    #===あとで書く
    #返却値:: あとで書く
    def viewport
      return Screen.rect
    end
    
    #===あとで書く
    #_vp_:: あとで書く
    #返却値:: あとで書く
    def viewport=(vp)
      @viewport = vp
      @map_layers.each{|l| l.viewport = @viewport }
      @event_layer.each{|e| e.viewport = @viewport } if @event_layer
    end
  end
end
