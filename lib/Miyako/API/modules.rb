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
=begin rdoc
==基本スプライトモジュール
スプライトの基本メソッドで構成されるテンプレートモジュール
=end
  module SpriteBase
    #===スプライトインスタンスを取得するメソッドのテンプレート
    #_data_:: あとで書く
    #返却値:: 自分自身を返す
    def to_sprite(data = nil)
      return self
    end

    #===SpriteUnit構造体を取得するメソッドのテンプレート
    #返却値:: nilを返す
    def to_unit
      return nil
    end
    
    #===描画可能・不可状態を返すメソッドのテンプレート
    #返却値:: falseを返す
    def visible
      return false
    end
    
    #===描画可能・不可状態を設定するメソッドのテンプレート
    #返却値:: falseを返す
    def visible=(v)
      return self
    end
    
    #===描画可能状態にするメソッドのテンプレート
    def show
      self.visible = true
    end
    
    #===描画不可能状態にするメソッドのテンプレート
    def hide
      self.visible = false
    end
    
    #===領域の矩形を取得するメソッドのテンプレート
    #返却値:: nilを返す
    def rect
      return nil
    end
    
    #===領域の最大矩形を取得するメソッドのテンプレート
    #返却値:: nilを返す
    def broad_rect
      return nil
    end
    
    #===画像(Bitmapクラスのインスタンス)を取得するメソッドのテンプレート
    #返却値:: nilを返す
    def bitmap
      return nil
    end
    
    #===画像内での描画開始位置(x座標)を取得するメソッドのテンプレート
    #返却値:: 0を返す
    def ox
      return 0
    end
    
    #===画像内での描画開始位置(y座標)を取得するメソッドのテンプレート
    #返却値:: 0を返す
    def oy
      return 0
    end
    
    #===画面への描画を指示するメソッドのテンプレート
    #_block_:: 呼び出し時にブロック付き呼び出しが行われたときのブロック本体。呼び先に渡すことが出来る。ブロックがなければnilが入る
    #返却値:: 自分自身を返す
    def render(&block)
      return self
    end
    
    #===画像への描画を指示するメソッドのテンプレート
    #_dst_:: 対象の画像
    #_block_:: 呼び出し時にブロック付き呼び出しが行われたときのブロック本体。呼び先に渡すことが出来る。ブロックがなければnilが入る
    #返却値:: 自分自身を返す
    def render_to(dst, &block)
      return self
    end
  end

=begin rdoc
==基本アニメーションモジュール
アニメーションの基本メソッドで構成されるテンプレートモジュール
=end
  module Animation
    #===アニメーションを開始するメソッドのテンプレート
    #返却値:: 自分自身を返す
    def start
      return self
    end

    #===アニメーションを停止するメソッドのテンプレート
    #返却値:: 自分自身を返す
    def stop
      return self
    end

    #===アニメーションパターンを先頭に戻すメソッドのテンプレート
    #返却値:: 自分自身を返す
    def reset
      return self
    end

    #===アニメーションを更新するメソッドのテンプレート
    #返却値:: falseを返す(アニメーションパターンが更新されたときにtrueを返す)
    def update_animation
      return false
    end
  end
  
  #==複数スプライト管理(配列)機能を追加するモジュール
  #配列にスプライトとして最低限の機能を追加する。
  #また、独自にswapなどのメソッドを追加。
  #render、render_toを用意し、一気に描画が可能。配列の要素順に描画される。
  #各要素の位置関係は関与していない(そこがPartsとの違い)
  module SpriteArray
    include SpriteBase
    include Animation
    include Enumerable

    #===各要素からスプライト以外の要素を取り除いた配列を作成する
    #SpriteBaseモジュール、もしくはSpriteArrayモジュールをインクルードしていない要素を削除した配列を返す
    #登録されている名前順の配列になる。
    #返却値:: 生成したスプライトを返す
    def sprite_only
      self.select{|e| e.class.include?(SpriteBase) || e.class.include?(SpriteArray)}
    end

    #===各要素からスプライト以外の要素を取り除いた配列を破壊的に作成する
    #SpriteBaseモジュール、もしくはSpriteArrayモジュールをインクルードしていない要素を削除する
    #登録されている名前順の配列になる。
    #返却値:: 自分自身を返す
    def sprite_only!
      self.delete_if{|e| !e.class.include?(SpriteBase) && !e.class.include?(SpriteArray)}
    end
  
    #===配列要素を複製したコピー配列を取得する
    #通常、インスタンスの複写に使われるdup,cloneメソッドは、同じ配列要素を見ているが、
    #このメソッドでは、要素も複製したものが複製される(各要素のdeep_copyメソッドを呼び出す)
    #返却値:: 複写した配列を返す
    def deep_copy
      self.map{|e| e.deep_copy }
    end

    #===各要素の描画可能状態を取得する
    #各要素のvisibleメソッドの値を配列で取得する。
    #登録されている名前順の配列になる。
    #返却値:: true/falseの配列
    def visible
      return self.sprite_only.map{|e| e.visible}
    end
  
    #===各要素の描画可能状態を一気に設定する
    #すべての要素のvisibleメソッドの値を変更する
    #登録されている名前順の配列になる。
    #_v_:: 設定する値(true/false)
    #返却値:: 自分自身を返す
    def visible=(v)
      self.sprite_only.each{|e| e.visible = v}
      return self
    end
  
    #===各要素の位置を変更する(変化量を指定)
    #ブロックを渡したとき、戻り値として[更新したdx,更新したdy]とした配列を返すと、
    #それがその要素での移動量となる。
    #ブロックの引数は、|要素, インデックス(0,1,2,...), dx, dy|となる。
    #(例)q=[a, b, c]
    #    #各スプライトの位置=すべて(10,15)
    #    q.move!(20,25) => aの位置:(30,40)
    #                      bの位置:(30,40)
    #                      cの位置:(30,40)
    #    q.move!(20,25){|e,i,dx,dy|
    #      [i*dx, i*dy]
    #    }
    #                   => aの位置:(10,15)
    #                      bの位置:(30,40)
    #                      cの位置:(50,65)
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move!(dx, dy)
      if block_given?
        self.sprite_only.each_with_index{|e, i| e.move!(*(yield e, i, dx, dy))}
      else
        self.sprite_only.each{|e| e.move!(dx, dy)}
      end
      self
    end

    #===各要素の位置を変更する(変化量を指定)
    #ブロックを渡したとき、戻り値として[更新したdx,更新したdy]とした配列を返すと、
    #それがその要素での移動量となる。
    #ブロックの引数は、|要素, インデックス(0,1,2,...), x, y|となる。
    #(例)q=[a, b, c]
    #    #各スプライトの位置=すべて(10,15)
    #    q.move!(20,25) => aの位置:(20,25)
    #                      bの位置:(20,25)
    #                      cの位置:(20,25)
    #    q.move!(20,25){|e,i,dx,dy|
    #      [i*dx, i*dy]
    #    }
    #                   => aの位置:( 0, 0)
    #                      bの位置:(20,25)
    #                      cの位置:(40,50)
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to!(x, y)
      if block_given?
        self.sprite_only.each_with_index{|e, i| e.move_to!(*(yield e, i, x, y))}
      else
        self.sprite_only.each{|e| e.move_to!(x, y)}
      end
      self
    end

    #===描く画像のアニメーションを開始する
    #各要素のstartメソッドを呼び出す
    #返却値:: 自分自身を返す
    def start
      self.sprite_only.each{|sprite| sprite.start }
      return self
    end
    
    #===描く画像のアニメーションを停止する
    #各要素のstopメソッドを呼び出す
    #返却値:: 自分自身を返す
    def stop
      self.sprite_only.each{|sprite| sprite.stop }
      return self
    end
    
    #===描く画像のアニメーションを先頭パターンに戻す
    #各要素のresetメソッドを呼び出す
    #返却値:: 自分自身を返す
    def reset
      self.sprite_only.each{|sprite| sprite.reset }
      return self
    end
    
    #===描く画像のアニメーションを更新する
    #各要素のupdate_animationメソッドを呼び出す
    #返却値:: 描く画像のupdate_spriteメソッドを呼び出した結果を配列で返す
    def update_animation
      self.sprite_only.map{|e|
        e.update_animation
      }
    end
  
    #===指定した要素の内容を入れ替える
    #配列の先頭から順にrenderメソッドを呼び出す。
    #描画するインスタンスは、引数がゼロのrenderメソッドを持っているもののみ(持っていないときは呼び出さない)
    #_idx1,idx2_:: 入れ替え対象の配列要素インデックス
    #返却値:: 自分自身を帰す
    def swap(idx1, idx2)
      l = self.length
      raise MiyakoValueError, "Illegal index range! : idx1:#{idx1}" if (idx1 >= l || idx1 < -l)
      raise MiyakoValueError, "Illegal index range! : idx2:#{idx2}" if (idx2 >= l || idx2 < -l)
      self[idx1], self[idx2] = self[idx2], self[idx1]
      return self
    end
    
    #===配列の要素を画面に描画する
    #配列の先頭から順にrenderメソッドを呼び出す。
    #描画するインスタンスは、SpriteBaseモジュールがmixinされているクラスのみ
    #返却値:: 自分自身を帰す
    def render
      self.sprite_only.each{|e| e.render }
      return self
    end
    
    #===配列の要素を対象の画像に描画する
    #配列の先頭から順にrender_toメソッドを呼び出す。
    #_dst_:: 描画対象の画像インスタンス
    #返却値:: 自分自身を帰す
    def render_to(dst)
      self.each{|e| e.render_to(dst) }
      return self
    end
  end
  
  #==ディープコピーを実装するモジュール
  #dup、cloneとは違い、「ディープコピー(配列などの要素も複製するコピー)」を実装するためのモジュール。
  module DeepCopy
    #===複製を取得する
    #ただし、再定義しているクラス(例:Arrayクラス)以外はdupメソッドの結果
    #返却値:: 複写したインスタンスを返す
    def deep_dup
      (self && self.methods.include?(:dup)) ? self.dup : self
    end

    #===複製を取得する
    #ただし、再定義しているクラス(例:Arrayクラス)以外はdupメソッドの結果
    #返却値:: 複写したインスタンスを返す
    def deep_clone
      self.deep_dup
    end
  end
end

class Object
  include Miyako::DeepCopy
end

class Array
  include Miyako::SpriteArray

  #===複製を取得する
  #ただし、配列の要素もdeep_dupメソッドで複製する
  #返却値:: 複写したインスタンスを返す
  def deep_dup
    self.dup.map{|e| (e && e.methods.include?(:deep_dup)) ? e.deep_dup : e }
  end
end

class Hash
  #===複製を取得する
  #ただし、配列の要素もdeep_dupメソッドで複製する
  #返却値:: 複写したインスタンスを返す
  def deep_dup
    ret = self.dup
    ret.keys.each{|key|
      v = ret[key]
      (v && v.methods.include?(:deep_dup)) ? v.deep_dup : v
    }
    ret
  end
end
