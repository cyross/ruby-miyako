=begin
--
Miyako v1.4
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
    ScreenFlag = Array.new
    ScreenFlag.push(SDL::HWSURFACE | SDL::DOUBLEBUF | SDL::ANYFORMAT)
    ScreenFlag.push(SDL::ANYFORMAT | SDL::FULLSCREEN)

    def Screen::get_fps_count
      return @@fps == 0 ? 0 : FpsMax / @@fps
    end

    @@fps = 0 # fps=0 : no-limit
    @@fpsView = false
    @@fps_sprite = nil
    @@fpscnt = Screen::get_fps_count
    @@min_interval = 3
    @@min_interval_r = @@min_interval / 1000
    @@t = 0
    @@freezing  = false
    @@mode      = WINDOW_MODE

    @@size      = Size.new(DefaultWidth, DefaultHeight)
    @@in_the_scene = false

    @@screen = nil

    @@sprite_list = Array.new
    
    def Screen::set_screen(f) #:nodoc:
      return false unless SDL.checkVideoMode(*(@@size.to_a << BPP << f))
      @@screen = SDL.setVideoMode(*(@@size.to_a << BPP << f))
      return true
    end

    #===画面の大きさを変更する
    #単位はピクセル単位
    #_w_:: 画面の幅
    #_h_:: 画面の高さ
    #_f_:: スプライトやシーンなどの設定(ビューポートやレイアウト)の情報をリセットするときに true を渡す
    #返却値:: 変更に成功したときは trueを返す
    def Screen::set_size(w, h, f=true)
      return false unless SDL.checkVideoMode(w, h, BPP, ScreenFlag[@@mode])
      @@size = Size.new(w, h)
      @@screen = SDL.setVideoMode(*(@@size.to_a << BPP << ScreenFlag[@@mode]))

      if f
        Sprite.recalc_layout
        SpriteAnimation.recalc_layout
        Plane.resize
        Sprite.reset_viewport
        SpriteAnimation.reset_viewport
        Map.reset_viewport
        FixedMap.reset_viewport
      end
      return true
    end

    def Screen::check_mode_error #:nodoc:
      unless Screen::set_screen(ScreenFlag[@@mode])
        print "Sorry, this system not supported display...\n";
        exit(1)
      end
    end

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

    Screen::check_mode_error

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

    #===現在の画面の大きさを取得する
    #返却値:: 画像の大きさ(Rect構造体のインスタンス)
    def Screen::rect
      return Rect.new(*([0, 0]+@@size.to_a))
    end

    #===SpriteUnit構造体の配列を取得する
    #
    #返却値:: あとで書く
    def Screen::sprite_list
      return @@sprite_list
    end

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

    def Screen::update_tick #:nodoc:
      t = SDL.getTicks
      interval = t - @@t
      while interval < @@fpscnt do
        t = SDL.getTicks
        interval = t - @@t
      end
      if @@fps_sprite
        @@fps_sprite.hide
        @@fps_sprite.dispose
      end
      if @@fpsView
        @@fps_sprite = Shape.text({:text => (FpsMax/(interval == 0 ? 1 : interval)).to_s() + " fps", :font => Font.sans_serif})
        @@fps_sprite.show
      end
      @@t = t
    end

    #===画像を消去する
    #画像を黒色([0,0,0,0])で塗りつぶす
    def Screen::clear
      @@screen.fillRect(0, 0, @@screen.w, @@screen.h, [0, 0, 0, 0])
    end
    
    #===画面を更新する(自前でrenderメソッドを呼び出す形式)
    #画像を、それぞれのインスタンスのrenderメソッドを呼び出した順に貼り付ける
    #
    #各インスタンスのdp,visibleメソッドの値は無視する
    #
    #SpriteAnimation.update_animationメソッドによる
    #アニメーションも明示的に行う必要がある
    #
    #(注)画面の消去は行わないので、必要ならScreen.clearメソッドで画面を消去する
    def Screen::render
      @@sprite_list.each{|s|
        @@screen.set_clip_rect(*(s.viewport.to_a))
        if s.effect && s.effect.effecting?
          s.effect.update(@@screen)
        else
          SDL.blitSurface(s.bitmap, s.ox, s.oy, s.ow, s.oh, @@screen, s.x, s.y)
        end
      }
      @@screen.set_clip_rect(0, 0, @@size.w, @@size.h)
      @@sprite_list.clear
      @@fps_sprite.render if @@fps_sprite
      Screen::update_tick
      @@screen.flip
    end

    #===画面を更新する
    #Sprite,Plane,TextBox,Map,FixedMapの各クラスに登録されている
    #画像を画面に貼り付ける
    #
    #順番は、各画像(SpriteUnit構造体)のdp値を昇順に貼り付ける
    #(dp値が小さい画像が奥に貼られるように見える)
    #
    #また、SpriteAnimation.update_animationメソッドを呼び出し、
    #アニメーションを自動更新する
    def Screen::update
      @@screen.fillRect(0, 0, @@screen.w, @@screen.h, [0, 0, 0, 0])
      Sprite.update_sprite
      SpriteAnimation.update_animation
      Plane.update
      TextBox.update
      Map.update
      FixedMap.update
      list1 = @@sprite_list.sort{|a,b| a.dp <=> b.dp}
      list1.each{|s|
        @@screen.set_clip_rect(*(s.viewport.to_a))
        if s.effect && s.effect.effecting?
          s.effect.update(@@screen)
        else
          SDL.blitSurface(s.bitmap, s.ox, s.oy, s.ow, s.oh, @@screen, s.x, s.y)
        end
      }
      @@screen.set_clip_rect(0, 0, @@size.w, @@size.h)
      @@sprite_list.clear
      Screen::update_tick
      @@screen.flip
    end
  end
end
