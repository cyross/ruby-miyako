# -*- encoding: utf-8 -*-
# Miyako Extension Raster Scroll
=begin
Miyako Extention Library v2.0
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
=end

module Miyako
  #==ラスタスクロール実行クラス
  #波の様に揺れる(疑似)ラスタスクロールを行うクラス
  #波はサイン波で構成される
  class RasterScroll
    #===インスタンスを作成する
    #ラスタスクロール対象のスプライトを登録する
    #_sspr_:: ラスタスクロール対象スプライト
    #返却値:: 作成したインスタンス
    def initialize(sspr)
      @src = sspr
      @lines = 0
      @h = @src.h
      @size = 0
      @sangle = 0
      @dangle = 0
      @fade_out = false
      @fo_size = 0
      @effecting = false
    end
    
    #===ラスタスクロールを開始する
    #ラスタスクロール実行用に設定する引数は以下の通り
    #:lines -> ライン数(:lines=>3を指定すると、3ラインずつラスタスクロールを行う)。デフォルトは1（ライン）
    #:size  -> 最大振幅数(:size=>20を指定すると、最大20ピクセルの高さの波となる)。デフォルトは4(ピクセル)
    #:start_angle -> 開始角度(一番上のラインでの振幅角度(ラジアンではなく角度なのに注意!))。デフォルトは0(度)
    #:distance -> 角度の変化量(ラインごとの角度の変化量。:distance=>1のときは、1度ずつ変化させる)。デフォルトは1(度)
    #:wait -> 変化させる間隔(WaitCounterクラスのインスタンス)。デフォルトは0.1秒間隔
    #_params_:: ラスタスクロール情報引数
    #返却値:: 自分自身を返す
    def start(params)
      @lines = params[:lines] || 1
      @size = params[:size] || 4
      @sangle = params[:start_angle] || 0
      @dangle = params[:distance] || 1
      @wait = params[:wait] || WaitCounter.new(0.1)
      @h = @h / @lines
      @fade_out = false
      @fo_size = 0
      @effecting = true
      @wait.start
      return self
    end
  
    #===ラスタスクロール処理を更新する
    #返却値:: 自分自身を返す
    def update
      return self unless @effecting
      if @wait.finish?
        @sangle = (@sangle + @dangle) % 360
        @wait.start
        if @fade_out
          return self unless @fo_wait.finish?
          @size = @size - @fo_size
          @fo_wait.start
          if @size <= 0
            @effecting = false
            @fade_out = false
          end
        end
      end
      return self
    end

    #===ラスタスクロールの実行状態を問い合わせる
    #返却値:: ラスタスクロール中の時はtrueを返す
    def effecting?
      return @effecting
    end

    #===ラスタスクロールの実行状態を問い合わせる
    #返却値:: ラスタスクロール中の時はtrueを返す
    def fade_out?
      return @fade_out
    end

    #===ラスタスクロールを停止する
    def stop
      @wait.stop
      @fo_size.stop if @fo_size
      @effecting = false
      @fade_out = false
    end

    #===ラスタスクロールを画面に描画する
    def render
      angle = @sangle
      @h.times{|y|
        rsx = @size * Math.sin(angle)
        @src.render{|src, dst| src.x += rsx; src.y += y * @lines; src.oy += y * @lines; src.oh = @lines }
        angle = angle + @dangle
      }
    end
    
    #===ラスタスクロールを画像に描画する
    #_dst_:: 描画先画像
    def render_to(dst)
      @angle = @sangle
      @h.times{|y|
        rsx = @size * Math.sin(@angle)
        @src.render_to(dst){|src, dst| src.x += rsx; src.y += y * @lines; src.oy += y * @lines; src.oh = @lines }
        @angle = @angle + @dangle
      }
    end

    #===ラスタスクロールをフェードアウトさせる
    #引数fwに与えられた間隔で振幅が減っていき(減る量は引数fsで与えられた値)、振幅がゼロになると終了する
    #_fs_:: フェードアウトの変化量
    #_fw_:: フェードアウトの変化を待つカウント(WaitCounterクラスインスタンス)
    def fade_out(fs, fw)
      @fo_size = fs
      @fo_wait = fw
      @fo_wait.start
      @fade_out = true
    end
  end
end
