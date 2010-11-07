# -*- encoding: utf-8 -*-
#
#=コンテンツ作成ライブラリMiyako2.1
#
#Authors:: サイロス誠
#Version:: 2.1.19
#Copyright:: 2007-2010 Cyross Makoto
#License:: LGPL2.1
#
=begin
Miyako v2.1
Copyright (C) 2007-2010  Cyross Makoto

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

if RUBY_VERSION < '1.9.1'
  puts 'Sorry. Miyako needs Ruby 1.9.1 or above...'
  exit
end

require 'sdl'

if SDL::VERSION < '2.0'
  puts 'Sorry. Miyako needs Ruby/SDL 2.0.0 or above...'
  exit
end

require 'forwardable'
require 'iconv' if RUBY_VERSION < '1.9.0'
require 'kconv'
require 'rbconfig'
require 'singleton'
require 'csv'
require 'delegate'

#画面などの初期設定を自動的に行うかどうかの設定。デフォルトはtrue
$miyako_auto_open = true if $miyako_auto_open.nil?

#デバッグモードの設定。デバッグモードにするときはtrueを渡す。デフォルトはfalse
$miyako_debug_mode ||= false

#openGLを使う？ openGLを使用するときはtrueを設定する。デフォルトはfalse
$miyako_use_opengl ||= false

#サウンド機能を使わないときは、miyako.rbをロードする前に
#$not_use_audio変数にtrueを割り当てる
$not_use_audio ||= false

Thread.abort_on_exception = true

#==Miyako基幹モジュール
module Miyako
  VERSION = "2.1.19"

  #===アプリケーション実行中に演奏する音楽のサンプリングレートを指定する
  #単位はHz(周波数)
  #規定値は44100
  #音声ファイルを扱うときは、すべての音声ファイルを同じサンプリングレートに統一する必要がある
  $sampling_seq ||= 44100

  #サウンド機能を使うときのバッファサイズを設定する（バイト単位）
  #デフォルトは4096バイト
  $sound_buffer_size ||= 4096

  #===Miyakoのバージョン番号を出力する
  #返却値:: バージョン番号を示す文字列
  def Miyako::version
    return VERSION
  end

  osn = Config::CONFIG["target_os"].downcase
  @@osName = "other"
  case osn
  when /mswin|mingw|cygwin|bccwin/
    @@osName = "win"
  when /linux/
    @@osName = "linux"
  when /darwin/
    @@osName = "mac_osx"
  end

  #===実行しているOSの名前を取得する
  #(Windows 9x/Me/Xp/Vista, Cygwin/MinGW) : "win"
  #(Linux) : "linux"
  #(Mac OS X) : "mac_osx"
  #(other) : "other"
  #返却値:: OS名
  def Miyako::getOSName
    return @@osName
  end

  #===ウィンドウのタイトルを設定する
  #_title_:: 設定する文字列
  def Miyako::setTitle(title)
    str = title
    case @@osName
    when "win"
      str = title.to_s().encode(Encoding::SJIS)
    when "mac_osx"
      str = title.to_s().encode(Encoding::UTF_8)
    when "linux"
      str = title.to_s().encode(Encoding::EUCJP)
    end
    SDL::WM.setCaption(str, "")
  end
end

require 'Miyako/API/exceptions'
require 'Miyako/API/utility'
require 'Miyako/API/struct_point'
require 'Miyako/API/struct_size'
require 'Miyako/API/struct_rect'
require 'Miyako/API/struct_square'
require 'Miyako/API/struct_segment'
require 'Miyako/API/color'
require 'Miyako/API/wait_counter'
require 'Miyako/API/basic_data'
require 'Miyako/API/modules'
require 'Miyako/API/layout'
require 'Miyako/API/yuki'
require 'Miyako/API/i_yuki'
require 'Miyako/API/font'
require 'Miyako/API/viewport'
require 'Miyako/API/bitmap'
require 'Miyako/API/drawing'
require 'Miyako/API/spriteunit'
require 'Miyako/API/sprite_animation'
require 'Miyako/API/sprite_list'
require 'Miyako/API/sprite'
require 'Miyako/API/collision'
require 'Miyako/API/screen'
require 'Miyako/API/shape'
require 'Miyako/API/plane'
require 'Miyako/API/input'
require 'Miyako/API/audio'
#require 'Miyako/API/movie'
require 'Miyako/API/parts'
require 'Miyako/API/choices'
require 'Miyako/API/textbox'
require 'Miyako/API/map_struct'
require 'Miyako/API/map'
require 'Miyako/API/fixedmap'
require 'Miyako/API/map_event'
require 'Miyako/API/story'
require 'Miyako/API/simple_story'
require 'Miyako/API/diagram'

module Miyako
  @@initialized = false

  #===Miyakoのメインループ
  #ブロックを受け取り、そのブロックを評価する
  #ブロック評価前に<i>Audio::update</i>と<i>Input::update</i>、<i>WaitCounter::update</i>、
  #<i>Screen::clear</i>、評価後に<i>WaitCounter::post_update</i>、<i>Animation::update</i>、
  #<i>Screen::render</i>を呼び出す
  #
  #ブロックを渡さないと例外が発生する
  def Miyako.main_loop(is_clear = true)
    raise MiyakoError, "Miyako.main_loop needs brock!" unless block_given?
    loop do
      Audio.update
      Input.update
      WaitCounter.update
      Screen.clear if is_clear
      yield
      WaitCounter.post_update
      Animation.update
      Screen.render
    end
  end

  #===SDLの初期化
  def Miyako.init
    raise MiyakoError, "Already initialized!" if @@initialized
    if $not_use_audio
      SDL.init(SDL::INIT_VIDEO | SDL::INIT_JOYSTICK)
    else
      SDL.init(SDL::INIT_VIDEO | SDL::INIT_AUDIO | SDL::INIT_JOYSTICK)
    end
    @@initialized = true
  end

  #===Miyako(SDL)が初期化された？
  def Miyako.initialized?
    @@initialized
  end

  #===Miyakoの初期化
  #画面初期化や音声初期化などのメソッドを呼び出す。
  #グローバル変数$miyako_auto_openがtrueのときは最初に自動的に呼び出される。
  #ユーティリティメソッドを使うだけならば、$miyako_auto_open=falseを設定して、後々Miyako.openを呼び出す。
  #_screen_:: 別のプロセスで生成されたSDL::Screenクラスのインスタンス。省略時はnil
  #_buf_size_:: Audioモジュールで使用するバッファサイズ。単位はバイト。省略時は4096
  #_seq_:: Audioモジュールで使用する音声の再生サンプル周波数。省略時は44100(44.1kHz)
  def Miyako.open(screen = nil, buf_size = 4096, seq = 44100)
    Miyako.init
    Screen.init(screen)
    Font.init
    Audio.init(buf_size, seq)
    Input.init
  end
end

require 'Miyako/miyako_no_katana'

Miyako.open(nil, $sound_buffer_size, $sampling_seq) if $miyako_auto_open
