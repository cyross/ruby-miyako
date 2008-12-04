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
==エフェクトクラス
=end
  class Effect
    #===あとで書く
    #_sspr_:: あとで書く
    #_dspr_:: あとで書く
    #返却値:: あとで書く
    def initialize(sspr, dspr = nil)
      @src = sspr
      @dst = dspr
      @effecting = false
      @wait = 0
      @cnt = 0
      @params = Array.new
    end
    
    #===あとで書く
    #_w_:: あとで書く
    #_param_:: あとで書く
    #返却値:: あとで書く
    def start(w, *param)
      return if @effecting
      @wait = w
      @cnt = @wait
      @param = param
      @effecting = true
    end
    
    #===あとで書く
    #返却値:: あとで書く
    def effecting?
      return @effecting
    end
    
    #===あとで書く
    #_params_:: あとで書く
    #返却値:: あとで書く
    def update(*params)
      return if @effecting == false # dummy code
    end

    #===画面に描画を指示する
    #現在の画像を、現在の状態で描画するよう指示する
    #但し、実際に描画されるのはScreen.renderメソッドが呼び出された時
    #返却値:: 自分自身を返す
    def render
      effect if @effecting
      return self
    end

    #===あとで書く
    #_params_:: あとで書く
    #返却値:: あとで書く
    def effect(*params)
      @effecting = false # dummy code
    end

    #===あとで書く
    #返却値:: あとで書く
    def stop
      @effecting = false
    end
    
    #===あとで書く
    #返却値:: あとで書く
    def dispose
      @dst = nil
    end
  end
end
