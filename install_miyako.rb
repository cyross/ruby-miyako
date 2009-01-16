if RUBY_VERSION < '1.9.1'
  puts 'Sorry. Miyako needs Ruby 1.9.1 or above...'
  exit
end

begin
require 'sdl'
rescue
  puts 'Sorry. Miyako needs Ruby/SDL...'
  exit
end

if SDL::VERSION < '2.0'
  puts 'Sorry. Miyako needs Ruby/SDL 2.0.0 or above...'
  exit
end

require 'rbconfig'
require 'fileutils'
require 'optparse'

option = { :noop => false, :verbose => true }
not_force = true

ARGV.options do |opt|
  opt.on('--no-harm'){ option[:noop] = true }
  opt.on('--force'){ not_force = false }
  opt.on('--quiet'){ option[:verbose] = false }

  opt.parse!
end

ext_dir = "./"
osn = Config::CONFIG["target_os"].downcase
if osn =~ /mswin|mingw|cygwin|bccwin/
  ext_dir = "win/"
elsif osn =~ /darwin/ # Mac OS X
  unless ENV['SDL_CONFIG_PATH'] 
    puts 'Please set SDL_CONFIG_PATH environment variable...'
    puts "USAGE: SDL_CONFIG_PATH='/bin/sh /hoge/foo/sdl-config"
    exit
  end
  system("cd miyako_no_katana/ ; " + Config::CONFIG["ruby_install_name"] + " extconf.rb --with-sdl-config='#{ENV['SDL_CONFIG_PATH']}'; make ; cp miyako_no_katana.bundle ../")
else # linux, U*IX...
  unless ENV['SDL_CONFIG_PATH'] 
    puts 'Please set SDL_CONFIG_PATH environment variable...'
    puts "USAGE: SDL_CONFIG_PATH='/bin/sh /hoge/foo/sdl-config"
    exit
  end
  system("cd miyako_no_katana/ ; " + Config::CONFIG["ruby_install_name"] + " extconf.rb --with-sdl-config='#{ENV['SDL_CONFIG_PATH']}'; make ; cp miyako_no_katana.so ../")
end

sitelibdir = Config::CONFIG["sitelibdir"] + "/Miyako"
apidir = sitelibdir + "/API"
extdir = sitelibdir + "/EXT"

if FileTest.exist?(sitelibdir) && not_force
  puts "#{sitelibdir} is arleady exists."
  puts "Are you sure?(Y/else)"
  exit unless $stdin.gets.split(//)[0].upcase == 'Y'
end

FileUtils.remove_dir(sitelibdir, true)
FileUtils.mkpath(sitelibdir, option)
FileUtils.mkpath(apidir, option)
FileUtils.mkpath(extdir, option)

if osn =~ /darwin/ # Mac OS X
  Dir.glob(ext_dir + "*.bundle"){|fname| FileUtils.install(fname, sitelibdir, option)}
else # Windows, linux, U*IX...
  Dir.glob(ext_dir + "*.so"){|fname| FileUtils.install(fname, sitelibdir, option)}
end
Dir.glob("lib/Miyako/*.rb"){|fname| FileUtils.install(fname, sitelibdir, option)}
Dir.glob("lib/Miyako/API/*.rb"){|fname| FileUtils.install(fname, apidir, option)}
Dir.glob("lib/Miyako/EXT/*.rb"){|fname| FileUtils.install(fname, extdir, option)}
