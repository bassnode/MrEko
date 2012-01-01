class MrEko::Playlist < Sequel::Model

  include MrEko::Core
  include MrEko::Presets

  plugin :validation_helpers
  many_to_many :songs, :join_table => :playlist_entries, :order => :playlist_entries__position.asc
  FORMATS = [:pls, :m3u, :text].freeze
  DEFAULT_OPTIONS = [ {:tempo => 0..500}, {:duration => 10..1200} ].freeze


  # Creates and returns a new Playlist from the passed <tt>options</tt>.
  # <tt>options</tt> should be finder options you pass to Song plus (optionally) :name.
  def self.create_from_options(options)
    # TODO: Is a name (or persisting) even necessary?
    MrEko.connection.transaction do
      pl = create(:name => options.delete(:name) || "Playlist #{rand(10000)}")

      filter = apply_filters prepare_options(options)
      songs = filter.all

      if songs.size > 0
        songs.each{ |song| pl.add_song(song) }
        pl.save
      else
        raise MrEko::NoSongsError.new("No songs match those criteria!")
      end
    end
  end

  # Organize and transform!
  def self.prepare_options(options)

    if preset = options.delete(:preset)
      new_options = load_preset(preset)
    else

      new_options = DEFAULT_OPTIONS.reject{ |d| options.keys.include?(d.keys.first) }

      options.each do |key, value|

        case key

        when :danceability, :energy
          new_options << transform(key, value, true)

        when :mode
          new_options << transform(key, MrEko.mode_lookup(value))

        when :key
          new_options << transform(key, MrEko.key_lookup(value))

        else
          new_options << transform(key, value)
        end
      end
    end

    new_options
  end

  # Return the formatted playlist.
  def output(format = :pls)
    format = format.to_sym
    raise ArgumentError.new("Format must be one of #{FORMATS.join(', ')}") unless FORMATS.include? format

    case format
    when :text
      create_text
    when :m3u
      create_m3u
    else
     create_pls
    end
  end

  private

  def self.transform(key, value, percentage=false)
    if match = value.to_s.match(/(^[<>])(\d+)/)
      operator = match[1]
      value = match[2]

      value = value.to_f / 100.0 if percentage

      "#{key} #{operator} #{value}".lit
    else
      value = value.to_f / 100.0 if percentage
      {key => value}
    end
  end


  # Recursively add Sequel where clauses
  def self.apply_filters(options, filtered=nil)
    filtered = (filtered || MrEko::Song).where(options.pop)
    filtered = apply_filters(options, filtered) unless options.empty?
    filtered
  end

  # Returns a text representation of the Playlist.
  def create_text
    songs.inject("") do |list, song|
      list << "#{song.filename}, #{song.title}\n"
    end
  end

  # Returns a PLS representation of the Playlist.
  def create_pls
    pls = "[playlist]\n"
    pls << "NumberOfEntries=#{songs.size}\n\n"

    i = 0
    while i < songs.size do
      num = i+1
      pls << "File#{num}=#{songs[i].filename}\n"
      pls << "Title#{num}=#{songs[i].title || songs[i].filename}\n"
      pls << "Length#{num}=#{songs[i].duration.round}\n\n"
      i+=1
    end

    pls << "Version=2"
  end

  def create_m3u
    "TBD"
  end
end
