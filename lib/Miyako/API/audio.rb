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
  #==オーディオ管理モジュール
  #オーディオにはBGM,SE(効果音)の2種類あり、扱えるメソッドが少々違う(別クラスになっている)。
  module Audio
    @@initialized = false

    #===音声関連の初期化処理
    #既に初期化済みの時はMiyakoErrorが発生する
    #_buf_size_:: Audioモジュールで使用するバッファサイズ。単位はバイト。省略時は4096
    #_seq_:: Audioモジュールで使用する音声の再生サンプリング周波数。省略時は44100(44.1kHz)
    def Audio.init(buf_size = 4096, seq = 44100)
      raise MiyakoError, "Already initialized!" if @@initialized
      SDL::Mixer.open(seq, SDL::Mixer::DEFAULT_FORMAT, 2, buf_size) unless $not_use_audio
      SDL::Mixer.allocate_channels(SE.channels)
      @@initialized = true
    end

    #===音声関係の初期化がされた？
    def Audio.initialized?
      @@initialized
    end
    
    #===BGM・効果音の再生情報を更新する
    def Audio.update
      return if $not_use_audio
      Audio::BGM.update
      Audio::SE.update
    end

    #==BGM管理クラス
    #再生できるBGMは1曲だけ。2つ以上のBGMの同時演奏は不可
    class BGM
      @@playing_bgm = nil

      #===BGMの再生情報を更新する
      def BGM.update
        return if $not_use_audio
        return unless @@playing_bgm
        if !@@playing_bgm.playing_without_loop? && @@playing_bgm.in_the_loop?
          @@playing_bgm.loop_count_up
          @@playing_bgm = nil if !@@playing_bgm.in_the_loop?
        elsif !@@playing_bgm.playing? && !@@playing_bgm.fade_out?
          @@playing_bgm = nil
        elsif !@@playing_bgm.allow_loop_count_up?
          @@playing_bgm.allow_loop_count_up
        end
      end

      #===現在の繰り返し回数を取得する
      #繰り返し回数を限定して演奏しているとき、何回目の演奏家を示す。
      #無限に繰り返しているときは常に-1を返す
      #返却値:: ループ回数
      def loop_count
        @loop_cnt
      end

      #===現在、繰り返し演奏中かどうかを問い合わせる
      #現在、繰り返し回数が指定の回数の範囲内かどうかをtrue・falseで返す。
      #無限に繰り返しているときは常にtrue
      #返却値:: 現在繰り返し演奏中のときはtrue
      def in_the_loop?
        @now_loops == -1 ? true : @loop_cnt <= @now_loops
      end

      def loop_count_up #:nodoc:
        @loop_cnt = @loop_cnt + 1 if (@now_loops != -1 && @cnt_up_flag)
        @cnt_up_flag = false
      end

      def allow_loop_count_up #:nodoc:
        @cnt_up_flag = true
      end

      def allow_loop_count_up? #:nodoc:
        @cnt_up_flag
      end
      
      #===インスタンスを生成する
      #_fname_:: 演奏するBGMファイル名。対応ファイルはwav,mp3,ogg,mid等。
      #_loops_:: 演奏の繰り返し回数を指定する。-1を渡すと無限に繰り返す。省略時は-1を渡す。
      #返却値:: 生成したインスタンス
      def initialize(fname, loops = -1)
        return if $not_use_audio
        raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        raise MiyakoIOError.no_file(fname) unless File.exist?(fname)
        @bgm = SDL::Mixer::Music.load(fname)
        @loops = loops
        @now_loops = loops
        @loop_cnt = 1
        @cnt_up_flag = false
      end

      #===インスタンスの複写
      #複写すると不都合が多いため、MiyakoCopyException例外が発生する
      def initialize_copy(obj)
        raise MiyakoCopyError.not_copy("BGM")
      end
      
      #===音の大きさを設定する
      #_v_:: 音の大きさ。0〜255までの整数。255で最大。
      #返却値:: 自分自身を返す
      def set_volume(v)
        return self if $not_use_audio
        raise MiyakoValueError.over_range(v, 0, 255) unless (0..255).cover?(v)
        SDL::Mixer.set_volume_music(v)
        return self
      end

      alias_method(:setVolume, :set_volume)
      
      #===BGMを演奏する。ブロックが渡されている場合、ブロックの評価中のみ演奏する。
      #音の大きさ・繰り返し回数・演奏時間を指定可能
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_loops_:: 演奏の繰り返し回数を指定する。-1のときは無限に繰り返す。nilを渡すと元の設定を使う。省略時はnilを渡す。
      #返却値:: 演奏に成功したときはtrue、失敗した問いはfalseを返す
      def start(vol = nil, loops = nil)
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
        end
        if loops
          raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        end
        return self.play(vol, loops)
      end
      
      #===BGMを演奏する。ブロックが渡されている場合、ブロックの評価中のみ演奏する。
      #音の大きさ・繰り返し回数を指定可能
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_loops_:: 演奏の繰り返し回数を指定する。-1のときは無限に繰り返す。nilを渡すと元の設定を使う。省略時はnilを渡す。
      #返却値:: 演奏に成功したときはtrue、失敗した問いはfalseを返す
      def play(vol = nil, loops = nil)
        return false if $not_use_audio
        return false if @@playing_bgm && @@playing_bgm != self
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
          set_volume(vol)
        end
        if loops
          raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        end
        @now_loops = loops ? loops : @loops
        SDL::Mixer.play_music(@bgm, @now_loops)
        @loop_cnt = 1
        if block_given?
          yield self
          SDL::Mixer.halt_music
        end
        @@playing_bgm = self
        return true
      end

      #===フェードインしながら演奏する
      #_msec_:: フェードインの時間。ミリ秒単位。デフォルトは5000ミリ秒(5秒)
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_loops_:: 演奏の繰り返し回数を指定する。-1のときは無限に繰り返す。nilを渡すと元の設定を使う。省略時はnilを渡す。
      #返却値:: 演奏に成功したときはtrue、失敗した問いはfalseを返す
      def fade_in(msec=5000, vol = nil, loops = nil)
        return false if $not_use_audio
        return false if @@playing_bgm && @@playing_bgm != self
        raise MiyakoValueError.over_range(msec, 1, nil) unless msec > 0
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
          set_volume(vol)
        end
        if loops
          raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        end
        @now_loops = loops ? loops : @loops
        SDL::Mixer.fade_in_music(@bgm, @now_loops)
        @@playing_bgm = self
        @loop_cnt = 1
        return true
      end

      alias_method(:fadeIn, :fade_in)
      
      #===演奏中を示すフラグ
      #返却値:: 演奏中はtrue、停止(一時停止)中はfalseを返す
      def playing?
        return false if $not_use_audio
        return (SDL::Mixer.play_music? && self.in_the_loop?) || self.fade_out?
      end
      
      def playing_without_loop? #:nodoc:
        return false if $not_use_audio
        return SDL::Mixer.play_music?
      end
      
      #===演奏停止中を示すフラグ
      #返却値:: 演奏停止中はtrue、演奏中はfalseを返す
      def pausing?
        return false if $not_use_audio
        return SDL::Mixer.pause_music?
      end

      #===演奏を一時停止する
      #resumeメソッドで一時停止を解除する
      #返却値:: 自分自身を返す
      def pause
        return self if $not_use_audio
        SDL::Mixer.pause_music if SDL::Mixer.play_music?
        return self
      end
      
      #==フェードイン中を示すフラグ
      #返却値:: フェードイン中はtrue、そのほかの時はfalseを返す
      def fade_in?
        return false if $not_use_audio
#        return SDL::Mixer.fading_music == SDL::Mixer::FADING_IN
        # なぜかSDL::Mixer::FADING_INが見つからないため、即値で
        # from SDL_Mixer.h
        return SDL::Mixer.fading_music == 2
      end
      
      #==フェードアウト中を示すフラグ
      #返却値:: フェードアウト中はtrue、そのほかの時はfalseを返す
      def fade_out?
        return false if $not_use_audio
#        return SDL::Mixer.fading_music == SDL::Mixer::FADING_OUT
        # なぜかSDL::Mixer::FADING_OUTが見つからないため、即値で
        # from SDL_Mixer.h
        return SDL::Mixer.fading_music == 1
      end

      #===一時停止を解除する
      #返却値:: 自分自身を返す
      def resume
        return self if $not_use_audio
        SDL::Mixer.resume_music if SDL::Mixer.pause_music?
        return self
      end

      #===演奏を停止する
      #pauseメソッドとは違い、完全に停止するため、resumeメソッドは使えない
      #返却値:: 自分自身を返す
      def stop
        return self if $not_use_audio
        SDL::Mixer.halt_music if SDL::Mixer.play_music?
        @loop_cnt = @now_loops + 1
        @@playing_bgm = nil if @@playing_bgm == self
        return self
      end

      #===演奏をフェードアウトする
      #_msec_:: フェードアウトする時間。ミリ秒単位。デフォルトは5000ミリ秒
      #_wmode_:: フェードアウトする間、処理を停止するかどうかを示すフラグ。デフォルトはfalse(すぐに次の処理を開始)
      #返却値:: 自分自身を返す
      def fade_out(msec = 5000, wmode = false)
        return self if $not_use_audio
        raise MiyakoValueError.over_range(msec, 1, nil) unless msec > 0
        if SDL::Mixer.play_music?
          SDL::Mixer.fade_out_music(msec)
          SDL::delay(msec) if wmode
        end
        return self
      end
      
      #===演奏情報を解放する
      #レシーバをdup/deep_dupなどのメソッドで複製したことがある場合、
      #内部データを共有しているため、呼び出すときには注意すること
      def dispose
        @@playing_bgm = nil if @@playing_bgm == self
        @bgm.destroy
        @bgm = nil
      end
      
      alias_method(:fadeOut, :fade_out)
    end

    #==効果音管理クラス
    class SE
      @@channels = 8
      @@playings = []

      SDL::Mixer.allocate_channels(@@channels)
      
      attr_accessor :priority
      
      #===効果音の再生情報を更新する
      def SE.update
        return if $not_use_audio
        @@playings.each{|playing|
          if !playing.playing_without_loop? && playing.in_the_loop?
            playing.loop_count_up
            @@playings.delete(playing) if !playing.in_the_loop?
          elsif !playing.playing? && !playing.fade_out?
            @@playings.delete(playing)
          elsif !playing.allow_loop_count_up?
            playing.allow_loop_count_up
          end
        }
      end
    
      #===何かしらの効果音が再生中かどうかを確認する
      #返却値:: 何かしらの効果音が再生中ならtrue、それ以外はfalse
      def SE.playing_any?
        !@@playings.empty?
      end
      
      #===同時発音数を取得する
      #返却値:: 同時再生数
      def SE.channels
        @@channels
      end
      
      #===現在再生している効果音をすべて停止する
      #_msec_:: 停止する時間をミリ秒で指定(msecミリ秒後に停止)。nilを渡すとすぐに停止する。省略時はnilを渡す。
      def SE.stop(msec = nil)
        if msec
          raise MiyakoValueError.over_range(msec, 1, nil) unless msec > 0
        end
        msec ? SDL::Mixer.expire(-1, msec) : SDL::Mixer.halt(-1)
        @@playings.clear
      end
      
      #===同時発音数を変更する
      #同時発音数に0以下を指定するとMiyakoValueErrorが発生する
      #現在同時に発音している音が新しいせっていによりあぶれる場合、あぶれた分を優先度の低い順に停止する
      #起動時の同時発音数は8
      #_channels_:: 変更する同時発音数
      #返却値:: 変更に成功したときはtrue、失敗したときはfalseを返す
      def SE.channels=(channels)
        return false if $not_use_audio
        raise MiyakoValueError, "Illegal Channels! : #{channels}" if channels <= 0
        if @@playings.length > channels
          num = @@channels - channels
          sorted = @@playings.sort{|a,b| a.priority <=> b.priority}
          num.times{|n| sorted[n].stop}
        end
        SDL::Mixer.allocate_channels(channels)
        @@channels = channels
        return true
      end

      #===現在の繰り返し回数を取得する
      #繰り返し回数を限定して演奏しているとき、何回目の演奏家を示す。
      #無限に繰り返しているときは常に-1を返す
      #返却値:: ループ回数
      def loop_count
        @loop_cnt
      end

      #===現在、繰り返し演奏中かどうかを問い合わせる
      #現在、繰り返し回数が指定の回数の範囲内かどうかをtrue・falseで返す。
      #無限に繰り返しているときは常にtrue
      #返却値:: 現在繰り返し演奏中のときはtrue
      def in_the_loop?
        @now_loops == -1 ? true : @loop_cnt <= @now_loops
      end

      def loop_count_up #:nodoc:
        @loop_cnt = @loop_cnt + 1 if (@now_loops != -1 && @cnt_up_flag)
        @cnt_up_flag = false
      end

      def allow_loop_count_up #:nodoc:
        @cnt_up_flag = true
      end

      def allow_loop_count_up? #:nodoc:
        @cnt_up_flag
      end

      #===インスタンスを生成する
      #_fname_:: 効果音ファイル名。wavファイルのみ対応
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_vol_:: 再生優先度(省略可能)。整数を設定する。省略したときは0を渡す。
      #返却値:: 生成したインスタンス
      def initialize(fname, vol = nil, priority = 0)
        return nil if $not_use_audio
        raise MiyakoIOError.no_file(fname) unless File.exist?(fname)
        @wave = SDL::Mixer::Wave.load(fname)
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
          @wave.set_volume(vol)
        end
        @channel = -1
        @loops = -1
        @now_loops = @loops
        @loop_cnt = 1
        @cnt_up_flag = false
        @priority = priority
      end

      #===インスタンスの複写
      #複写すると不都合が多いため、MiyakoCopyException例外が発生する
      def initialize_copy(obj)
        raise MiyakoCopyError.not_copy("SE")
      end
      
      #===効果音を鳴らす
      #音の大きさ・繰り返し回数・演奏時間を指定可能
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_loops_:: 演奏の繰り返し回数を指定する。-1のときは無限に繰り返す。省略時は1を渡す。
      #_time_:: 演奏時間。ミリ秒を整数で指定する。省略時は最後まで演奏する。
      #返却値:: 再生に成功したときはtrue、失敗したときはfalseを返す
      def start(vol = nil, loops = 1, time = nil)
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
        end
        if time
          raise MiyakoValueError.over_range(time, 1, nil) unless msec > 1
        end
        raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        return self.play(vol, loops, time)
      end

      #===効果音を鳴らす
      #音の大きさ・繰り返し回数・演奏時間を指定可能
      #鳴らすとき、同時再生数を超えるときは鳴らさずにfalseを返す
      #ただし、自分自身が鳴っているときは、前に鳴っていた音を止めて再び鳴らす
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_loops_:: 演奏の繰り返し回数を指定する。-1のときは無限に繰り返す。省略時は1を渡す。
      #_time_:: 演奏時間。ミリ秒を整数で指定する。省略時は最後まで演奏する。
      #返却値:: 再生に成功したときはtrue、失敗したときはfalseを返す
      def play(vol = nil, loops = 1, time = nil)
        return false if $not_use_audio
        if (@@playings.length == @@channels && !@@playings.include?(self))
          sorted = @@playings.sort{|a,b| a.priority <=> b.priority}
          sorted[0].stop
        elsif @@playings.include?(self)
          self.stop
        end
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
          set_volume(vol)
        end
        if time
          raise MiyakoValueError.over_range(time, 1, nil) unless time > 0
        end
        raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        @now_loops = loops ? loops : @loops
        @loop_cnt = 1
        lp = @now_loops == -1 ? -1 : @now_loops - 1
        @channel = time ? SDL::Mixer.play_channel_timed(-1, @wave, lp, time) : SDL::Mixer.play_channel(-1, @wave, lp)
        @@playings << self
        if block_given?
          yield self
          SDL::Mixer.halt(@channel)
        end
        SE.update
        return true
      end

      #===効果音が鳴っているかを示すフラグ
      #返却値:: 効果音が鳴っているときはtrue、鳴っていないときはfalseを返す
      def playing?
        return false if $not_use_audio
        return @channel != -1 ? (SDL::Mixer.play?(@channel) && self.in_the_loop?) || self.fade_out? : false
      end
      
      def playing_without_loop? #:nodoc:
        return false if $not_use_audio
        return @channel != -1 ? SDL::Mixer.play?(@channel) : false
      end

      #===効果音を停止する
      #_msec_:: 停止する時間をミリ秒で指定(msecミリ秒後に停止)。nilを渡すとすぐに停止する。省略時はnilを渡す。
      #返却値:: 自分自身を返す
      def stop(msec = nil)
        return self if $not_use_audio
        return self if !@@playings.include?(self)
        if msec
          raise MiyakoValueError.over_range(msec, 1, nil) unless msec > 0
        end
        return self if @channel == -1
        return self unless SDL::Mixer.play?(@channel)
        msec ? SDL::Mixer.expire(@channel, msec) : SDL::Mixer.halt(@channel)
        @loop_cnt = @now_loops + 1
        @@playings.delete(self)
        @channe = -1
        return self
      end

      #===フェードインしながら演奏する
      #_msec_:: フェードインの時間。ミリ秒単位。デフォルトは5000ミリ秒(5秒)
      #_loops_:: 演奏の繰り返し回数を指定する。-1のときは無限に繰り返す。省略時は1を渡す。
      #_vol_:: 音の大きさ(省略可能)。0〜255の整数を設定する。nilを渡したときは音の大きさを変更しない。
      #_time_:: 演奏時間。ミリ秒を整数で指定する。省略時は最後まで演奏する。
      #返却値:: 演奏に成功したときはtrue、失敗した問いはfalseを返す
      def fade_in(msec=5000, loops = 1, vol = nil, time = nil)
        return false if $not_use_audio
        if (@@playings.length == @@channels && !@@playings.include?(self))
          sorted = @@playings.sort{|a,b| a.priority <=> b.priority}
          sorted[0].stop
        elsif @@playings.include?(self)
          self.stop
        end
        if vol
          raise MiyakoValueError.over_range(vol, 0, 255) unless (0..255).cover?(vol)
          set_volume(vol)
        end
        if time
          raise MiyakoValueError.over_range(time, 1, nil) unless time > 0
        end
        raise MiyakoValueError.over_range(loops, -1, nil) unless loops >= -1
        @now_loops = loops ? loops : @loops
        @loop_cnt = 1
        lp = @now_loops == -1 ? -1 : @now_loops - 1
        @channel = time ? SDL::Mixer.fade_in_channel_timed(-1, @wave, lp, msec, time) : SDL::Mixer.fade_in_channel(-1, @wave, lp, msec)
        @@playings << self
        SE.update
        return true
      end

      #===演奏をフェードアウトする
      #_msec_:: フェードアウトする時間。ミリ秒単位。デフォルトは5000ミリ秒
      #_wmode_:: フェードアウトする間、処理を停止するかどうかを示すフラグ。デフォルトはfalse(すぐに次の処理を開始)
      #返却値:: 自分自身を返す
      def fade_out(msec = 5000, wmode = false)
        return self if $not_use_audio
        return self if !@@playings.include?(self)
        if msec
          raise MiyakoValueError.over_range(msec, 1, nil) unless msec > 0
        end
        if self.playing?
          SDL::Mixer.fade_out(@channel, msec)
          SDL::delay(msec) if wmode
        end
        return self
      end

      #==フェードイン中を示すフラグ
      #返却値:: フェードイン中はtrue、そのほかの時はfalseを返す
      def fade_in?
        return false if $not_use_audio
        return false if @channel == -1
        # なぜかSDL::Mixer::FADING_INが見つからないため、即値で
        # from SDL_Mixer.h
#        return SDL::Mixer.fading(@channel) == SDL::Mixer::FADING_IN
        return SDL::Mixer.fading(@channel) == 2
      end
      
      #==フェードアウト中を示すフラグ
      #返却値:: フェードアウト中はtrue、そのほかの時はfalseを返す
      def fade_out?
        return false if $not_use_audio
        return false if @channel == -1
        # なぜかSDL::Mixer::FADING_INが見つからないため、即値で
        # from SDL_Mixer.h
#        return SDL::Mixer.fading(@channel) == SDL::Mixer::FADING_OUT
        return SDL::Mixer.fading(@channel) == 1
      end


      #===効果音の大きさを設定する
      #_v_:: 音の大きさ。0から255までの整数で示す。
      #返却値:: 自分自身を返す
      def set_volume(v)
        return self if $not_use_audio
        raise MiyakoValueError.over_range(v, 0, 255) unless (0..255).cover?(v)
        @wave.set_volume(v)
        return self
      end
      
      #===演奏情報を解放する
      #レシーバをdup/deep_dupなどのメソッドで複製したことがある場合、
      #内部データを共有しているため、呼び出すときには注意すること
      def dispose
        @wave.destroy
        @wave = nil
      end
      
      alias_method(:setVolume, :set_volume)
    end
  end
end
