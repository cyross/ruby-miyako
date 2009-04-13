# encoding: utf-8
# MiyakoCairoサンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'
require 'Miyako/EXT/miyako_cairo'

sprite = Miyako::Sprite.new(:file=>"Animation2/lex_body.png", :type=>:ck)
sprite.bitmap.saveBMP("./sample.bmp")

surface = Miyako::MiyakoCairo.to_cairo_surface(sprite)
surface.write_to_png("./sample.png")

surface = Cairo::ImageSurface.new(Cairo::Format::ARGB32, 320, 240)
context = Cairo::Context.new(surface)

context.set_source_rgb(1.0, 0.5, 0.8)
context.fill{
  context.rectangle(50, 50, 150, 100)
}

surface.write_to_png("./sample2.png")

sprite = Miyako::MiyakoCairo.to_sprite(surface)
sprite.bitmap.saveBMP("./sample2.bmp")
