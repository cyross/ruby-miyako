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
=begin rdoc
==基本スプライトモジュール
スプライトの基本メソッドで構成されるテンプレートモジュール
=end
  module SpriteBase
  #===あとで書く
  #返却値:: あとで書く
    def show
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def hide
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def dp
      return nil
    end

  #===あとで書く
  #_v_:: あとで書く
  #返却値:: あとで書く
    def dp=(v)
    end

  #===あとで書く
  #_data_:: あとで書く
  #返却値:: あとで書く
    def to_sprite(data = nil)
      return nil
    end

  #===あとで書く
  #返却値:: あとで書く
    def to_unit
      return nil
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def bitmap
      return nil
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def ox
      return nil
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def oy
      return nil
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def ow
      return nil
    end
    
  #===あとで書く
  #返却値:: あとで書く
    def oh
      return nil
    end
  end

=begin rdoc
==基本アニメーションモジュール
アニメーションの基本メソッドで構成されるテンプレートモジュール
=end
  module Animation
  #===あとで書く
  #返却値:: あとで書く
    def start
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def stop
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def reset
      return self
    end

  #===あとで書く
  #返却値:: あとで書く
    def update_animation
      return nil
    end
  end
  
=begin rdoc
==タッピングモジュール
タッピングを実装するテンプレートモジュール
=end
  module MiyakoTap
    #タッピングを使用したブロックを使ったプロパティ設定(自分自身を引数としたブロック)を行う
    #返却値:: 自分自身を返す
    def property
      if block_given?
        yield self
      end
      return self
    end
  end
end
