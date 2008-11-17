=begin
--
Miyako v1.5
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
  #==アニメーション管理クラス
  #スプライトのアニメーションの構築・実行を管理するクラス
  class SpriteAnimation
    include SpriteBase
    include Animation
    include Layout
    include SingleEnumerable
    include MiyakoTap

    @@animation_list = []
    
    #===インスタンスの作成
    #アニメーションを行うための初期設定を行う。
    #アニメーションは２種類の方法があり、
    #
    #「一つのスプライトをow,ohプロパティで分割して、表示開始位置をずらすことでアニメーションを行う」方法と、
    #
    #(RPGのキャラチップを想定。　以降、「単体アニメーション」と呼ぶ)
    #
    #「複数枚のスプライトの配列を渡し、要素順に表示させることでアニメーションを行う」方法がある。
    #
    #(いわゆる「ぱらぱら漫画」方式。　以降、「配列アニメーション」と呼ぶ)
    #
    #「パターン番号」は、キャラクタパターン(画像を一定の大きさ(ow,oh)で切り分けた単位)の番号を意味する。
    #
    #単体アニメーションのときは、画像の左上から0,1,2,...と数える。
    #
    #配列アニメーションのときは、配列のインデックスがパターン番号となる。
    #
    #
    #
    #利用できるパラメータは以下の通り
    #
    #:sprite => sprite|spriteの配列　アニメーションさせるスプライト(インスタンス単体もしくはインスタンスの配列)。必須パラメータ。
    #
    #:dir => :h|:v　単体アニメーションのとき、縦方向に位置をずらして表示させる(:h指定時)か、横方向か(:v指定時)を決定する。デフォルトは:h。
    #
    #:pattern_list => 表示させるパターン番号を指定するための配列。配列の要素の順にパターンが表示される。
    #
    #_hash_:: パラメータ名とパラメータとのハッシュ
    #返却値:: 生成されたインスタンス
    def initialize(hash)
      init_layout
      @units = Array.new
      @slist = nil

      hash[:dir] ||= :h
      @dir   = hash[:dir]
      s = hash[:sprite]
      hash[:pattern_list] ||= nil
      @plist = hash[:pattern_list]
      hash[:wait] ||= 0
      wait = hash[:wait]
      hash[:move_offset] ||= nil
      @move_offset = hash[:move_offset]
      hash[:position_offset] ||= nil
      @pos_offset = hash[:position_offset]
      hash[:align] ||= :max
      @align = hash[:align]
      hash[:loop] ||= true
      @loop = hash[:loop]

      @pat_len  = 1
      @pat_olen = 1
      @chr_len  = 1
      @chr_olen = 1

      @slist = Array.new
      if s.kind_of?(Sprite)
        set_layout_size(s.ow, s.oh)
        move_to(s.x, s.y)
        s.snap(self)
        s.left
        s.top
        s.hide
        @pat_len  = @dir == :h ? s.h  : s.w
        @pat_olen = @dir == :h ? s.oh : s.ow
        @chr_len  = @dir == :h ? s.w  : s.h
        @chr_olen = @dir == :h ? s.ow : s.oh
        @pats     = @pat_len / @pat_olen
      elsif s.kind_of?(Array)
        first = s[0]
        set_layout_size(first.ow, first.oh)
        move_to(first.x, first.y)
        s.each{|ss|
          ss.snap(self)
          ss.left
          ss.top
          @slist.push(ss)
          ss.hide
        }
        @pat_len  = @slist.length
        @pats     = @slist.length
      else
        raise MiyakoError, "Illegal sprite list for SpriteAnimation."
      end

      if @plist
        if @align == :min
          @pats = @plist.length if @pats > @plist.length
        else
          @pats = @plist.length if @pats < @plist.length
        end
      else
        @plist = Array.new unless @plist
      end

      if @move_offset
        if @align == :min
          @pats = @move_offset.length if @pats > @move_offset.length
        else
          @pats = @move_offset.length if @pats < @move_offset.length
        end
      else
        @move_offset = Array.new
      end

      if @pos_offset
        if @align == :min
          @pats = @pos_offset.length if @pats > @pos_offset.length
        else
          @pats = @pos_offset.length if @pats < @pos_offset.length
        end
      else
        @pos_offset = Array.new
      end

      if wait.kind_of?(Array)
        @waits = wait.collect{|w| w.kind_of?(Float) ? WaitCounter.new(w) : w }
        if @align == :min
          @pats = @waits.length if @pats > @waits.length
        else
          @pats = @waits.length if @pats < @waits.length
        end
      else
        @waits = Array.new
      end

      if @plist.length == 0
        @pats.times{|p| @plist.push(p)}
      elsif @plist.length < @pats
        tmp = @plist
        @plist = Array.new
        @pats.times{|p|
          v = p % tmp.length
          @plist.push(tmp[v])
        }
      end

      if @slist.length == 0
        @pats.times{|p| @slist.push(s) }
        @pats.times{|p|
          u = SpriteUnit.new(@slist[p].dp, @slist[p].bitmap, @slist[p].ox, @slist[p].oy, @slist[p].ow, @slist[p].oh, 0, 0, nil, Screen.rect)
          px = p % (@pat_len / @pat_olen)
          if @dir == :h
            u.oy = @slist[p].oh * @plist[px]
          else
            u.ox = @slist[p].ow * @plist[px]
          end
          @units.push(u)
        }
      elsif @slist.length < @pats
        tmp = @slist
        @slist = Array.new
        @pats.times{|p|
          v = p % tmp.length
          @slist.push(tmp[v])
          u = SpriteUnit.new(tmp[v].dp, tmp[v].bitmap, tmp[v].ox, tmp[v].oy, tmp[v].ow, tmp[v].oh, 0, 0, nil, Screen.rect)
          @units.push(u)
        }
      else
        @pats.times{|p|
          u = SpriteUnit.new(@slist[p].dp, @slist[p].bitmap, @slist[p].ox, @slist[p].oy, @slist[p].ow, @slist[p].oh, 0, 0, nil, Screen.rect)
          @units.push(u)
        }
      end

      if @move_offset.length == 0
        @pats.times{|p|
          @move_offset.push(Point.new(0,0))
        }
      elsif @move_offset.length < @pats
        tmp = @move_offset
        @move_offset = Array.new
        @pats.times{|p|
          v = p % tmp.length
          @move_offset.push(tmp[v])
        }
      end

      if @pos_offset.length == 0
        @pats.times{|p|
          @pos_offset.push(0)
        }
      elsif @pos_offset.length < @pats
        tmp = @pos_offset
        @pos_offset = Array.new
        @pats.times{|p|
          v = p % tmp.length
          @pos_offset.push(tmp[v])
        }
      end

      if @waits.length == 0
        if wait.kind_of?(Integer)
          @waits = Array.new
          @waits.fill(wait, 0, @pats)
        elsif wait.kind_of?(Float)
          @waits = Array.new
          @waits.fill(WaitCounter.new(wait), 0, @pats)
        else
          raise MiyakoError, "Illegal wait counter for SpriteAnimation."
        end
      elsif @waits.length < @pats
        tmp = @waits
        @waits = Array.new
        @pats.times{|p|
          v = p % tmp.length
          @waits.push(tmp[@plist[v]])
        }
      end

      @chrs  = @chr_len / @chr_olen

      @cnum  = 0
      @pnum  = 0
      @cnt   = 0
      @exec  = false
      @visible = false

      @now = @units[0]
      @now.x = @slist[@plist[@pnum]].x + @move_offset[@pnum][0]
      @now.y = @slist[@plist[@pnum]].y + @move_offset[@pnum][1]

      @@animation_list.push(self)
    end

    attr_accessor :visible

    def update_layout_position #:nodoc:
      if @now
        @now.x = @layout.pos[0]
        @now.y = @layout.pos[1]
      end
    end
    
    #===アニメーションのdp値を取得する
    #返却値:: アニメ-ションのdp値
    def dp
      return @units[0].dp
    end

    #===アニメーションのdp値を変更する
    #スプライト本体のdpには影響が無い
    #
    #(逆に言うと、必ず設定すること！)
    #_v_:: dp値
    def dp=(v)
      @units.each{|u| u.dp = v}
    end

    #===現在表示しているスプライトのowを取得する
    #返却値:: スプライトのow
    def ow
      return @now.ow
    end

    #===現在表示しているスプライトのohを取得する
    #返却値:: スプライトのoh
    def oh
      return @now.oh
    end

    #===表示するパターンの番号を変更する
    #_pnum_:: パターン番号
    #返却値:: 自分自身
    def pattern(pnum)
      @pnum = pnum if pnum < @pats
      set_pat
      @cnt = @waits[@plist[@pnum]] if @exec
      return self
    end

    #===現在表示しているパターンを取得する
    #返却値:: 現在表示しているスプライトのインスタンス
    def get_pattern
      return @plist[@pnum]
    end

    #===あとで書く
    #_cnum_:: あとで書く
    #返却値:: あとで書く
    def character(cnum)
      return if cnum >= @chrs
      @cnum = cnum
      set_chr
      return self
    end

    #===あとで書く
    #_d_:: あとで書く
    #返却値:: あとで書く
    def move_character(d)
      @cnum = (@cnum + d) % @chrs
      @cnum = @cnum + @chrs if @cnum < 0
      set_chr
      return self
    end

    def get_character #:nodoc:
      return @cnum
    end
    
    #===アニメーションを開始する
    #パターンがリセットされていないときは、一時停止から復帰した時と同じ動作をする
    #返却値:: 自分自身
    def start
      return if @exec
      set_pat
      @now.x = @slist[@plist[@pnum]].x + @move_offset[@pnum][0]
      @now.y = @slist[@plist[@pnum]].y + @move_offset[@pnum][1]
      if @dir == :h
        @now.oy += @pos_offset[@pnum]
      else
        @now.ox += @pos_offset[@pnum]
      end
      @cnt = @waits[@plist[@pnum]]
      @cnt.start if @cnt.kind_of?(WaitCounter)
      @exec = true
      return self
    end

    #===アニメーションを停止する
    #停止しても、表示していたパターンはリセットされていない
    #返却値:: 自分自身
    def stop
      return unless @exec
      if @dir == :h
        @now.oy -= @pos_offset[@pnum]
      else
        @now.ox -= @pos_offset[@pnum]
      end
      @cnt.stop if @cnt.kind_of?(WaitCounter)
      @exec = false
      return self
    end

    #===アニメーションの開始・停止を切り替える
    #返却値:: 自分自身
    def toggle_exec
      if @exec
        stop
      else
        start
      end
      return self
    end

    def update_animation #:nodoc:
      return unless @exec
      if @dir == :h
        @now.oy -= @pos_offset[@pnum]
      else
        @now.ox -= @pos_offset[@pnum]
      end
      if @cnt.kind_of?(Integer)
        update_frame
      else
        update_wait_counter
      end
      @now.x = @slist[@plist[@pnum]].x + @move_offset[@pnum][0]
      @now.y = @slist[@plist[@pnum]].y + @move_offset[@pnum][1]
      if @dir == :h
        @now.oy += @pos_offset[@pnum]
      else
        @now.ox += @pos_offset[@pnum]
      end
      Screen.sprite_list.push(@now) if @visible
    end

    def update_frame #:nodoc:
      if @cnt == 0
        @pnum = (@pnum + 1) % @pats
        if @loop == false && @pnum == 0
          stop
          return
        end
        set_pat
        @cnt = @waits[@plist[@pnum]]
      else
        @cnt -= 1
      end
    end
    
    def update_wait_counter #:nodoc:
      unless @cnt.waiting?
        @pnum = (@pnum + 1) % @pats
        if @loop == false && @pnum == 0
          stop
          return
        end
        set_pat
        @cnt = @waits[@plist[@pnum]]
        @cnt.start
      end
    end

    def set_pat #:nodoc:
      @now = @units[@plist[@pnum]]
    end

    def set_chr #:nodoc:
      @units.each{|u|
        if @dir == :h
          u.ox = @chr_olen * @cnum
        else
          u.oy = @chr_olen * @cnum
        end
      }
    end

    #===アニメーションのパターンをリセットする
    #返却値:: 自分自身
    def reset
      @pnum = 0
      @cnt  = 0
      return self
    end

    #===アニメーションが実行中かを返す
    #返却値:: アニメーションが実行されていれば true
    def exec?
      return @exec
    end

    #===アニメーションを表示する
    #返却値:: 自分自身
    def show
      org_visible = @visible
      @visible = true
      if block_given?
        res = Proc.new.call
        hide unless org_visible
        return res
      end
      return self
    end
    
    #===アニメーションを隠蔽する
    #返却値:: 自分自身
    def hide
      @visible = false
      return self
    end
    
    # アニメーションのビューポートを返す
    # 返却値:: ビューポートを示すRectクラスのインスタンス
    def viewport
      return @now.viewport
    end

    # ビューポートを新しく設定する
    # _vp_:: 新しいビューポートを示すRectクラスのインスタンス
    # 返却値:: 自分自身を返す
    def viewport=(vp)
      @layout.viewport = vp
      @units.each{|u| u.viewport = vp }
      return self
    end

    # 現在実行中のパターンの元になったスプライトユニットを返す
    # 返却値:: 現在表示しているスプライトユニット
   def to_unit
      return @now.dup
    end
    
    # 現在実行中のパターンの画像を返す
    # 返却値:: 現在表示している画像(bitmap)
    def bitmap
      return @now.bitmap
    end
    
    # 現在実行中のパターンの元になったスプライトを返す
    # 返却値:: 現在表示しているスプライト
    def to_sprite
      return @slist[@plist[@pnum]]
    end
    
    #===画面に描画を指示する
    #現在の画像を、現在の状態で描画するよう指示する
    #--
    #(但し、実際に描画されるのはScreen.renderメソッドが呼び出された時)
    #++
    #返却値:: 自分自身を返す
    def render
      Screen.sprite_list.push(@now.dup)
      return self
    end

    #===インスタンスに束縛されているオブジェクトを解放する
    def dispose
      @slist.clear
      @units.each{|u| u.bitmap = nil}
      @units.clear
      @waits.clear
      @plist.clear
      @move_offset.clear
      @pos_offset.clear
      @@animation_list.delete(self)
    end

    def SpriteAnimation.clear #:nodoc:
      @@animation_list.clear
    end

    #===すべてのSpriteAnimationクラスのインスタンスのアニメーション状態を更新する
    #Sprite.update、Miyako.main_loopメソッド、Sceneモジュールを使用しているとき
    #は呼び出す必要はないが、Sprite.renderメソッドを使用するときは明示的に呼び出す
    #必要がある。
    def SpriteAnimation.update_animation
      @@animation_list.each{|a| a.update_animation }
    end
    
    def SpriteAnimation::recalc_layout #:nodoc:
      @@animation_list.each{|a| a.calc_layout }
    end
    
    def SpriteAnimation.reset_viewport #:nodoc:
      @@animation_list.each{|a| a.viewport = Screen.rect }
    end
  end
end

