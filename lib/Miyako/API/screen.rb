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

require 'singleton'

module Miyako
  #プログラムで使用する色深度を示す。デフォルトは現在システムが使用している色深度
  $miyako_bpp ||= SDL.video_info.bpp
  #色深度が32ビット以外の時はエラーを返す
  raise MiyakoError, "Unsupported Color bits! : #{$miyako_bpp}" unless [32].include?($miyako_bpp)

  #==画面管理モジュール
  module Screen
    #デフォルトの画面解像度(幅)
    DefaultWidth = 640
    #デフォルトの画面解像度(高さ)
    DefaultHeight = 480
    #Miyakoで使用する色深度
    BPP = $miyako_bpp
    #fpsの最大値(1000fps)
    FpsMax = 1000
    #画面モードの数(ウインドウモード、フルスクリーンモード)
    WINMODES = 2
    #ウインドウモードを示す値
    WINDOW_MODE = 0
    #フルスクリーンモードを示す値
    FULLSCREEN_MODE = 1

    #ウインドウモード・フルスクリーンモードを切り替える際のフラグを示す配列
    ScreenFlag = $miyako_use_opengl ? [SDL::OPENGL, SDL::OPENGL | SDL::FULLSCREEN] : [SDL::HWSURFACE | SDL::DOUBLEBUF | SDL::ANYFORMAT, SDL::ANYFORMAT | SDL::FULLSCREEN]
    
    if $miyako_use_opengl
      SDL::GL.set_attr(SDL::GL::RED_SIZE, 8)
      SDL::GL.set_attr(SDL::GL::GREEN_SIZE, 8)
      SDL::GL.set_attr(SDL::GL::BLUE_SIZE, 8)
      SDL::GL.set_attr(SDL::GL::ALPHA_SIZE, 8)
      SDL::GL.set_attr(SDL::GL::DEPTH_SIZE, 32)
      SDL::GL.set_attr(SDL::GL::STENCIL_SIZE, 32)
      SDL::GL.set_attr(SDL::GL::DOUBLEBUFFER, 1)
    end
    
    def Screen::get_fps_count
      return @@fps == 0 ? 0 : FpsMax / @@fps
    end

    @@fps = 0 # fps=0 : no-limit
    @@fpsView = false
    @@fpscnt = Screen::get_fps_count
    @@interval = 0
    @@min_interval = 3
    @@min_interval_r = @@min_interval / 1000
    @@t = 0
    @@freezing  = false
    @@mode      = WINDOW_MODE
    @@unit      = SpriteUnitFactory.create

    @@size      = Size.new(DefaultWidth, DefaultHeight)
    @@in_the_scene = false

    @@screen = nil
    @@viewport = nil
    
    #===画面の状態(ウインドウモードとフルスクリーンモード)を設定する
    #_v_:: ウィンドウモードのときは、Screen::WINDOW_MODE、 フルスクリーンモードのときはScreen::FULLSCREEN_MODE
    def Screen::set_mode(v)
      if v.to_i == WINDOW_MODE || v.to_i == FULLSCREEN_MODE
        @@mode = v.to_i
        Screen::check_mode_error
      end
    end

    #===ウインドウモードとフルスクリーンモードを切り替える
    def Screen::toggle_mode
      @@mode = (@@mode + 1) % WINMODES
      Screen::check_mode_error
    end

    def Screen::fps # :nodoc:
      return @@fps
    end

    def Screen::fps=(val) # :nodoc:
      @@fps = val
      @@fpscnt = @@fps == 0 ? 0 : Screen::get_fps_count
    end

    def Screen::fps_view # :nodoc:
      return @@fpsView
    end

    def Screen::fps_view=(val) # :nodoc:
      @@fpsView = val
    end

    #===画面を管理するインスタンスを取得する
    #返却値:: 画面インスタンス(SDL::Screenクラスのインスタンス)
    def Screen::screen
      return @@screen
    end

    #===画面の幅を取得する
    #返却値:: 画面の幅(ピクセル)
    def Screen::w
      return @@size[0]
    end

    #===画面の高さを取得する
    #返却値:: 画面の高さ(ピクセル)
    def Screen::h
      return @@size[1]
    end

    #===画面を管理するSpriteUnitを取得する
    #得られるインスタンスは複写していないので、インスタンスの値を調整するには、dupメソッドで複製する必要がある
    #返却値:: SpriteUnitインスタンス
    def Screen::to_unit
      return @@unit
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #x方向の中心座標を取得する
    #返却値:: 中心座標。
    def Screen::center_x
      return @@unit.cx
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #x方向の中心座標を取得する
    #_pos_:: 中心座標
    def Screen::center_x=(pos)
      @@unit.cx = pos
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #y方向の中心座標を取得する
    #返却値:: 中心座標。
    def Screen::center_y
      return @@unit.cy
    end

    #===画像の回転・拡大・縮小の中心座標を取得する
    #y方向の中心座標を取得する
    #_pos_:: 中心座標
    def Screen::center_y=(pos)
      @@unit.cy = pos
    end

    #===現在の画面の大きさを矩形で取得する
    #返却値:: 画像の大きさ(Rect構造体のインスタンス)
    def Screen::rect
      return Rect.new(*([0, 0]+@@size.to_a))
    end

    #===現在の画面の最大の大きさを矩形で取得する
    #但し、Screenの場合は最大の大きさ=画面の大きさなので、rectと同じ値が得られる
    #返却値:: 画像の大きさ(Rect構造体のインスタンス)
    def Screen::broad_rect
      return Screen.rect
    end

    #===現在のビューポート(表示区画)を取得する
    #ビューポートの設定は、Viewport#renderで行う
    #返却値:: ビューポート(Viewportクラスのインスタンス)
    def Screen::viewport
      return @@viewport
    end

    #===現在の画面の大きさを取得する
    #返却値:: 画像の大きさ(Size構造体のインスタンス)
    def Screen::size
      return @@size.dup
    end

    #===画面のサーフェスを生成する
    #グローバル変数$miyako_open_screen==falseの時に有効
    #画面サーフェスを生成し、表示させる
    #require 'Miyako/miyako'を記述する前に、"$miyako_open_screen=false"と記述すると
    def Screen::open
      @@screen = SDL::Screen.open(*(@@size.to_a << BPP << ScreenFlag[@@mode]))
      SpriteUnitFactory.apply(@@unit, {:bitmap=>@@screen, :ow=>@@screen.w, :oh=>@@screen.h})
      @@viewport = Viewport.new(0, 0, @@screen.w, @@screen.h)
    end

    def Screen::set_screen #:nodoc:
      return false unless SDL.checkVideoMode(*(@@size.to_a << BPP << ScreenFlag[@@mode]))
      self.open
      return true
    end

    #===画面の大きさを変更する
    #単位はピクセル単位
    #_w_:: 画面の幅
    #_h_:: 画面の高さ
    #返却値:: 変更に成功したときは trueを返す
    def Screen::set_size(w, h)
      return unless @@screen
      return false unless SDL.checkVideoMode(w, h, BPP, ScreenFlag[@@mode])
      @@size = Size.new(w, h)
      self.open
      return true
    end

    def Screen::check_mode_error #:nodoc:
      unless Screen::set_screen
        print "Sorry, this system not supported display...\n";
        exit(1)
      end
    end

    Screen::check_mode_error

    #===現在表示されている画面を画像(Spriteクラスのインスタンス)として取り込む
    #_param_:: Spriteインスタンスを生成するときに渡すパラメータ(但し、:sizeと:typeのみ使用する)
    #_rect_:: 取り込む画像の矩形(4要素の配列もしくはRect構造体のインスタンス)
    #デフォルトは画面の大きさ
    #返却値:: 取り込んだ画像を含むSpriteクラスのインスタンス
    def Screen::capture(param, rect = ([0, 0] + @@size.to_a))
      param = param.dup
      param[:size] = Size.new(*(rect[2..3]))
      dst = Sprite.new(param)
      SDL.blit_surface(*([@@screen] + rect.to_a << dst.bitmap << 0 << 0))
      return dst
    end

    #===現在表示されている画面を複製し、Spriteクラスのインスタンスとして取得
    #Screen.captureとの違いは、パラメータ・サイズは不変(画面の大きさで複製)で取り扱う。
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 取り込んだ画像を含むSpriteクラスのインスタンス
    def Screen::to_sprite
      dst = Sprite.new(:size => Size.new(*(rect[2..3])), :type => :ac)
      Bitmap.screen_to_ac!(Screen, dst)
      yield dst if block_given?
      return dst
    end

    #===画像を消去する
    #画像を黒色([0,0,0,0])で塗りつぶす
    def Screen::clear
      return unless @@screen
      @@screen.fillRect(0, 0, @@screen.w, @@screen.h, [0, 0, 0, 0])
    end
    
    #===画面を更新する
    #描画した画面を、実際にミニ見える形に反映させる
    #呼び出し時に画面の消去は行われないため、明示的にScreen.clearメソッドを呼び出す必要がある
    def Screen::render
      Shape.text({:text => (FpsMax/(@@interval == 0 ? 1 : @@interval)).to_s() + " fps", :font => Font.sans_serif}).render  if @@fpsView
      Screen::update_tick
      @@screen.flip
    end

    #===インスタンスの内容を画面に描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit,画面のSpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 自分自身を返す
    def Screen::render_screen(src)
    end
  end
end
