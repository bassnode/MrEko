class Eko::Playlist < Sequel::Model
  class NoSongsError < Exception; end
  
  plugin :validation_helpers
  many_to_many :songs
  FORMATS = [:pls, :m3u, :text]
  
  def self.create_from_options(options)
    # TODO: Is a name (or persisting) even necessary?
    pl = create(:name => options.delete(:name) || "Playlist #{rand(10000)}")
    prepare_options!(options)

    songs = Eko::Song.where(options).all
    if songs.size > 0
      songs.each{ |song| pl.add_song(song) }
      pl.save
    else
      pl.delete # TODO: Look into not creating Playlist in the 1st place
      raise NoSongsError.new("No songs match that criteria!")
    end
  end
  
  def self.prepare_options!(options)
    min_tempo = options.delete(:min_tempo) || 0
    max_tempo = options.delete(:max_tempo) || 500
    options[:tempo] = min_tempo..max_tempo
    
    if options.has_key?(:mode)
      options[:mode] = Eko::Song.mode_lookup(options[:mode])
    end
        
    if options.has_key?(:key)
      options[:key] = Eko::Song.key_lookup(options[:key])
    end
    
  end
  
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
  
  def create_text
    songs.inject("") do |list, song|
      list << "#{song.filename}, #{song.title}\n"
    end
  end
  
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

Eko::Playlist.plugin :timestamps