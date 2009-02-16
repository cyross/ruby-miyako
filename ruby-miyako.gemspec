Gem::Specification.new do |s|
  s.name = "ruby-miyako"
  s.version = "2.0.0"
  s.date = "2009-2-20"
  s.summary = "Game programming library for Ruby"
  s.email = "cyross@po.twin.ne.jp"
  s.homepage = "http://www.twin.ne.jp/~cyross/Miyako/"
  s.description = "Miyako is Ruby library for programming game or rich client"
  s.has_rdoc = true
  s.rdoc_options = "-c utf-8"
  s.authors = ["Cyross Makoto"]
  s.files = ["img/cursor.png", "img/cursors.png", "img/dice.png", "img/wait_cursor.png",
"img/window.png", "img/win_base.png", "lib/Miyako", "lib/Miyako/API", "lib/Miyako/API/audio.rb",
"lib/Miyako/API/basic_data.rb", "lib/Miyako/API/bitmap.rb", "lib/Miyako/API/choices.rb",
"lib/Miyako/API/collision.rb", "lib/Miyako/API/diagram.rb", "lib/Miyako/API/drawing.rb",
"lib/Miyako/API/fixedmap.rb", "lib/Miyako/API/font.rb", "lib/Miyako/API/input.rb",
"lib/Miyako/API/layout.rb", "lib/Miyako/API/map.rb", "lib/Miyako/API/map_event.rb", "lib/Miyako/API/modules.rb",
"lib/Miyako/API/movie.rb", "lib/Miyako/API/parts.rb", "lib/Miyako/API/plane.rb", "lib/Miyako/API/screen.rb",
"lib/Miyako/API/shape.rb", "lib/Miyako/API/sprite.rb", "lib/Miyako/API/spriteunit.rb", "lib/Miyako/API/sprite_animation.rb",
"lib/Miyako/API/story.rb", "lib/Miyako/API/textbox.rb", "lib/Miyako/API/viewport.rb", "lib/Miyako/API/yuki.rb",
"lib/Miyako/EXT", "lib/Miyako/EXT/miyako_cairo.rb", "lib/Miyako/EXT/raster_scroll.rb", "lib/Miyako/EXT/slides.rb",
"lib/Miyako/miyako.rb", "miyako_no_katana/extconf.rb","miyako_no_katana/miyako_no_katana.c",
"sample/Animation1", "sample/Animation1/m1ku.rb", "sample/Animation1/m1ku_arm_0.png",
"sample/Animation1/m1ku_arm_1.png", "sample/Animation1/m1ku_arm_2.png", "sample/Animation1/m1ku_arm_3.png",
"sample/Animation1/m1ku_back.jpg", "sample/Animation1/m1ku_body.png", "sample/Animation1/m1ku_eye_0.png",
"sample/Animation1/m1ku_eye_1.png", "sample/Animation1/m1ku_eye_2.png", "sample/Animation1/m1ku_eye_3.png",
"sample/Animation1/m1ku_hair_front.png", "sample/Animation1/m1ku_hair_rear.png", "sample/Animation1/readme.txt",
"sample/Animation2", "sample/Animation2/lex.rb", "sample/Animation2/lex_back.png", "sample/Animation2/lex_body.png",
"sample/Animation2/lex_roadroller.png", "sample/Animation2/lex_wheel_0.png", "sample/Animation2/lex_wheel_1.png",
"sample/Animation2/lex_wheel_2.png", "sample/Animation2/readme.txt", "sample/Animation2/song_title.png",
"sample/Diagram_sample", "sample/Diagram_sample/back.png", "sample/Diagram_sample/chr01.png", "sample/Diagram_sample/chr02.png",
"sample/Diagram_sample/cursor.png", "sample/Diagram_sample/diagram_sample_yuki2.rb", "sample/Diagram_sample/readme.txt",
"sample/Diagram_sample/wait_cursor.png", "sample/fixed_map_test", "sample/fixed_map_test/cursor.png", "sample/fixed_map_test/fixed_map_sample.rb",
"sample/fixed_map_test/map.csv", "sample/fixed_map_test/mapchip.csv", "sample/fixed_map_test/map_01.png", "sample/fixed_map_test/map_sample.rb",
"sample/fixed_map_test/monster.png", "sample/fixed_map_test/readme.txt", "sample/map_test", "sample/map_test/chara.rb", "sample/map_test/chr1.png",
"sample/map_test/cursor.png", "sample/map_test/main_parts.rb", "sample/map_test/main_scene.rb", "sample/map_test/map.png", "sample/map_test/map2.png",
"sample/map_test/mapchip.csv", "sample/map_test/map_layer.csv", "sample/map_test/map_manager.rb", "sample/map_test/map_test.rb",
"sample/map_test/oasis.rb", "sample/map_test/readme.txt", "sample/map_test/route.rb", "sample/map_test/sea.png", "sample/map_test/town.rb",
"sample/map_test/wait_cursor.png", "sample/map_test/window.png", "sample/Room3", "sample/Room3/blue.rb", "sample/Room3/ending.rb",
"sample/Room3/green.rb", "sample/Room3/image", "sample/Room3/image/akamatsu.png", "sample/Room3/image/aoyama.png", "sample/Room3/image/congra.png",
"sample/Room3/image/congratulation.png", "sample/Room3/image/congratulation_bg.png", "sample/Room3/image/cursor.png", "sample/Room3/image/midori.png",
"sample/Room3/image/mittsu_no_oheya.png", "sample/Room3/image/mittsu_no_oheya_logo.png", "sample/Room3/image/room_blue.png",
"sample/Room3/image/room_green.png", "sample/Room3/image/room_red.png", "sample/Room3/image/start.png", "sample/Room3/image/three_doors.png",
"sample/Room3/image/wait_cursor.png", "sample/Room3/main.rb", "sample/Room3/main_component.rb", "sample/Room3/readme.txt", "sample/Room3/red.rb",
"sample/Room3/room3.rb", "sample/Room3/title.rb", "win/miyako_no_katana.so", "install_miyako.rb", "README", "miyako.png", "miyako_banner.png", "Rakefile"]
  s.require_paths = ["lib"]
  s.post_install_message="\n[[IMPORTANT]]\nplease enter 'ruby install_miyako.rb' at installed path to complete installation of ruby-miyako.\n\n[Example]\n>cd (ruby-path)/lib/ruby/gems/1.8/gems/cyross-ruby-miyako-2.0.0\nruby install_miyako.rb\n\n"
end