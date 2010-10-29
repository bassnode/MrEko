class MrEko::Playlist < Sequel::Model
  class NoSongsError < Exception; end
  
  include MrEko::Presets
  
  plugin :validation_helpers
  many_to_many :songs
  FORMATS = [:pls, :m3u, :text]
  
  # Creates and returns a new Playlist from the passed <tt>options</tt>.
  # <tt>options</tt> should be finder options you pass to Song plus (optionally) :name.
  def self.create_from_options(options)
    # TODO: Is a name (or persisting) even necessary?
    pl = create(:name => options.delete(:name) || "Playlist #{rand(10000)}")
    prepare_options!(options)

    songs = MrEko::Song.where(options).all
    if songs.size > 0
      songs.each{ |song| pl.add_song(song) }
      pl.save
    else
      pl.delete # TODO: Look into not creating Playlist in the 1st place
      raise NoSongsError.new("No songs match that criteria!")
    end
  end
  
  # Organize and transform!
  def self.prepare_options!(options)
    if preset = options.delete(:preset)
      options.replace load_preset(preset)
    else
      unless options[:tempo].is_a? Range
        min_tempo = options.delete(:min_tempo) || 0
        max_tempo = options.delete(:max_tempo) || 500
        options[:tempo] = min_tempo..max_tempo
      end    
    
      unless options[:duration].is_a? Range
        min_duration = options.delete(:min_duration) || 10 # worthless jams
        max_duration = options.delete(:max_duration) || 1200 # 20 min.
        options[:duration] = min_duration..max_duration
      end
    
      if options.has_key?(:mode)
        options[:mode] = MrEko::Song.mode_lookup(options[:mode])
      end
        
      if options.has_key?(:key)
        options[:key] = MrEko::Song.key_lookup(options[:key])
      end
    end
  end
  
  # Return the formatted playlist.  
  def output(format = :pls)
    format = format.to_sym
    raise ArgumentError.new("Format must be one of #{FORMATS.join(', ')}") unless FORMATS.include? format
    
    case format
    when :pls
      create_pls
    when :m3u
      create_m3u
    else
     create_text
    end
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

MrEko::Playlist.plugin :timestamps