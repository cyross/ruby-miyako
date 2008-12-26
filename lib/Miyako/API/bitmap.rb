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

# ビットマップ関連クラス群
module Miyako
  #==ビットマップ(画像)管理クラス
  #SDLのSurfaceクラスインスタンスを管理するクラス
  class Bitmap
    def Bitmap.create(w, h, flag=SDL::HWSURFACE | SDL::SRCCOLORKEY | SDL::SRCALPHA) #:nodoc:
      return SDL::Surface.new(flag, w, h, 32, Screen.screen.Rmask, Screen.screen.Gmask, Screen.screen.Bmask, Screen.screen.Amask)
    end
    def Bitmap.load(filename) #:nodoc:
      return SDL::Surface.load(filename)
    end
  end
end
