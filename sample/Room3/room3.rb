# -*- encoding: utf-8 -*-
#! /usr/bin/ruby
# Sample Adventure "Room 3"

$miyako_debug_mode = true

require 'Miyako/miyako'
#require 'Miyako/idaten_miyako'

include Miyako

Miyako.setTitle("Room 3")
Screen.set_size(640, 480)

#Screen.fps = 40
#Screen.fpsView = true

require 'main_component'
require 'title'
require 'main'
require 'red'
require 'green'
require 'blue'
require 'ending'

r3 = Story.new
r3.run(MainScene)
