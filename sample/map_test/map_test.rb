#! /usr/bin/ruby
# map_test

require 'singleton'

require 'Miyako/miyako'
require 'Miyako/idaten_miyako'

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

#イベントを登録
MapEvent.add(3, EventRouteMarker)
MapEvent.add(7, EventRouteMarker2)
MapEvent.add(8, EventTown)
MapEvent.add(16, EventOasis)

#Screen.set_size(320, 240)
mt = Story.new
mt.run(MainScene)
