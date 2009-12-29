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

module Miyako
  #==マップ上のイベント全体を管理するクラス
  #Map/FixedMapクラス内で使用する
  #使い方：
  #
  #(1)インスタンスを生成する
  #
  #em = MapEventManager.new
  #
  #(2)MapEventクラスとIDを登録する
  #
  #(例)MapEventモジュールをmixinしたクラスXを、ID=0のイベントとして登録
  #
  #em.add(0, X)
  #
  #(3)Map/FixedMapクラスインスタンス生成時に引数として渡す
  #
  #@map = Map.new(...,em)
  #
  #(注)登録するIDは、イベントレイヤー上の番号と対応しておくこと
  class MapEventManager
    #===インスタンスを生成する
    #_map_obj_:: Managerが属するMap/FixedMapクラスのインスタンス
    #返却値:: 生成されたインスタンス
    def initialize
      @map = nil
      @id2event = Hash.new
    end

    def initialize_copy(obj) #:nodoc:
      @map = @map.dup if @map
      @id2event = @id2event.dup
    end

    def set(map) #:nodoc:
      @map = map
    end

    #===イベントクラスをマップに追加登録する
    #_id_:: イベント番号(0以上の整数)
    #_event_:: イベントクラス。クラスのインスタンスではないことに注意！
    #返却値:: 自分自身を返す
    def add(id, event)
      @id2event[id] = event
      return self
    end

    #===イベント番号に関連づけれられているイベントクラスを返す
    #引数で渡した番号に対応するイベントクラス(クラスそのもの)を返す
    #引数idが未登録のイベント番号だったときはnilが返る
    #_id_:: イベント番号
    #返却値:: イベントクラス(classクラスインスタンス)もしくはnil
    def [](id)
      return @id2event[id]
    end

    #===イベントクラスに関連づけれられているイベント番号を返す
    #引数で渡したイベントクラスに対応するイベント番号を返す
    #引数eventが未登録のイベント番号だったときはnilが返る
    #_event_:: イベントクラス
    #返却値:: イベント番号(0以上の整数)もしくはnil
    def to_id(event)
      return @id2event.key(event)
    end

    #===イベントが登録されているかを確認する
    #引数で渡した番号に対応するイベントクラスが登録されているかどうかを確認する
    #idに関連づけられたイベントクラスが登録されている時はtrueを返す
    #_id_:: イベント番号
    #返却値:: true/false
    def include?(id)
      return @id2event.has_key?(id)
    end

    #===イベントのインスタンスを生成する(番号指定)
    #インスタンス生成と同時に、マップ上の座標を渡して初期位置を設定する
    #登録していないIDを指定するとエラーになる
    #
    #設置は、マップ上の座標に設置する。表示上の座標ではない事に注意。
    #_id_:: イベントクラスと登録した際の番号
    #_x_:: イベントを設置する位置(X座標)
    #_y_:: イベントを設置する位置(Y座標)
    #返却値:: 生成したインスタンス
    def create(id, x = 0, y = 0)
      raise MiyakoError, "This MapEventManager instance is not set Map/FixedMap instance!" unless @map
      raise MiyakoError, "Unknown Map Event ID! : #{id}" unless include?(id)
      return @id2event[id].new(@map, x, y)
    end

    #===すべての登録済みイベントクラスの登録を解除する
    def clear
      @id2event.keys.each{|k| @id2event[k] = nil }
    end

    def dispose
      @map = nil
      @id2event.clear
      @id2event = nil
    end
  end

  #==マップ上のイベントを管理するモジュール
  #実際に使う際にはmix-inして使う
  module MapEvent
    include SpriteBase
    include Animation

    #===イベントのインスタンスを作成する
    #引数として渡せるX,Y座標の値は、表示上ではなく理論上の座標位置
    #_map_obj_:: 関連づけられたMap/FixedMapクラスのインスタンス
    #_x_:: マップ上のX座標の値。デフォルトは0
    #_y_:: マップ上のY座標の値。デフォルトは0
    #返却値:: 生成されたインスタンス
    def initialize(map_obj, x = 0, y = 0)
      init(map_obj, x, y)
    end

    #===イベント生成時のテンプレートメソッド
    #イベントクラスからインスタンスが生成された時の初期化処理を実装する
    #_map_obj_:: 関連づけられたMap/FixedMapクラスのインスタンス
    #_x_:: マップ上のX座標の値
    #_y_:: マップ上のY座標の値
    def init(map_obj, x, y)
    end

    #===インスタンス内の表示やデータを更新するテンプレートメソッド
    #マップ画像が更新された時に呼び出す
    #_map_obj_:: インスタンスが組み込まれているMap/FixedMapクラスのインスタンス
    #_events_:: マップに登録されているイベントインスタンスの配列
    #_params_:: 開発者が明示的に用意した引数。内容はハッシュ
    def update(map_obj, events, params)
    end

    #===インスタンス内の表示やデータを更新するテンプレートメソッド
    #独自に更新を行いたいときに呼び出される
    #_params_:: 開発者が明示的に用意した引数。可変引数
    def update2(*params)
    end

    #===イベントを指定の分量で移動させる(テンプレートメソッド)
    #_dx_:: 移動量(x座標)。単位はピクセル
    #_dy_:: 移動量(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 自分自身を返す
    def move!(dx,dy,*params)
      return self
    end

    #===イベントを指定の位置へ移動させる(テンプレートメソッド)
    #_x_:: 移動先の位置(x座標)。単位はピクセル
    #_y_:: 移動先の位置(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 自分自身を返す
    def move_to!(x,y,*params)
      return self
    end

    #===イベントを指定の分量で移動させる(テンプレートメソッド)
    #スプライトのみを移動させるときにオーバーライドする
    #_dx_:: 移動量(x座標)。単位はピクセル
    #_dy_:: 移動量(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 自分自身を返す
    def sprite_move!(dx,dy,*params)
      return self
    end

    #===イベントを指定の位置へ移動させる(テンプレートメソッド)
    #スプライトのみを移動させるときにオーバーライドする
    #_x_:: 移動先の位置(x座標)。単位はピクセル
    #_y_:: 移動先の位置(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 自分自身を返す
    def sprite_move_to!(x,y,*params)
      return self
    end

    #===イベントを指定の分量で移動させる(テンプレートメソッド)
    #論理的な位置のみを移動させるときにオーバーライドする
    #_dx_:: 移動量(x座標)。単位はピクセル
    #_dy_:: 移動量(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 自分自身を返す
    def pos_move!(dx,dy,*params)
      return self
    end

    #===イベントを指定の位置へ移動させる(テンプレートメソッド)
    #論理的な位置のみを移動させるときにオーバーライドする
    #_x_:: 移動先の位置(x座標)。単位はピクセル
    #_y_:: 移動先の位置(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 自分自身を返す
    def pos_move_to!(x,y,*params)
      return self
    end

    #===イベントを指定の分量で移動させたときの値を求める(テンプレートメソッド)
    #_dx_:: 移動量(x座標)。単位はピクセル
    #_dy_:: 移動量(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 移動した位置のインスタンスを返す
    def move(dx,dy,*params)
      return Point.new(0,0)
    end

    #===イベントを指定の位置へ移動させたときの値を求める(テンプレートメソッド)
    #_x_:: 移動先の位置(x座標)。単位はピクセル
    #_y_:: 移動先の位置(y座標)。単位はピクセル
    #_params_:: move呼び出し時に渡された引数。可変個数
    #返却値:: 移動した位置のインスタンスを返す
    def move_to(x,y,*params)
      return Point.new(0,0)
    end

    #===イベント発生可否問い合わせ(テンプレートメソッド)
    #イベント発生が可能なときはtrueを返す(その後、startメソッドを呼び出す)処理を実装する
    #_param_:: 問い合わせに使用するパラメータ群。デフォルトはnil
    #返却値:: イベント発生可能ならばtrue
    def met?(*params)
      return false
    end

    #===画面に画像を描画する(テンプレートメソッド)
    #イベントで所持している画像を描画するメソッドを実装する
    #(イベント内部で用意している画像の描画用テンプレートメソッド)
    def render
    end

    #===イベントを発生させる(テンプレートメソッド)
    #ここに、イベント発生イベントを実装する。更新はupdateメソッドに実装する
    #_param_:: イベント発生に必要なパラメータ群。デフォルトはnil
    #返却値:: 自分自身を返す
    def start(*params)
      return self
    end

    #===イベントを停止・終了させる(テンプレートメソッド)
    #ここに、イベント停止・終了イベントを実装する。更新はupdateメソッドに実装する
    #_param_:: イベント発生に必要なパラメータ群。デフォルトはnil
    #返却値:: 自分自身を返す
    def stop(*params)
      return self
    end

    #===イベント発生中問い合わせ(テンプレートメソッド)
    #ここに、イベント発生中の問い合わせ処理を実装する。
    #_param_:: あとで書く
    #返却値:: イベント発生中の時はtrue
    def executing?
      return false
    end

    #===イベント終了後の後処理(テンプレートメソッド)
    #ここに、イベント終了後の後処理を実装する。
    def final
    end

    #===イベントに使用しているインスタンスを解放する(テンプレートメソッド)
    #ここに、インスタンス解放処理を実装する。
    def dispose
    end
  end
end
