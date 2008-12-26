# -*- encoding: utf-8 -*-
# Miyako Extension Cairo-Miyako interface
=begin
Miyako Extention Library v2.0
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
=end

begin
  loaded = false
  require 'cairo'
rescue LoadError
  begin
    require 'rubygems'
    require 'cairo'
    loaded = true
  rescue LoadError
    raise Miyako::MiyakoError, "Sorry, Cairo-Miyako Interface has rcairo." unless loaded
  end
end

module Miyako
  #==MiyakoのSpriteクラスのインスタンスとCairoのImageSurfaceクラスのインスタンスとの相互変換モジュール
  #要rcairo1.8以降
  module MiyakoCairo
    #===SpriteインスタンスをCairoのImageSurfaceに変換
    #変換したCairo::ImageSurfaceインスタンスは、32ビット(Cairo::Format::ARGB32)の画像を持つ
    #_sprite_:: 変換元Spriteインスタンス
    #返却値:: 変換したCairo::ImageSurfaceインスタンス
    def MiyakoCairo.to_cairo_surface(sprite)
      return Cairo::ImageSurface.new(sprite.bitmap.pixels, Cairo::Format::ARGB32, sprite.w, sprite.h, sprite.w * 4)
    end
    
    #===CairoのImageSurfaceをSpriteインスタンスに変換
    #変換したSpriteインスタンスは、:acタイプ(但し元画像がCairo::Format::RGB24の時は:asタイプ)の画像を持つ
    #_surface_:: 変換元Cairo::ImageSurfaceインスタンス
    #返却値:: 変換したSpriteインスタンス
    def MiyakoCairo.to_sprite(surface)
      # エンディアン判別
      if [1].pack("V*") == [1].pack("L*") # リトルエンディアン？
        bitmap = SDL::Surface.new_from(surface.data, surface.width, surface.height, 32, surface.stride, 0xff0000, 0xff00, 0xff, 0xff000000)
      else # ビッグエンディアン
        bitmap = SDL::Surface.new_from(surface.data, surface.width, surface.height, 32, surface.stride, 0xff00, 0xff0000, 0xff000000, 0xff)
      end
      return Sprite.new(:bitmap => bitmap, :type => :as) if surface.format == Cairo::Format::RGB24
      return Sprite.new(:bitmap => bitmap, :type => :ac)
    end
  end
end
