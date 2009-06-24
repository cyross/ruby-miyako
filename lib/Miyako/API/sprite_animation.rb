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
  #==アニメーション管理クラス
  #スプライトのアニメーションの構築・実行を管理するクラス
  class SpriteAnimation
    include SpriteBase
    include Animation
    include Layout
    include SingleEnumerable

    attr_accessor :visible #レンダリングの可否(true->描画 false->非描画)
    
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
    #:sprite => sprite|spriteの配列　アニメーションさせるスプライト(インスタンス単体もしくはインスタンスの配列)。必須パラメータ
    #
    #:dir => :h|:v　単体アニメーションのとき、縦方向に位置をずらして表示させる(:h指定時)か、横方向か(:v指定時)を決定する。デフォルトは:h
    #
    #:pattern_list => 表示させるパターン番号を指定するための配列。配列の要素の順にパターンが表示される
    #
    #:loop => アニメーションを繰り返し更新するかどうかを示すフラグ。falseのときは、1回パターンを実行した後、アニメーションを終了する(true/false)
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
        @now = s.to_unit unless @now
        set_layout_size(s.ow, s.oh)
        move_to(s.x, s.y)
        s.snap(self)
        s.left
        s.top
        @pat_len  = @dir == :h ? s.h  : s.w
        @pat_olen = @dir == :h ? s.oh : s.ow
        @chr_len  = @dir == :h ? s.w  : s.h
        @chr_olen = @dir == :h ? s.ow : s.oh
        @pats     = @pat_len / @pat_olen
      elsif s.kind_of?(Array)
        first = s[0]
        @now = first.to_unit unless @now
        set_layout_size(first.ow, first.oh)
        move_to(first.x, first.y)
        @slist = s.map{|ss|
          ss.snap(self)
          ss.left.top
        }
        @pat_len  = @slist.length
        @pats     = @slist.length
      else
        raise MiyakoTypeError, "Illegal sprite list for SpriteAnimation."
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
        @plist = @plist.cycle.take(@pats)
      end

      if @slist.length == 0
        @slist = Array.new(@pats){|pat| s }
        @units = Array.new(@pats){|pat|
          u = @slist[pat].to_unit.dup
          px = pat % (@pat_len / @pat_olen)
          if @dir == :h
            u.oy = @slist[pat].oh * @plist[px]
          else
            u.ox = @slist[pat].ow * @plist[px]
          end
          u
        }
      elsif @slist.length < @pats
        tmp = @slist
        @slist = @slist.cycle.take(@pats)
        @units = Array.new(@pats){|pat| @slist[pat].to_unit.dup }
      else
        @units = Array.new(@pats){|pat| @slist[pat].to_unit.dup }
      end

      if @move_offset.length == 0
        @move_offset = Array.new(@pats){|pat| Point.new(0,0) }
      elsif @move_offset.length < @pats
        @move_offset = @move_offset.cycle.take(@pats)
      end

      if @pos_offset.length == 0
        @pos_offset = Array.new(@pats){|pat| 0 }
      elsif @pos_offset.length < @pats
        @pos_offset = @pos_offset.cycle.take(@pats)
      end

      if @waits.length == 0
        if wait.kind_of?(Integer)
          @waits = Array.new(@pats){|pat| wait}
        elsif wait.kind_of?(Float)
          @waits = Array.new(@pats){|pat| WaitCounter.new(wait)}
        else
          raise MiyakoTypeError, "Illegal counter class for SpriteAnimation."
        end
      elsif @waits.length < @pats
        @waits = @waits.cycle.take(@pats)
      end

      @chrs  = @chr_len / @chr_olen

      @cnum  = 0
      @pnum  = 0
      @cnt   = 0
      @exec  = false
      @visible = true

      @now = @units[0]
      @now.move_to(@slist[@plist[@pnum]].x + @move_offset[@pnum][0],
                   @slist[@plist[@pnum]].y + @move_offset[@pnum][1])
    end
    
    def initialize_copy(obj) #:nodoc:
      @units = @units.deep_dup
      @slist = @slist.deep_dup
      @plist = @plist.dup
      @move_offset = @move_offset.dup
      @pos_offset = @pos_offset.dup
      @now = @units[@plist[@pnum]]
      copy_layout
    end

    attr_accessor :visible
 
    #=== 現在表示しているスプライトの x 座標の値を取得する
    #返却値:: x 座標の値
    def x
      return @now.x
    end
 
    #=== 現在表示しているスプライトの y 座標の値を取得する
    #返却値:: y 座標の値
    def y
      return @now.y
    end
 
    #=== 現在表示しているスプライトの幅を取得する
    #返却値:: 現在表示しているスプライトの幅(ピクセル単位)
    def w
      return @now.ow
    end
 
    #=== 現在表示しているスプライトの高さを取得する
    #返却値:: 現在表示しているスプライトの高さ(ピクセル単位)
    def h
      return @now.oh
    end

    def update_layout_position #:nodoc:
      @units.each{|u| u.move_to(*@layout.pos)}
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
    def pattern=(pnum)
      @pnum = pnum if pnum < @pats
      set_pat
      @cnt = @waits[@plist[@pnum]] if @exec
      return self
    end

    #===現在表示しているパターンを取得する
    #返却値:: 現在表示しているスプライトのインスタンス
    def pattern
      return @plist[@pnum]
    end

    #===キャラクター番号を設定する
		#キャラクター番号(アニメーションさせるときに表示させるパターン群インデックス)
		#を設定する。範囲外のキャラクター番号が設定された時は何も行わない
    #_cnum_:: キャラクター番号
    def character=(cnum)
      return self if (cnum < 0 || cnum >= @chrs)
      @cnum = cnum
      set_chr
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

		#===現在のキャラクター番号を取得する
		#返却値:: キャラクター番号（0以上の整数）
    def character
      return @cnum
    end
    
    #===アニメーションを開始する
    #パターンがリセットされていないときは、一時停止から復帰した時と同じ動作をする
    #返却値:: 自分自身
    def start
      return self if @exec
      set_pat
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
      return self unless @exec
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

    #===アニメーションの更新を行う
    #アニメーションのカウントをチェックし、カウントが終了したときは新しいパターンに切り替えて、カウントを開始する
    #すべてのパターンのアニメーションが終了すれば、最初のパターンに戻り、カウントを開始する
    #但し、インスタンス生成時に:loop->falseを設定していれば、アニメーションを終了する
    #返却値:: アニメーションパターンが切り替わればtrue、切り替わらないとき、アニメーションが終了したときはfalseを返す
    def update_animation
    end

    def update_frame #:nodoc:
      if @cnt > 0
        @cnt -= 1
        return false
      end
      @pnum = (@pnum + 1) % @pats
      if @loop == false && @pnum == 0
        stop
        return false
      end
      set_pat
      @cnt = @waits[@plist[@pnum]]
      return true
    end
    
    def update_wait_counter #:nodoc:
      return false if @cnt.waiting?
      @pnum = (@pnum + 1) % @pats
      if @loop == false && @pnum == 0
        stop
        return false
      end
      set_pat
      @cnt = @waits[@plist[@pnum]]
      @cnt.start
      return true
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

    #===現在実行中のパターンの元になったスプライトユニットを返す
    #得られるインスタンスは内部でしようしてるものの複写
    #返却値:: 現在表示しているスプライトユニット
    def to_unit
      return @now.dup
    end
    
    #=== 現在実行中のパターンの画像を返す
    #返却値:: 現在表示している画像(bitmap)
    def bitmap
      return @now.bitmap
    end
    
    #===現在実行中のパターンの元になったインスタンスを返す
    #取得するパターンは、元になったインスタンスのto_spriteメソッドを呼び出した時の値となる
    #引数1個のブロックを渡せば、スプライトに補正をかけることが出来る
    #返却値:: 現在表示しているスプライト
    def to_sprite(&block)
      return @slist[@plist[@pnum]].to_sprite(&block)
    end

    #===現在表示しているスプライトの大きさを矩形で取得する
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def rect
      return Rect.new(@now.x, @now.y, @now.ow, @now.oh)
    end
 
    #===現在表示しているスプライトの最大の大きさを矩形で取得する
    #現在のパターンの大きさと同じため、rectメソッドの値と同一となる
    #返却値:: 生成された矩形(Rect構造体のインスタンス)
    def broad_rect
      return self.rect
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
    end

    #===アニメーションの現在の画像を画面に描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
    #画面の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    def render
    end

    #===アニメーションの現在の画像を画像に描画する
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。
    #転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に設定にする。
    #ブロック付きで呼び出し可能(レシーバに対応したSpriteUnit構造体が引数として得られるので、補正をかけることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|インスタンスのSpriteUnit,転送先のSpriteUnit|となる。
    #visibleメソッドの値がfalseのときは描画されない。
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    def render_to(dst)
    end
  end
end

