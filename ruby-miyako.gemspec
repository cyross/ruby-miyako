Gem::Specification.new do |s|
  s.name = "ruby-miyako"
  s.version = "2.0.4"
  s.date = "2009-4-25"
  s.summary = "Game programming library for Ruby"
  s.email = "cyross@po.twin.ne.jp"
  s.homepage = "http://www.twin.ne.jp/~cyross/Miyako/"
  s.description = "Miyako is Ruby library for programming game or rich client"
  s.required_ruby_version = '>= 1.9.1'
  s.has_rdoc = true
  s.rdoc_options = "-c utf-8"
  s.authors = ["Cyross Makoto"]
  s.test_files = []
  s.extensions = ["extconf.rb"]
  s.files = File.readlines("MANIFEST").map{|line| line.chomp}
  s.require_paths = ["lib"]
end