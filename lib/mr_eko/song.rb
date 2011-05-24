class MrEko::Song < Sequel::Model
  include MrEko::Core
  plugin :validation_helpers
  many_to_many :playlists

  class EnmfpError < Exception; end

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
    fingerprint_json = enmfp_data(filename, md5)

    if fingerprint_json.keys.include?('error')
      raise EnmfpError, "Errors returned in the ENMFP fingerprint data: #{fingerprint_json.error.inspect}"
    else
      begin
        log "Identifying with ENMFP code"

        identify_options = {}.tap do |opts|
          opts[:code]    = fingerprint_json.raw_data
          opts[:artist]  = fingerprint_json.metadata.artist
          opts[:title]   = fingerprint_json.metadata.title
          opts[:release] = fingerprint_json.metadata.release
          opts[:bucket]  = 'audio_summary'
        end

        profile = MrEko.nest.song.identify(identify_options)

        raise EnmfpError, "Nothing returned" if profile.songs.empty?
        profile = profile.songs.first

        # Get the extended audio data from the profile
        analysis = MrEko.nest.song.profile(:id => profile.id, :bucket => 'audio_summary').songs.first.audio_summary
      rescue Exception => e
        log %Q{Issues using ENMFP data "(#{e})" #{e.backtrace.join("\n")}}
        analysis, profile = get_datapoints_by_upload(filename)
      end
    end

    create do |song|
      song.filename       = File.expand_path(filename)
      song.md5            = md5
      song.code           = fingerprint_json.code
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

  def self.catalog_via_tags(filename)
    puts 'Coming soon'
  end

  # Using the Echonest Musical Fingerprint lib in the hopes
  # of sidestepping the mp3 upload process.
  def self.enmfp_data(filename, md5)
    unless File.exists?(fp_location(md5))
      log 'Running ENMFP'
      `#{File.join(MrEko::HOME_DIR, 'ext', 'enmfp', MrEko.enmfp_binary)} "#{File.expand_path(filename)}" > #{fp_location(md5)}`
    end

    raw_json = File.read fp_location(md5)
    hash = Hashie::Mash.new(JSON.parse(raw_json).first)
    hash.raw_data = raw_json
    hash
  end

  # Returns the analysis and profile data from Echonest for the given track.
  def self.get_datapoints_by_upload(filename)
    log "Uploading data to EN for analysis"
    analysis = MrEko.nest.track.analysis(filename)
    profile  = MrEko.nest.track.profile(:md5 => MrEko.md5(filename), :bucket => 'audio_summary').body.track

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
