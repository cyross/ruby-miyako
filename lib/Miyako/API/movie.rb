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

module Miyako
  #==動画管理クラス
  #動画ファイル(MPEGファイル限定)をロード・再生するクラス
  class Movie
    include SpriteBase
    include Layout
    extend Forwardable

    @@movie_list = []
    
    #===動画のインスタンスを作成する
    #(但し、現在の所、loopパラメータは利用できない)
    #_fname_:: 動画ファイル名
    #_loops_:: ループ再生の可否。ループ再生させるときは true を渡す
    #返却値:: 生成したインスタンス
    def initialize(fname, loops = true)
      init_layout

      @x = 0
      @y = 0
      
      @movie = SDL::MPEG.load(fname)
      @size = Size.new(@movie.info.width, @movie.info.height)
      set_layout_size(*(@size.to_a))

      @sprite = Sprite.new({:size=>@size , :type=>:movie})
      @sprite.snap(self)
      
      @movie.enable_audio(true) unless $not_use_audio
      @movie.enable_video(true)
      @movie.set_loop(loops)
      
      @movie.set_display(@sprite.bitmap)
      @movie.scale(1.0)
      @@movie_list.push(self)
    end

    def update_layout_position #:nodoc:
      @x = @layout.pos[0]
      @y = @layout.pos[1]
      @sprite.move_to(*@layout.pos)
    end
    
    #===動画再生時の音量を指定する
    #_v_:: 指定する音量。(0～100までの整数)
    def set_volume(v)
      return if v < 0 || v > 100 || $not_use_audio
      @movie.set_volume(v)
    end

    #===動画再生中かを返す
    #返却値:: 再生中のときは true を返す
    def playing?
      return @movie.status == SDL::MPEG::PLAYING
    end

    #===動画データを解放する
    def dispose
      @movie.stop if playing?
      @sprite.dispose
      layout_dispose
      @@movie_list.delete(self)
      @movie = nil
    end

    #===再生領域の範囲を設定する
    #元動画のうち、表示させたい箇所を Rect クラスのインスタンスか4要素の配列で指定する
    #_rect_:: 再生領域。
    def region(rect)
      @movie.set_display_region(*(rect.to_a))
    end

    #===動画の再生を一時停止する
    #再生を裁可するには、 Miyako::Movie#rewind メソッドを呼び出す必要がある
    #_pause_by_input_:: ダミー
    def pause(pause_by_input)
      @movie.pause
    end

    #===動画を再生させる
    #動画の先頭から再生する。ブロックを渡したときは、ブロックを評価している間動画を再生する
    #_vol_:: 動画再生時の音量。0～100の整数
    def start(vol = nil)
      set_volume(vol) if vol
      @movie.play
      if block_given?
        yield self
        @movie.stop
      end
    end

    #===動画再生を停止する
    def stop
      @movie.stop
    end

    #===再生中の動画の再生位置を返す
    #位置は秒単位で返す
    #返却値:: 再生位置
    def current
      return @movie.info.current_time
    end

    #===動画の長さを返す
    #長さは、秒単位で返す。
    #返却値:: 動画の長さ
    def length
      return @movie.info.total_time
    end

    #===画面に描画を指示する
    #現在表示できる選択肢を、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      @sprite.render
      return self
    end
    
    #===一時停止中の動画の再生を再開する
    #Miyako::Movie#pause メソッドを実行した後に呼び出す
    def_delegators(:@movie, :rewind)
    #===指定時間ぶん、スキップ再生を行う
    #size:: スキップ長(秒単位)
    def_delegators(:@movie, :skip)
    def_delegators(:@sprite, :rect, :broad_rect, :ox, :oy)
  end
end
