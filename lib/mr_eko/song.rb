class MrEko::Song < Sequel::Model
  include MrEko::Core
  plugin :validation_helpers
  many_to_many :playlists

  def self.create_from_file!(filename, analysis_type = :enmfp)
    md5 = MrEko.md5(filename)
    existing = where(:md5 => md5).first
    return existing unless existing.nil?

    case analysis_type
    when :enmfp
      catalog_via_enmfp(filename)
    when :tags
      catalog_via_tags(filename)
    end

  end

  def self.catalog_via_enmfp(filename)
    md5 = MrEko.md5(filename)
    fingerprint_data = enmfp_data(filename, md5)
    fingerprint_json_data = Hashie::Mash.new(JSON.parse(fingerprint_data).first)

    if fingerprint_json_data.keys.include?('error')
      log "ERROR!"
      return
    else
      begin
        log "Identifying with ENMFP code"

        identify_options = {:code => fingerprint_data}
        identify_options[:artist]   = fingerprint_json_data.metadata.artist  if fingerprint_json_data.metadata.artist
        identify_options[:title]    = fingerprint_json_data.metadata.title   if fingerprint_json_data.metadata.title
        identify_options[:release]  = fingerprint_json_data.metadata.release if fingerprint_json_data.metadata.release

        profile = MrEko.nest.song.identify(identify_options)

        raise "ENMP returned nothing" if profile.songs.empty?

        profile = profile.songs.first
        analysis = MrEko.nest.song.profile(:id => profile.id, :bucket => 'audio_summary').songs.first.audio_summary
      rescue Exception => e
        log "Issues using ENMP data \"(#{e})\""
        analysis, profile = get_datapoints_by_filename(filename)
      end
    end

    create do |song|
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
    end
  end


  # IDEA: This probably won't work since it's creating a new file,
  # but could try uploading a sample of the song (faster).
  # ffmpeg -y -i mogwai.mp3 -ar 22050 -ac 1 -ss 30 -t 30 output.mp3
  # or
  # sox mogwai.mp3 output.mp3 30 60

  # Using the Echonest Musical Fingerprint lib in the hopes
  # of sidestepping the mp3 upload process.
  def self.enmfp_data(filename, md5)
    unless File.exists?(fp_location(md5))
      log 'Running ENMFP'
      `#{File.join(MrEko::HOME_DIR, 'ext', 'enmfp', MrEko.enmfp_binary)} "#{File.expand_path(filename)}" > #{fp_location(md5)}`
    end

    File.read fp_location(md5)
  end

  # Returns the analysis and profile data from Echonest for the given track.
  def self.get_datapoints_by_filename(filename)
    log "Uploading data to EN for analysis"
    analysis = MrEko.nest.track.analysis(filename)
    profile  = MrEko.nest.track.profile(:md5 => MrEko.md5(filename)).body.track

    return [analysis, profile]
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

  # Return the file path of the EN fingerprint JSON file
  def self.fp_location(md5)
    File.expand_path File.join(MrEko::FINGERPRINTS_DIR, "#{md5}.json")
  end

end

MrEko::Song.plugin :timestamps
