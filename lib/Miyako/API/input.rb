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

  #==入力管理モジュール
  #本モジュールでは、キーボードやマウス、ゲームパッドなどの入力装置からの情報を管理する。
  #メソッドのほとんどは、「押されたかどうか」などの問い合わせメソッドで構成されている。
  #本モジュールでは、以下のボタンが使用可能。キー(ボタン)すべてシンボルとして定義
  #:btn1 ～ :btn12: ゲームパッドの 1～12 に対応するボタン、もしくはキーボード上の z～n、a～hの各ボタンに対応
  #:down,:left,:right,up: ゲームパッドの方向ボタンとキーボードの方向キーに対応
  #:spc: スペースバーに対応
  #:ent: Enterキーに対応
  #:esc: エスケープキーに対応
  #:alt: Altキー(左右)に対応
  #:ctl: コントロールキー(左右)に対応
  #:sft: シフトキー(左右)に対応
  #
  #また、本モジュールのメソッドに "trigger", "pushed" の２つのメソッドがあるが、
  #"trigger"系メソッドは、「押されていたら常にtrue」を示すのに対して、
  #"pushed"系メソッドは、「押した瞬間のみtrue、次の更新(Input.update)の時以降は、
  #ボタンを放して再び押されるまでfalse」という機能を持つ
  module Input
    BTNS = 12 # 使用するボタン数(ボタン１〜ボタン１２)
    @@joy = nil
    @@joy = SDL::Joystick.open(0) if SDL::Joystick.num >= 1
    @@quit = false
    @@toggle_screen_mode = true
    @@click_start_tick = 0

    @@syms = [:btn1, :btn2, :btn3, :btn4, :btn5, :btn6, :btn7, :btn8, :btn9, :btn10, :btn11, :btn12,
              :down, :left, :right, :up,  :spc, :ent, :esc, :alt, :ctl, :sft]

    @@mods = [SDL::Key::MOD_LALT, SDL::Key::MOD_RALT, SDL::Key::MOD_LCTRL, SDL::Key::MOD_RCTRL,
              SDL::Key::MOD_LSHIFT, SDL::Key::MOD_RSHIFT]

    @@btn2sym = {SDL::Key::Z => :btn1, SDL::Key::X => :btn2, SDL::Key::C => :btn3,
                 SDL::Key::A => :btn4, SDL::Key::S => :btn5, SDL::Key::D => :btn6,
                 SDL::Key::Q => :btn7, SDL::Key::W => :btn8, SDL::Key::E => :btn9,
                 SDL::Key::V => :btn10, SDL::Key::B => :btn11, SDL::Key::N => :btn12,
                 SDL::Key::KP2 => :down, SDL::Key::DOWN => :down,
                 SDL::Key::KP4 => :left, SDL::Key::LEFT => :left,
                 SDL::Key::KP6 => :right, SDL::Key::RIGHT => :right,
                 SDL::Key::KP8 => :up, SDL::Key::UP => :up,
                 SDL::Key::SPACE => :spc,
                 SDL::Key::RETURN => :ent,
                 SDL::Key::ESCAPE => :esc,
                 SDL::Key::MOD_LALT => :alt, SDL::Key::MOD_RALT => :alt,
                 SDL::Key::MOD_LCTRL => :ctl, SDL::Key::MOD_RCTRL => :ctl,
                 SDL::Key::MOD_LSHIFT => :sft, SDL::Key::MOD_RSHIFT => :sft}

    @@num2bsym = [:btn1,  :btn2,  :btn3,  :btn4,  :btn5,  :btn6,
                  :btn7,  :btn8,  :btn9,  :btn10, :btn11, :btn12]

    def Input::create_btns #:nodoc:
      return {:btn1  => 0, :btn2  => 0, :btn3  => 0,
              :btn4  => 0, :btn5  => 0, :btn6  => 0,
              :btn7  => 0, :btn8  => 0, :btn9  => 0,
              :btn10 => 0, :btn11 => 0, :btn12 => 0,
              :down  => 0, :left  => 0, :right => 0, :up => 0,
              :spc   => 0, :ent   => 0, :esc   => 0,
              :alt   => 0, :ctl   => 0, :sft   => 0}
    end

    @@btn = {:trigger => create_btns,
             :pushed  => create_btns,
             :pre     => create_btns}

    @@move_amount = [{:down =>  0, :left => -1, :right =>  1, :up =>  0},
                     {:down =>  1, :left =>  0, :right =>  0, :up => -1}]

    @@process = {SDL::Event2::Active          => lambda {|e| Input::process_active(e)},
                 SDL::Event2::Quit            => lambda {|e| Input::process_quit(e)},
                 SDL::Event2::KeyDown         => lambda {|e| Input::process_keydown(e)},
                 SDL::Event2::KeyUp           => lambda {|e| Input::process_keyup(e)},
                 SDL::Event2::JoyAxis         => lambda {|e| Input::process_joyaxis(e)},
                 SDL::Event2::JoyButtonDown   => lambda {|e| Input::process_joybuttondown(e)},
                 SDL::Event2::JoyButtonUp     => lambda {|e| Input::process_joybuttonup(e)},
                 SDL::Event2::MouseMotion     => lambda {|e| Input::process_mousemotion(e)},
                 SDL::Event2::MouseButtonDown => lambda {|e| Input::process_mousebuttondown(e)},
                 SDL::Event2::MouseButtonUp   => lambda {|e| Input::process_mousebuttonup(e)}}
    @@process.default = lambda {|e|  }

    @@mouse = {:pos   => {:x => 0, :y => 0, :dx => 0, :dy => 0},
               :trigger => {:left => false, :middle => false, :right => false}, # 2008.06.11
               :click => {:left => false, :middle => false, :right => false, :interval => 200},
               :drag  => {:left => false, :middle => false, :right => false, :x => 0, :y => 0},
               :drop  => {:left => false, :middle => false, :right => false, :succeed => true},
               :inner => true}

    def Input::process_quit(e) #:nodoc:
      @@quit = true
    end

    def Input::process_keydown(e) #:nodoc:
      set_btn(@@btn2sym[e.sym]) if @@btn2sym.include?(e.sym)
      @@mods.each{|m| set_btn(@@btn2sym[m]) if e.mod & m == m}
    end

    def Input::process_keyup(e) #:nodoc:
      reset_btn(@@btn2sym[e.sym]) if @@btn2sym.include?(e.sym)
      @@mods.each{|m| reset_btn(@@btn2sym[m]) if e.mod & m == m}
    end

    def Input::process_joyaxis(e) #:nodoc:
      if e.axis == 0
        if e.value >= 16384
          set_btn(:right)
        elsif e.value < -16384
          set_btn(:left)
        else
          reset_btn(:left)
          reset_btn(:right)
        end
      elsif e.axis == 1
        if e.value >= 16384
          set_btn(:down)
        elsif e.value < -16384
          set_btn(:up)
        else
          reset_btn(:down)
          reset_btn(:up)
        end
      end
    end

    def Input::process_joybuttondown(e) #:nodoc:
      set_btn(@@num2bsym[e.button]) if e.button < BTNS
    end

    def Input::process_joybuttonup(e) #:nodoc:
      reset_btn(@@num2bsym[e.button]) if e.button < BTNS
    end

    def Input::process_mousemotion(e) #:nodoc:
      @@mouse[:pos][:x]  = e.x
      @@mouse[:pos][:y]  = e.y
      @@mouse[:pos][:dx] = e.xrel
      @@mouse[:pos][:dy] = e.yrel
    end

    def Input::process_mousebuttondown(e) #:nodoc:
      set_mouse_button(:trigger, e.button)
      return unless @@mouse[:inner]
      click_mouse_button(:click, e.button)
      set_mouse_button(:drag, e.button)
      @@mouse[:drag][:x] = @@mouse[:pos][:x]
      @@mouse[:drag][:y] = @@mouse[:pos][:y]
      @@click_start_tick = SDL.getTicks
    end

    def Input::process_mousebuttonup(e) #:nodoc:
      reset_mouse_button(:trigger, e.button)
      click_interval = SDL.getTicks - @@click_start_tick
      if click_interval < @@mouse[:click][:interval]
        [:left, :middle, :right].each{|b| @@mouse[:drag][b] = false }
      else
        @@mouse[:drop][:left]    = @@mouse[:drag][:left] and (e.button == SDL::Mouse::BUTTON_LEFT)
        @@mouse[:drop][:middle]  = @@mouse[:drag][:left] and (e.button == SDL::Mouse::BUTTON_MIDDLE)
        @@mouse[:drop][:right]   = @@mouse[:drag][:left] and (e.button == SDL::Mouse::BUTTON_RIGHT)
        @@mouse[:drop][:succeed] = [:left,:middle,:right].inject(false){|r,i| r |= @@mouse[:drag][i]} && @@mouse[:inner]
        [:left, :middle, :right].each{|b| @@mouse[:drag][b] = false }
      end
    end

    def Input::process_active(e) #:nodoc:
      @@mouse[:inner] = e.gain if e.state == 1
    end

    def Input::process_default(e) #:nodoc:
    end

    def Input::click_mouse_button(mode, btn) #:nodoc:
      @@mouse[mode][:left]    = (btn == SDL::Mouse::BUTTON_LEFT)
      @@mouse[mode][:middle]  = (btn == SDL::Mouse::BUTTON_MIDDLE)
      @@mouse[mode][:right]   = (btn == SDL::Mouse::BUTTON_RIGHT)
    end

    def Input::set_mouse_button(mode, btn) #:nodoc:
      @@mouse[mode][:left]    = (btn == SDL::Mouse::BUTTON_LEFT)
      @@mouse[mode][:middle]  = (btn == SDL::Mouse::BUTTON_MIDDLE)
      @@mouse[mode][:right]   = (btn == SDL::Mouse::BUTTON_RIGHT)
    end

    def Input::reset_mouse_button(mode, btn) #:nodoc:
      @@mouse[mode][:left]    = false if (btn == SDL::Mouse::BUTTON_LEFT)
      @@mouse[mode][:middle]  = false if (btn == SDL::Mouse::BUTTON_MIDDLE)
      @@mouse[mode][:right]   = false if (btn == SDL::Mouse::BUTTON_RIGHT)
    end

    def Input::set_btn(n) #:nodoc:
      @@btn[:trigger][n] = 1
      return if @@btn[:pre][n] == 1
      @@btn[:pushed][n] = 1
      @@btn[:pre][n] = 1
    end

    def Input::reset_btn(n) #:nodoc:
      @@btn.each_key{|k| @@btn[k][n] = 0}
    end

    #===入力装置からの情報を更新する
    #必ず１回は呼び出す必要がある
    #(特に、ゲームループの最初に呼び出す必要がある
    #また、このメソッドを呼び出すのは必ずメインスレッドから呼び出すこと
    def Input::update
      SDL::Joystick.updateAll
      @@btn[:pushed].each_key{|p| @@btn[:pushed][p] = 0 }
      [:dx, :dy].each{|e| @@mouse[:pos][e] = 0 }
      [:left, :middle, :right].each{|e|
        @@mouse[:click][e] = false
        @@mouse[:drop][e] = false
      }
      e_list = []
      while e = SDL::Event2.poll
        e_list << e
      end
      e_list.reverse.each{|e|
        @@process[e.class].call(e)
        if @@btn[:trigger][:alt] & @@btn[:pushed][:ent]==1 and @@toggle_screen_mode
          Screen.toggle_mode
          @@btn[:trigger][:alt] = false
          @@btn[:pushed][:ent] = 0
        end
      }
    end

    #===指定のボタンがすべて押下状態かを問い合わせるメソッド
    #_inputs_:: ボタンを示すシンボル。複数指定可能
    #((例)Input.trigger_all?(:btn1, :btn2) #ボタン１とボタン２が押されている)
    #返却値:: すべて押下状態ならば true を返す
    def Input::trigger_all?(*inputs)
      raise MiyakoError, "No setting any buttons! : trigger_all?" if inputs.length == 0
      return inputs.inject(false){|r, v| r &= (@@btn[:trigger][v] == 1)}
    end

    #===指定のボタンがどれかが押下状態かを問い合わせるメソッド
    #引数を省略した場合は、「どれかのキーが押下状態か」を問い合わせる。
    #_inputs_:: ボタンを示すシンボル。複数指定可能
    #((例)Input.trigger_all?(:btn1, :btn2) #ボタン１かボタン２、もしくはその両方が押されている)。
    #返却値:: どれかが押下状態ならば true を返す
    def Input::trigger_any?(*inputs)
      inputs = @@syms if inputs.length == 0
      return inputs.inject(false){|r, v| r |= (@@btn[:trigger][v] == 1)}
    end

    #===指定のボタンがすべて押されたかを問い合わせるメソッド
    #_inputs_:: ボタンを示すシンボル。複数指定可能
    #((例)Input.trigger_all?(:btn1, :btn2) #ボタン１とボタン２が押されている)
    #返却値:: すべて押されていれば true を返す
    def Input::pushed_all?(*inputs)
      raise MiyakoError, "No setting any buttons! : trigger_any?" if inputs.length == 0
      return inputs.inject(true){|r, v| r &= (@@btn[:pushed][v] == 1)}
    end

    #===指定のボタンのどれかが押されたかを問い合わせるメソッド
    #_inputs_:: ボタンを示すシンボル。複数指定可能
    #((例)Input.trigger_all?(:btn1, :btn2) #ボタン１かボタン２、もしくはその両方が押されている)
    #返却値:: すべて押されていれば true を返す
    def Input::pushed_any?(*inputs)
      inputs = @@syms if inputs.length == 0
      return inputs.inject(false){|r, v| r |= (@@btn[:pushed][v] == 1)}
    end

    #===ボタンが押下状態にある方向を取得する
    #方向キーが押下状態にある情報を、２要素の配列［x,y］で示す。
    #
    #各要素の値は以下の通り。
    #x ・・・ -1:左、0:変化なし、1:右
    #
    #y ・・・ -1:上、0:変化なし、1:下
    #返却値:: 移動方向を示す配列
    def Input::trigger_amount
      amt = [0, 0]
      [:down, :left, :right, :up].each{|d| [0, 1].each{|n| amt[n] += @@btn[:trigger][d] * @@move_amount[n][d]} }
      return amt
    end

    #===ボタンが押された方向を取得する
    #方向キーが押された情報を、２要素の配列［x,y］で示す。
    #
    #各要素の値は以下の通り。
    #x ・・・ -1:左、0:変化なし、1:右
    #
    #y ・・・ -1:上、0:変化なし、1:下
    #返却値:: 移動方向を示す配列
    def Input::pushed_amount
      amt = [0, 0]
      [:down, :left, :right, :up].each{|d| [0, 1].each{|n| amt[n] += @@btn[:pushed][d] * @@move_amount[n][d]} }
      return amt
    end

    #===ウィンドウの「閉じる」ボタンが選択されたかどうかを問い合わせる
    #Windowsの場合、ウィンドウ右上の「×」ボタンを押したときに相当
    #返却値:: 「×」ボタンが押されていれば true を返す
    def Input::quit?
      return @@quit
    end

    #===エスケープキーが押されたかどうかを問い合わせる
    #返却値:: エスケープキーが押されていれば true を返す
    def Input::escape?
      return (@@btn[:pushed][:esc] == 1)
    end

    #===ウィンドウの「×」ボタンか、エスケープキーが押されたかどうかを問い合わせる
    #返却値:: 「×」ボタンが押されてる、もしくはエスケープキーが押されていれば true を返す
    def Input::quit_or_escape?
      return @@quit || (@@btn[:pushed][:esc] == 1)
    end

    #===マウスカーソルを表示する
    def Input::mouse_cursor_show
      SDL::Mouse.show
    end

    #===マウスカーソルを隠蔽する
    def Input::mouse_cursor_hide
      SDL::Mouse.hide
    end

    #===マウスの現在位置を取得する
    #求める値は、{:x=>n,:y=>n}で示すハッシュとする
    #原点は、画面領域の左上を{:x=>0,:y=>0}とする
    #返却値:: マウスカーソルの位置を示すPoint構造体
    def Input::get_mouse_position
      return Point.new(@@mouse[:pos][:x],@@mouse[:pos][:y])
    end

    #===マウスの移動量を取得する
    #求める値は、{:x=>n,:y=>n}で示すハッシュとする
    #移動量は、右下方向を正とする
    #返却値:: マウスカーソルの移動量を示すSize構造体
    def Input::get_mouse_amount
      return Size.new(@@mouse[:pos][:dx],@@mouse[:pos][:dy])
    end

    #===ボタンがクリックされたかを問い合わせるメソッド
    #ボタンの問い合わせは可変個数のシンボルで行う。指定できるボタンは以下の通り
    #このメソッドを呼び出した後、そのボタンの返却値は、Input.updateが呼ばれない限りfalseになることに注意。
    #
    #:left : 左ボタン
    #:middle : 中ボタン(ホイールをクリック)
    #:right : 右ボタン
    #:any : 上記ボタンの少なくともどれか一つ
    #
    #_btn_:: 問い合わせるボタンを示すシンボル(可変個)
    #返却値:: ボタンが押されていれば true を返す
    def Input::click?(btn)
      btns = (btn == :any ? [:left, :middle, :right] : [btn])
      ret = btns.inject(false){|r, f| r |= @@mouse[:click][f]}
      return ret
    end

    #===ボタンが押されているかを問い合わせるメソッド
    #ボタンの問い合わせは可変個数のシンボルで行う。指定できるボタンは以下の通り
    #
    #:left : 左ボタン
    #:middle : 中ボタン(ホイールをクリック)
    #:right : 右ボタン
    #:any : 上記ボタンの少なくともどれか一つ
    #
    #_btn_:: 問い合わせるボタンを示すシンボル(可変個)
    #返却値:: ボタンが押されていれば true を返す
    def Input::mouse_trigger?(btn)
      return btn == :any ? (@@mouse[:trigger][:left] || @@mouse[:trigger][:middle] || @@mouse[:trigger][:right]) : @@mouse[:trigger][btn]
    end

    #===ドラッグアンドドロップが行われたかどうかを問い合わせる
    #ドラッグアンドドロップした際に使ったボタンの問い合わせは、
    #可変個数のシンボルで行う。指定できるボタンは以下の通り
    #
    #:left : 左ボタン
    #:middle : 中ボタン(ホイールをクリック)
    #:right : 右ボタン
    #:any : 上記ボタンの少なくともどれか一つ
    #
    #_btn_:: 問い合わせるボタンを示すシンボル(可変個)
    #返却値:: ドラッグアンドドロップが成功していれば、true を返す
    def Input::drag_and_drop?(btn)
      return @@mouse[:drop][:succeed] && (btn == :any ? (@@mouse[:drop][:left] || @@mouse[:drop][:middle] || @@mouse[:drop][:right]) : @@mouse[:click][btn])
    end

    #===ドラッグアンドドロップされた範囲を取得する
    #取得できる範囲は、以下のハッシュで取得できる。
    #{:drag_x => ドラッグが行われた x 座標, :drag_y => ドラッグが行われた y 座標, :drop_x => ドロップが行われた x 座業, :drop_y => ドロップが行われた y 座標}
    #返却値:: ドラッグアンドドロップが成功していれば、移動範囲を示すハッシュ、失敗していれば nil を返す
    def Input::get_drag_and_drop_range
      return @@mouse[:drop][:succeed] ? {:drag_x => @@mouse[:drag][:x], :drag_y => @@mouse[:drag][:y], :drop_x => @@mouse[:pos][:x], :drop_y => @@mouse[:pos][:y]} : nil
    end

    #===ダブルクリックの間隔を取得する
    #間隔は、ミリ秒単位で取得できる
    #返却値:: ボタンのクリック間隔
    def Input::click_interval
      return @@mouse[:click][:interval]
    end

    #===ダブルクリックの間隔を設定する
    #間隔は、ミリ秒単位で設定できる
    #_v_:: ボタンのクリック間隔
    def Input::click_interval=(v)
      @@mouse[:click][:interval] = v
    end

    #===マウスカーソルが画面の内側に有るかどうかを問い合わせる
    #返却値:: マウスカーソルが画面内ならtrueを返す
    def Input::mouse_cursor_inner?
      return @@mouse[:inner]
    end

    #===Alt+Enterキーを押したときにフル・ウィンドウモード切り替えの可否を切り替える
    def Input::enable_toggle_screen_mode
      @@toggle_screen_mode = true
    end

    #===Alt+Enterキーを押したときにフル・ウィンドウモード切り替えを不可にする
    def Input::disenable_toggle_screen_mode
      @@toggle_screen_mode = false
    end

    #===Alt+Enterキーを押したときにフル・ウィンドウモード切り替えができるかどうかを問い合わせる
    #返却値:: 切り替えができるときは true を返す
    def Input::toggle_screen_mode?
      return @@toggle_screen_mode
    end
  end
end
