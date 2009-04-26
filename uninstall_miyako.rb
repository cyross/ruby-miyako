# Miyako2.0 uninstall script
# 2009 Cyross Makoto

if RUBY_VERSION < '1.9.1'
  puts 'Sorry. Miyako needs Ruby 1.9.1 or above...'
  exit
end

require 'rbconfig'
require 'fileutils'

puts "Are you sure?(Y/else)"
exit unless $stdin.gets.split(//)[0].upcase == 'Y'

sitelibdir = Config::CONFIG["sitelibdir"] + "/Miyako"

FileUtils.remove_dir(sitelibdir, true)

puts "uninstall completed."
