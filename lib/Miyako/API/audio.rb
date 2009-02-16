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

module Miyako
  #==オーディオ管理モジュール
  #オーディオにはBGM,SE(効果音)の2種類あり、扱えるメソッドが少々違う(別クラスになっている)。
  module Audio
    #==BGM管理クラス
    class BGM
      #===インスタンスを生成する
      #_fname_:: 演奏するBGMファイル名。対応ファイルはwav,mp3,ogg,mid等。
      #_loops_:: ループの可否を指定する。trueのとき繰り返し再生を行う
      #返却値:: 生成したインスタンス
      def initialize(fname, loops = true)
        return if $not_use_audio
        @bgm = SDL::Mixer::Music.load(fname)
        @loops = loops
      end

      #===音の大きさを設定する
      #_v_:: 音の大きさ。0〜255までの整数。255で最大。
      #返却値:: 自分自身を返す
      def set_volume(v)
        return self if $not_use_audio
        SDL::Mixer.setVolumeMusic(v)
        return self
      end

      alias_method(:setVolume, :set_volume)
      
      #===BGMを演奏する。ブロックが渡されている場合、ブロックの評価中のみ演奏する。
      #_vol_:: 音の大きさ(省略可能)。0〜255までの整数。
      #返却値:: 自分自身を返す
      def play(vol = nil)
        return self if $not_use_audio
        set_volume(vol) if vol
        l = @loops ? -1 : 0
        SDL::Mixer.playMusic(@bgm, l).to_s()
        if block_given?
          yield self
          SDL::Mixer.haltMusic
        end
        return self
      end

      #===フェードインしながら演奏する
      #_msec_:: フェードインの時間。ミリ秒単位。デフォルトは5000ミリ秒(5秒)
      #返却値:: 自分自身を返す
      def fade_in(msec=5000)
        return self if $not_use_audio
        l = @loops ? -1 : 0
        SDL::Mixer.fadeInMusic(@bgm, l, msec)
        return self
      end

      alias_method(:fadeIn, :fade_in)
      
      #===演奏中を示すフラグ
      #返却値:: 演奏中はtrue、停止(一時停止)中はfalseを返す
      def playing?
        return false if $not_use_audio
        return SDL::Mixer.playMusic?
      end

      #===演奏を一時停止する
      #resumeメソッドで一時停止を解除する
      #返却値:: 自分自身を返す
      def pause
        return self if $not_use_audio
        SDL::Mixer.pauseMusic if SDL::Mixer.playMusic?
        return self
      end

      #===一時停止を解除する
      #返却値:: 自分自身を返す
      def resume
        return self if $not_use_audio
        SDL::Mixer.resumeMusic if SDL::Mixer.pauseMusic?
        return self
      end

      #===演奏を停止する
      #pauseメソッドとは違い、完全に停止するため、resumeメソッドは使えない
      #返却値:: 自分自身を返す
      def stop
        return self if $not_use_audio
        SDL::Mixer.haltMusic if SDL::Mixer.playMusic?
        return self
      end

      #===演奏をフェードアウトする
      #_msec_:: フェードアウトする時間。ミリ秒単位。デフォルトは5000ミリ秒
      #_wmode_:: フェードアウトする間、処理を停止するかどうかを示すフラグ。デフォルトはfalse(すぐに次の処理を開始)
      #返却値:: 自分自身を返す
      def fade_out(msec = 5000, wmode = false)
        return self if $not_use_audio
        if SDL::Mixer.playMusic?
          SDL::Mixer.fadeOutMusic(msec)
          SDL::delay(msec) if wmode
        end
        return self
      end
      
      #===演奏情報を解放する
      #単なるダミー
      def dispose
      end
      
      alias_method(:fadeOut, :fade_out)
    end

    #==効果音管理クラス
    class SE
      
      #===同時発音数を変更する
      #デフォルトの同時発音数は８。発音数を減らすと鳴っている音が止まるため注意
      #_channels_:: 変更するチャネル数。０以下を指定するとエラー
      def SE.channels=(channels)
        return if $not_use_audio
        raise MiyakoError, "Illegal Channels! : #{channels}" if channels <= 0
        SDL::Mixer.allocate_channels(channels)
      end

      #===インスタンスを生成する
      #_fname_:: 効果音ファイル名。wavファイルのみ対応
      #返却値:: 生成したインスタンス
      def initialize(fname)
        return if $not_use_audio
        @wave = SDL::Mixer::Wave.load(fname)
        @channel = -1
      end

      #===効果音を鳴らす
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する
      #返却値:: 自分自身を返す
      def play(vol = nil)
        return self if $not_use_audio
        set_volume(vol) if vol
        @channel = SDL::Mixer.playChannel(-1, @wave, 0)
        if block_given?
          yield self
          SDL::Mixer.halt(@channel)
        end
        return self
      end

      #===効果音が鳴っているかを示すフラグ
      #返却値:: 効果音が鳴っているときはtrue、鳴っていないときはfalseを返す
      def playing?
        return false if $not_use_audio
        return @channel != -1 ? SDL::Mixer.play?(@channel) : false
      end

      #===効果音を停止する
      #返却値:: 自分自身を返す
      def stop
        return self if $not_use_audio
        SDL::Mixer.halt(@channel) if @channel != -1
        return self
      end

      #===効果音の大きさを設定する
      #_v_:: 音の大きさ。0から255までの整数で示す。
      #返却値:: 自分自身を返す
      def set_volume(v)
        return self if $not_use_audio
        @wave.setVolume(v)
        return self
      end
      
      #===演奏情報を解放する
      #単なるダミー
      def dispose
      end
      
      alias_method(:setVolume, :set_volume)
    end
  end
end
