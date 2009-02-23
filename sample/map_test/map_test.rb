# -*- encoding: utf-8 -*-
#! /usr/bin/ruby
# map_test

require 'singleton'

require 'Miyako/miyako'

include Miyako

Screen.fps = 60
#Screen.fps_view = true

require 'main_parts'
require 'chara'
require 'map_manager'
require 'route'
require 'oasis'
require 'town'
require 'main_scene'

#Screen.set_size(320, 240)
mt = Story.new
mt.run(MainScene)
