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
end
