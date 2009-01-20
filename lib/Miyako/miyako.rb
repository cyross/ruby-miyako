# -*- encoding: utf-8 -*-
#
#=コンテンツ作成ライブラリMiyako2.0
#
#Authors:: サイロス誠
#Version:: 2.0.0
#Copyright:: 2007-2008 Cyross Makoto
#License:: LGPL2.1
#
=begin
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
require 'jcode' if RUBY_VERSION < '1.9.0'
require 'rbconfig'

$KCODE = 'u' if RUBY_VERSION < '1.9.0'


#デバッグモードの設定。デバッグモードにするときはtrueを渡す。デフォルトはfalse
$miyako_debug_mode ||= false

#Miyako.main_loopでウェイトを行うかどうかの設定。デフォルトはtrue
$miyako_use_wait = true if $miyako_use_wait == nil
#Miyako.main_loopでかけるウェイト。単位は秒(実数)。デフォルトは0.01秒
$miyako_wait_time = 0.01 if $miyako_wait_time == nil

#openGLを使う？ openGLを使用するときはtrueを設定する。デフォルトはfalse
$miyako_use_opengl ||= false

#サウンド機能を使わないときは、miyako.rbをロードする前に
#$not_use_audio変数にtrueを割り当てる
$not_use_audio ||= false
if $not_use_audio
  SDL.init(SDL::INIT_VIDEO | SDL::INIT_JOYSTICK)
else
  SDL.init(SDL::INIT_VIDEO | SDL::INIT_AUDIO | SDL::INIT_JOYSTICK)
end

Thread.abort_on_exception = true

#==Miyako基幹モジュール
module Miyako

  #===アプリケーション実行中に演奏する音楽のサンプリングレートを指定する
  #単位はHz(周波数)
  #規定値は44100
  #音声ファイルを扱うときは、すべての音声ファイルを同じサンプリングレートに統一する必要がある
  $sampling_seq ||= 44100

  #サウンド機能を使うときのバッファサイズを設定する（バイト単位）
  #デフォルトは4096バイト
  $sound_buffer_size ||= 4096

  SDL::TTF.init
  SDL::Mixer.open($sampling_seq, SDL::Mixer::DEFAULT_FORMAT, 2, $sound_buffer_size) unless $not_use_audio

  #===Miyakoのバージョン番号を出力する
  #返却値:: バージョン番号を示す文字列
  def Miyako::version
    return "2.0.0"
  end

  #==Miyakoの例外クラス
  class MiyakoError < Exception
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
      str = title.to_s().tosjis()
    when "mac_osx"
      str = Iconv.conv("UTF-8-MAC", "UTF-8", title.to_s().toutf8())
    when "linux"
      str = title.to_s().toeuc()
    end
    SDL::WM.setCaption(str, "")
  end
end

require 'Miyako/API/yuki'
require 'Miyako/API/basic_data'
require 'Miyako/API/modules'
require 'Miyako/API/font'
require 'Miyako/API/viewport'
require 'Miyako/API/layout'
require 'Miyako/API/bitmap'
require 'Miyako/API/drawing'
require 'Miyako/API/spriteunit'
require 'Miyako/API/sprite_animation'
require 'Miyako/API/sprite'
require 'Miyako/API/collision'
require 'Miyako/API/screen'
require 'Miyako/API/shape'
require 'Miyako/API/plane'
require 'Miyako/API/input'
require 'Miyako/API/audio'
require 'Miyako/API/movie'
require 'Miyako/API/parts'
require 'Miyako/API/choices'
require 'Miyako/API/textbox'
require 'Miyako/API/map'
require 'Miyako/API/fixedmap'
require 'Miyako/API/map_event'
require 'Miyako/API/story'
require 'Miyako/API/diagram'

module Miyako
  #===Miyakoのメインループ
  #ブロックを受け取り、そのブロックを評価する
  #ブロック評価前に<i>Input::update</i>と<i>Screen::clear</i>、評価後に<i>Screen::render</i>を呼び出す
  #
  #ブロックを渡さないと例外が発生する
  def Miyako.main_loop
    raise MiyakoError, "Miyako.main_loop needs brock!" unless block_given?
    loop do
      Input::update
      Screen::clear
      yield
      Screen::render
      sleep $miyako_wait_time if $miyako_use_wait
    end
  end
end

require 'Miyako/miyako_no_katana'
