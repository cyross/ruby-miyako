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

module Miyako
  #==マップチップ構造体に配列化メソッド(to_a)を定義するための構造体クラス
  #インデックス参照メソッドを追加
  class MapChipStruct < Struct
    #===インスタンスを配列化する
    #Map/FixedMap.newメソッド内部で、MapChip構造体と、その配列とのダックタイピングのために用意
    #返却値:: 自分自身を[]囲んだオブジェクトを返す
    def to_a
      return [self]
    end
  end

  #=マップチップ定義構造体
  MapChip = MapChipStruct.new(:chip_image, :chips, :size, :chip_size, :access_types, :collision_table, :access_table)

  #=マップチップ作成ファクトリクラス
  class MapChipFactory
    #===CSVファイルからMapChip構造体を生成する
    #_csv_filename_:: マップチップファイル名(CSVファイル)
    #_use_alpha_:: 画像にαチャネルを使うかどうかのフラグ。trueのときは画像のαチャネルを使用、falseのときはカラーキーを使用。デフォルトはtrue
    #返却値:: MapChip構造体
    def MapChipFactory.load(csv_filename, use_alpha = true)
      raise MiyakoIOError.no_file(csv_filename) unless File.exist?(csv_filename)
      lines = CSV.read(csv_filename)
      raise MiyakoFileFormatError, "This file is not Miyako Map Chip file! : #{csv_filename}" unless lines.shift[0] == "Miyako Mapchip"
      spr = use_alpha ? Sprite.new({:filename => lines.shift[0], :type => :alpha_channel}) : Sprite.new({:file_name => lines.shift[0], :type => :color_key})
      tmp = lines.shift
      chip_size = Size.new(tmp[0].to_i, tmp[1].to_i)
      size = Size.new(spr.w / chip_size.w, spr.h / chip_size.h)
      chips = size.w * size.h
      access_types = lines.shift[0].to_i
      collision_table = Array.new(access_types){|at|
        Array.new(chips){|n| Collision.new(lines.shift.map{|s| s.to_i}) }
      }
      access_table = Array.new(access_types){|at|
        Array.new(chips){|n|
          lines.shift.map{|s|
            v = eval(s)
            next v if (v == true || v == false)
            v = v.to_i
            next false if v == 0
            true
          }
        }
      }
      return MapChip.new(spr, chips, size, chip_size, access_types, collision_table, access_table)
    end

    #===スプライトからMapChip構造体を生成する
    #CSVファイルからではなく、独自に用意したデータからMapChip構造体を生成する
    #このとき、マップチップの大きさは、引数として渡すスプライトのow,ohから算出する
    #collision_tableは、すべてのチップで[0,0,ow,oh]として生成する
    #access_tableは、すべての方向でtrueとして設定する
    #_sprite_:: マップチップが描かれているスプライト
    #_access_types_:: アクセス形式の数。0以下の時はMiyakoValueErrorが発生する。省略時は1
    #返却値:: MapChip構造体
    def MapChipFactory.create(sprite, access_types = 1)
      raise MiyakoValueErro, "illegal access types! needs >1 : #{access_types}" if access_types < 1
      chip_size = Size.new(sprite.ow, sprite.oh)
      size = Size.new(sprite.w / chip_size.w, sprite.h / chip_size.h)
      chips = size.w * size.h
      ctable = Array.new(access_types){|at| Array.new(chips){|n| Collision.new([0,0,chip_size.w,chip_size.h]) } }
      atable = Array.new(access_types){|at| Array.new(chips){|n| [true] * 8 } }
      return MapChip.new(sprite, chips, size, chip_size, access_types, ctable, atable)
    end

    #===スプライトからMapChip構造体を生成する
    #CSVファイルからではなく、独自に用意したデータからMapChip構造体を生成する
    #このとき、マップチップの大きさは、引数sizeを使用する
    #collision_tableは、すべてのチップで[0,0,ow,oh]として生成する
    #access_tableは、すべての方向でtrueとして設定する
    #_sprite_:: マップチップが描かれているスプライト
    #_size_:: マップチップの大きさ(Size構造体)
    #_access_types_:: アクセス形式の数。0以下の時はMiyakoValueErrorが発生する。省略時は1
    #返却値:: MapChip構造体
    def MapChipFactory.create_with_size(sprite, size, access_types = 1)
      raise MiyakoValueErro, "illegal access types! needs >1 : #{access_types}" if access_types < 1
      chip_size = Size.new(size[0], size[1])
      size = Size.new(sprite.w / chip_size.w, sprite.h / chip_size.h)
      chips = size.w * size.h
      ctable = Array.new(access_types){|at| Array.new(chips){|n| Collision.new([0,0,chip_size.w,chip_size.h]) } }
      atable = Array.new(access_types){|at| Array.new(chips){|n| [true] * 8 } }
      return MapChip.new(sprite, chips, size, chip_size, access_types, ctable, atable)
    end

    #===全方向移動可能なAccessTableを作成
    #要素がすべてtrueの配列を生成する
    #返却値:: 生成した配列
    def MapChipFactory.all_access_table
      [true] * 8
    end

    #===完全に移動不可なAccessTableを作成
    #要素がすべてfalseの配列を生成する
    #返却値:: 生成した配列
    def MapChipFactory.not_access_table
      [false] * 8
    end
  end

  #==マップチップ構造体に配列化メソッド(to_a)を定義するための構造体クラス
  #インデックス参照メソッドを追加
  class MapStructStruct < Struct
    #===インスタンスを配列化する
    #Map/FixedMap.newメソッド内部で、MapChip構造体と、その配列とのダックタイピングのために用意
    #返却値:: 自分自身を[]囲んだオブジェクトを返す
    def to_a
      return [self]
    end
  end

  #=マップチップ定義構造体
  MapStruct = MapStructStruct.new(:size, :layer_num, :layers, :elayer_num, :elayers)

  #=マップ作成ファクトリクラス
  class MapStructFactory
    #===CSVファイルからMapStruct構造体を生成する
    #_csv_filename_:: マップファイル名(CSVファイル)
    #返却値:: 生成したMapStruct構造体
    def MapStructFactory.load(csv_filename)
      raise MiyakoIOError.no_file(csv_filename) unless File.exist?(csv_filename)
      layer_data = CSV.readlines(csv_filename)
      raise MiyakoFileFormatError, "This file is not Miyako Map Layer file! : #{csv_filename}" unless layer_data.shift[0] == "Miyako Maplayer"

      tmp = layer_data.shift # 空行の空読み込み

      size = Size.new(*(tmp[0..1].map{|v| v.to_i}))

      layers = layer_data.shift[0].to_i

      elayer = []
      layer  = []
      layers.times{|n|
        name = layer_data.shift[0]
        values = []
        size.h.times{|y|
          values << layer_data.shift.map{|m| m.to_i}
        }
        if name == "<event>"
          elayer << values
        else
          layer << values
        end
      }

      return MapStruct.new(size, layer.length, layer, elayer.length, elayer)
    end

    #===MapStruct構造体を生成する
    #マップの大きさ・マップレイヤーを構成する配列・イベントレイヤーを構成する配列から
    #MapChip構造体を生成する
    #それぞれ構成を確認し、合致しないときはMiyakoErrorを返す
    #
    #(例)access_type数2、レイヤー階層1層、縦5、横6のとき
    #[[[-1,-1,-1,-1,-1,-1],
    #  [-1, 1, 1, 1, 1,-1],
    #  [-1, 1, 0, 0, 1,-1],
    #  [-1, 1, 1, 1, 1,-1],
    #  [-1,-1,-1,-1,-1,-1]]
    #
    # [[-1,-1,-1,-1,-1,-1],
    #  [-1,-1, 2, 2,-1,-1],
    #  [-1, 2, 1, 1, 2,-1],
    #  [-1,-1, 2, 2,-1,-1],
    #  [-1,-1,-1,-1,-1,-1]]]
    #
    #_size_:: マップの大きさ。マップチップ単位・Size構造体インスタンスを渡す
    #_layers_:: マップチップIDの並びを示す配列
    #_elayers_:: イベントIDの並びを示す配列。使用しないときは省略(nilを渡す)
    #返却値:: 生成したMapStruct構造体
    def MapStructFactory.create(size, layers, elayers=nil)
      raise MiyakoError, "layer access types and event layer access types is not equal." if elayers && layers.length != elayers.length
      layers.each{|layer|
        raise MiyakoError, "layer height and size.h is not equal." if layer.length != size[1]
        layer.each{|line| raise MiykaoError, "layer width and size.w is not equal." if line.length != size[0] }
      }
      if elayers
        elayers.each{|layer|
          raise MiyakoError, "event layer height and size.h is not equal." if layer.length != size[1]
          layer.each{|line| raise MiykaoError, "event layer width and size.w is not equal." if line.length != size[0] }
        }
      end
      return MapStruct.new(Size.new(*size), layers.length, layers, elayers ? elayers.length : 0, elayers)
    end

    #===すべて未定義のマップレイヤー配列を作成する
    #すべての要素の値が-1(未定義)のレイヤー配列を生成する。
    #
    #(例)縦5、横6(MapStructFactory.undefined_layer([6,5])のとき
    #[[-1,-1,-1,-1,-1,-1],
    # [-1,-1,-1,-1,-1,-1],
    # [-1,-1,-1,-1,-1,-1],
    # [-1,-1,-1,-1,-1,-1],
    # [-1,-1,-1,-1,-1,-1]]
    #
    #_size_:: マップの大きさ。マップチップ単位・Size構造体インスタンスを渡す
    #返却値:: 生成したレイヤー配列
    def MapStructFactory.undefined_layer(size)
      return Array.new(size[1]){ Array.new(size[0]){ -1 }}
    end
  end

  #==アクセス方向定義クラス
  #マップチップのアクセステーブルを参照する際に、状態(入る(:in)・出る(:out))と
  #方向(:left, :right, :up, :down)から、アクセステーブルの指標を取得する必要がある。
  #このクラスでは、その指標を取得するメソッドを用意している
  class MapDir
    @@accesses = {
      in:  { right: 2, left: 4, up: 6, down: 0},
      out: { right: 3, left: 5, up: 1, down: 7}
    }
    @@accesses2 = {
      in:  [[-1,0,6],[2,-1,-1],[4,-1,-1]],
      out: [[-1,7,1],[3,-1,-1],[5,-1,-1]]
    }

    #===状態と方向からアクセステーブルの指標を取得する
    #アクセステーブルには、2種類の状態(入る=:in, 出る=:out)と、
    #4種類の方向(左=:left, 右=:right, 上=:up, 下=:down)から構成される
    #配列となっている。本メソッドで、状態・方向に対応するシンボルから配列の要素指標を取得する。
    #指定外のシンボルを渡すと例外が発生する
    #_state_:: 状態を示すシンボル(:in, :out)
    #_direction_:: 方向を示すシンボル(:left, :right, :up, :down)
    #返却値:: アクセステーブルの指標番号(整数)
    def MapDir.index(state, direction)
      raise MiyakoValueError, "can't find AcceessIndex state symbol! #{state}" unless @@accesses.has_key?(state)
      raise MiyakoValueError, "can't find AcceessIndex direction symbol! #{direction}" unless @@accesses[state].has_key?(direction)
      return @@accesses[state][direction]
    end

    #===状態と移動量からアクセステーブルの指標を取得する
    #アクセステーブルには、2種類の状態(入る=:in, 出る=:out)と、移動量(dx,dy)から構成される
    #配列となっている。本メソッドで、状態に対応するシンボル、整数から配列の要素指標を取得する。
    #指定外のシンボルを渡すと例外が発生する
    #_state_:: 状態を示すシンボル(:in, :out)
    #_dx_:: x方向移動量
    #_dy_:: y方向移動量
    #返却値:: アクセステーブルの指標番号(整数)。何も移動しない場合は-1が返る
    def MapDir.index2(state, dx, dy)
      raise MiyakoValueError, "can't find AcceessIndex state symbol! #{state}" unless @@accesses.has_key?(state)
      return @@accesses2[state][dx < -1 ? -1 : dx > 1 ? 1 : 0][dy < -1 ? -1 : dy > 1 ? 1 : 0]
    end
  end
end
