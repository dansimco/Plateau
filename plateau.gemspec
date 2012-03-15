Gem::Specification.new do |s|
  s.name = "plateau"
  s.version = "0.0.3"
  s.authors = ["Daniel Sim","Exploding Box Productions"]
  s.date = %q{2012-02-13}
  s.description = 'Flat file publishing engine'
  s.summary = %Q{A publishing & blogging engine powered by markdown and mustache}
  s.email = 'dan@explodingbox.com'
  s.homepage = 'https://github.com/explodingbox/Plateau'
  s.has_rdoc = false
  s.executables << "plateau"
  s.add_dependency('mustache', '>= 0.99.4')
  s.add_dependency('maruku', '>= 0.6.0')
  s.files = [
    'README.md',
    'lib/Plateau.rb',
    'resources/Plateau.tar.gz'
  ]
end