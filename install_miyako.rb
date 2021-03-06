# Miyako2.0 install script
# 2009 Cyross Makoto

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

if SDL::VERSION < '2.1'
  puts 'Sorry. Miyako needs Ruby/SDL 2.1.0 or above...'
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
  if ENV['SDL_CONFIG_PATH']
    system(Config::CONFIG["ruby_install_name"] + " extconf.rb --with-sdl-config='#{ENV['SDL_CONFIG_PATH']}'; make")
  else
    system(Config::CONFIG["ruby_install_name"] + " extconf.rb --with-sdl-config='sdl-config'; make")
  end
else # linux, U*IX...
  if ENV['SDL_CONFIG_PATH']
    system(Config::CONFIG["ruby_install_name"] + " extconf.rb --with-sdl-config='#{ENV['SDL_CONFIG_PATH']}'; make")
  else
    system(Config::CONFIG["ruby_install_name"] + " extconf.rb --with-sdl-config='sdl-config'; make")
  end
end

baselibdir = Config::CONFIG["sitelibdir"]
sitelibdir = baselibdir + "/Miyako"
apidir = sitelibdir + "/API"
extdir = sitelibdir + "/EXT"
fontdir = sitelibdir + "/fonts"
fontdocdir1 = fontdir + "/docs-ume"
fontdocdir2 = fontdir + "/docs-mplus"

if FileTest.exist?(sitelibdir) && not_force
  puts "#{sitelibdir} is arleady exists."
  puts "Are you sure?(Y/else)"
  exit unless $stdin.gets.split(//)[0].upcase == 'Y'
end

FileUtils.remove_dir(sitelibdir, true)
FileUtils.mkpath(sitelibdir, option)
FileUtils.mkpath(apidir, option)
FileUtils.mkpath(extdir, option)
FileUtils.mkpath(fontdir, option)
FileUtils.mkpath(fontdocdir1, option)
FileUtils.mkpath(fontdocdir2, option)

if osn =~ /darwin/ # Mac OS X
  Dir.glob(ext_dir + "*.bundle"){|fname| FileUtils.install(fname, sitelibdir, option)}
else # Windows, linux, U*IX...
  Dir.glob(ext_dir + "*.so"){|fname| FileUtils.install(fname, sitelibdir, option)}
end
Dir.glob("lib/*.rb"){|fname| FileUtils.install(fname, baselibdir, option)}
Dir.glob("lib/Miyako/*.rb"){|fname| FileUtils.install(fname, sitelibdir, option)}
Dir.glob("lib/Miyako/API/*.rb"){|fname| FileUtils.install(fname, apidir, option)}
Dir.glob("lib/Miyako/EXT/*.rb"){|fname| FileUtils.install(fname, extdir, option)}
Dir.glob("lib/Miyako/fonts/*.ttf"){|fname| FileUtils.install(fname, fontdir, option)}
Dir.glob("lib/Miyako/fonts/README"){|fname| FileUtils.install(fname, fontdir, option)}
Dir.glob("lib/Miyako/fonts/ChangeLog"){|fname| FileUtils.install(fname, fontdir, option)}
Dir.glob("lib/Miyako/fonts/docs-ume/*"){|fname| FileUtils.install(fname, fontdocdir1, option)}
Dir.glob("lib/Miyako/fonts/docs-mplus/*"){|fname| FileUtils.install(fname, fontdocdir2, option)}

unless osn =~ /mswin|mingw|cygwin|bccwin/
  FileUtils.chmod(0755, sitelibdir)
  FileUtils.chmod(0755, apidir)
  FileUtils.chmod(0755, extdir)
  FileUtils.chmod(0755, fontdir)
  FileUtils.chmod(0644, sitelibdir+'/miyako.rb')
  Dir.glob(sitelibdir+"/*.so"){|fname| FileUtils.chmod(0644, fname)} # for linux,bsd
  Dir.glob(sitelibdir+"/*.bundle"){|fname| FileUtils.chmod(0644, fname)} # for macosx
  Dir.glob(apidir+"/*.rb"){|fname| FileUtils.chmod(0644, fname)}
  Dir.glob(extdir+"/*.rb"){|fname| FileUtils.chmod(0644, fname)}
  Dir.glob(fontdir+"/*.ttf"){|fname| FileUtils.chmod(0644, fname)}
  FileUtils.chmod(0644, fontdir+"/README")
  FileUtils.chmod(0644, fontdir+"/ChangeLog")
  Dir.glob(fontdir+"/*.ttf"){|fname| FileUtils.chmod(0644, fname)}
  Dir.glob(fontdocdir1+"/*"){|fname| FileUtils.chmod(0644, fname)}
  Dir.glob(fontdocdir2+"/*"){|fname| FileUtils.chmod(0644, fname)}
end
