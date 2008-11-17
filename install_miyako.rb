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
  system("cd idaten_miyako/ ; " + Config::CONFIG["ruby_install_name"] + " extconf.rb ; make ; cp idaten_miyako.bundle ../")
  system("cd miyako_no_katana/ ; " + Config::CONFIG["ruby_install_name"] + " extconf.rb ; make ; cp miyako_no_katana.bundle ../")
else # linux, U*IX...
  system("cd idaten_miyako/ ; " + Config::CONFIG["ruby_install_name"] + " extconf.rb ; make ; cp idaten_miyako.so ../")
  system("cd miyako_no_katana/ ; " + Config::CONFIG["ruby_install_name"] + " extconf.rb ; make ; cp miyako_no_katana.so ../")
end

sitelibdir = Config::CONFIG["sitelibdir"] + "/Miyako"
apidir = sitelibdir + "/API"
extdir = sitelibdir + "/EXT"

if FileTest.exist?(sitelibdir) && not_force
  puts "#{sitelibdir} is arleady exists."
  puts "Are you sure?(Y/else)"
  exit unless $stdin.gets.split(//)[0].upcase == 'Y'
end

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
