class MrEko::Song < Sequel::Model
  plugin :validation_helpers
  many_to_many :playlists
  MODES = %w(minor major)
  CHROMATIC_SCALE = %w(C C# D D# E F F# G G# A A# B).freeze

  # IDEA: This probably won't work since it's creating a new file,
  # but could try uploading a sample of the song (faster).
  # ffmpeg -y -i mogwai.mp3 -ar 22050 -ac 1 -ss 30 -t 30 output.mp3
  # or
  # sox mogwai.mp3 output.mp3 30 60

  # Using the Echonest Musical Fingerprint lib in the hopes
  # of sidestepping the mp3 upload process.
  def self.enmfp_data(filename, md5)
    unless File.exists?(fp_location(md5))
      puts 'Running ENMFP'
      `#{File.join(MrEko::HOME_DIR, 'ext', 'enmfp', enmfp_binary)} "#{File.expand_path(filename)}" > #{fp_location(md5)}`
    end

    File.read fp_location(md5)
  end

  # Return the file path of the EN fingerprint JSON file
  def self.fp_location(md5)
    target = File.join(MrEko::HOME_DIR, 'fingerprints')
    Dir.mkdir(target) unless File.exists?(target)
    File.expand_path File.join(target, "#{md5}.json")
  end

  # Use the platform-specific binary.
  def self.enmfp_binary
    case RUBY_PLATFORM
    when /darwin/
      'codegen.Darwin'
    when /686/
      'codegen.Linux-i686'
    when /x86/
      'codegen.Linux-x86_64'
    else
      'codegen.windows.exe'
    end
  end

  # Returns the analysis and profile data from Echonest for the given track.
  def self.get_datapoints_by_filename(filename)
    analysis = MrEko.nest.track.analysis(filename)
    profile  = MrEko.nest.track.profile(:md5 => MrEko.md5(filename)).body.track

    return [analysis, profile]
  end

  # TODO: Cleanup - This method is prety ugly now.
  def self.create_from_file!(filename)
    md5 = MrEko.md5(filename)
    existing = where(:md5 => md5).first
    return existing unless existing.nil?

    fingerprint_data = enmfp_data(filename, md5)
    fingerprint_json_data = Hashie::Mash.new(JSON.parse(fingerprint_data).first)

    if fingerprint_json_data.keys.include?('error')
      analysis, profile = get_datapoints_by_filename(filename)
    else
      puts "Identifying with ENMFP code"
      identify_options = {:code => fingerprint_data}
      identify_options[:artist]   = fingerprint_json_data.metadata.artist  if fingerprint_json_data.metadata.artist
      identify_options[:title]    = fingerprint_json_data.metadata.title   if fingerprint_json_data.metadata.title
      identify_options[:release]  = fingerprint_json_data.metadata.release if fingerprint_json_data.metadata.release
      profile = MrEko.nest.song.identify(identify_options)

      if profile.songs.empty? 
        # ENMFP wasn't recognized, so upload.
        analysis, profile = get_datapoints_by_filename(filename)
      else
        begin
          profile = profile.songs.first
          analysis = MrEko.nest.song.profile(:id => profile.id, :bucket => 'audio_summary').songs.first.audio_summary
        rescue Exception => e
          puts "Issues using ENMP data, uploading \"(#{e})\""
          analysis, profile = get_datapoints_by_filename(filename)
        end
      end
    end

    # TODO: add ruby-mp3info as fallback for parsing ID3 tags
    # since Echonest seems a bit flaky in that dept.
    song                = new()
    song.filename       = File.expand_path(filename)
    song.md5            = md5
    song.code           = fingerprint_json_data.code
    song.tempo          = analysis.tempo
    song.duration       = analysis.duration
    song.fade_in        = analysis.end_of_fade_in
    song.fade_out       = analysis.start_of_fade_out
    song.key            = analysis.key
    song.mode           = analysis.mode
    song.loudness       = analysis.loudness
    song.time_signature = analysis.time_signature
    song.echonest_id    = profile.id
    song.bitrate        = profile.bitrate
    song.title          = profile.title
    song.artist         = profile.artist || profile.artist_name
    song.album          = profile.release
    song.danceability   = profile.audio_summary? ? profile.audio_summary.danceability : analysis.danceability
    song.energy         = profile.audio_summary? ? profile.audio_summary.energy       : analysis.energy

    song.save
  end

  # Takes 'minor' or 'major' and returns its integer representation.
  def self.mode_lookup(mode)
    MODES.index(mode)
  end

  # Takes a chromatic key (eg: G#) and returns its integer representation.
  def self.key_lookup(key_letter)
    CHROMATIC_SCALE.index(key_letter)
  end

  # Takes an integer and returns its standard (chromatic) representation.
  def key_letter
    CHROMATIC_SCALE[key]
  end

  def validate
    super
    set_md5 # no Sequel callback for this?
    validates_unique :md5
  end

  private
  def set_md5
    self.md5 ||= MrEko.md5(filename)
  end

end

MrEko::Song.plugin :timestamps
