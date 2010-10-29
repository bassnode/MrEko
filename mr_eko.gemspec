## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'mr_eko'
  s.version           = '0.1.0'
  s.date              = '2010-10-28'
  s.rubyforge_project = 'mr_eko'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Short description used in Gem listings."
  s.description = "Long description. Maybe copied from the README."

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Ed Hickey"]
  s.email    = 'bassnode@gmail.com'
  s.homepage = 'http://github.com/bassnode/mreko'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]


  ## If your gem includes any executables, list them here.
  # s.executables = ["name"]
  # s.default_executable = 'name'

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_dependency('sequel', "= 3.15")
  s.add_dependency('sqlite3-ruby', "~> 1.3")
  s.add_dependency('hashie')
  s.add_dependency('httpclient', "~> 2.1")
  s.add_dependency('json', "= 1.4.6")
  s.add_dependency('ruby-echonest')
  # gem "ruby-echonest", :git => "http://github.com/koyachi/ruby-echonest.git", :branch => 'version4'

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('mocha', "= 0.9.8")
  s.add_development_dependency('shoulda', "~> 2.11")
  s.add_development_dependency('test-unit', "~> 2.1")

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    Gemfile.lock
    README.md
    Rakefile
    bin/eko
    bin/mr_eko
    db/migrate/001_add_playlists.rb
    db/migrate/002_add_songs.rb
    eko.rb
    lib/mr_eko.rb
    lib/mr_eko/playlist.rb
    lib/mr_eko/presets.rb
    lib/mr_eko/song.rb
    lib/playlist.rb
    lib/presets.rb
    lib/song.rb
    mr_eko.gemspec
    test/eko_test.rb
    test/playlist_test.rb
    test/test.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/*_test\.rb/ }
end