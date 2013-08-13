# TODO: Refactor this so everything's not in class methods
class MrEko::Song < Sequel::Model
  include MrEko::Core
  plugin :validation_helpers
  many_to_many :playlists, :through => :playlist_entries

  REQUIRED_ID3_TAGS = [:artist, :title]

  # A wrapper which gets called by the bin file.
  # By default will try to extract the needed song info from the ID3 tags and
  # if fails, will analyze via ENMFP/upload.
  #
  # @param [String] file path of the MP3
  # @param [Hash] options hash
  # @option options [Boolean] :tags_only If passed, skip ENMFP
  # @return [MrEko::Song]
  def self.create_from_file!(filename, opts={})
    md5 = MrEko.md5(filename)
    existing = where(:md5 => md5).first
    return existing unless existing.nil?

    if song = catalog_via_tags(filename, :md5 => md5)
      song
    elsif !opts[:tags_only]
      catalog_via_enmfp(filename, :md5 => md5)
    end

  end

  # Run local analysis (ENMFP) on the passed file, send that identifier code
  # to EN and store the returned details in our DB.
  # If the local analysis fails, upload the MP3 to EN for server-side analysis.
  #
  # @param [String] location of the audio file
  # @param [Hash] opts
  # @option opts [String] :md5 pre-calculated MD5 of file
  # @return [MrEko::Song, NilClass] the created Song
  def self.catalog_via_enmfp(filename, opts={})
    md5 = opts[:md5] || MrEko.md5(filename)
    existing = where(:md5 => md5).first
    return existing unless existing.nil?

    return if file_too_big? filename

    log "Identifying with ENMFP code #{filename}"

    begin
      fingerprint_json = enmfp_data(filename, md5)
      profile = identify_from_enmfp_data(fingerprint_json)
    rescue MrEko::EnmfpError => e
      log %Q{Issues using ENMFP data "(#{e})" #{e.backtrace.join("\n")}}
      analysis, profile = get_datapoints_by_upload(filename)
    end

    create do |song|
      song.filename       = File.expand_path(filename)
      song.md5            = md5
      song.code           = fingerprint_json ? fingerprint_json.code : nil
      song.tempo          = profile.audio_summary.tempo
      song.duration       = profile.audio_summary.duration
      song.key            = profile.audio_summary[:key]
      song.mode           = profile.audio_summary.mode
      song.loudness       = profile.audio_summary.loudness
      song.time_signature = profile.audio_summary.time_signature
      song.echonest_id    = profile.id
      song.bitrate        = fingerprint_json ? fingerprint_json.metadata.bitrate : nil
      song.title          = profile.title
      song.artist         = profile.artist || profile.artist_name
      song.album          = fingerprint_json ? fingerprint_json.metadata.release : profile.release
      song.danceability   = profile.audio_summary.danceability
      song.energy         = profile.audio_summary.energy
    end
  end

  # Parses the file's ID3 tags and converts and strange encoding.
  #
  # @param [String] The file path
  # @return [ID3Lib::Tag]
  def self.parse_id3_tags(filename)
    log "Parsing ID3 tags"

    clean_tags ID3Lib::Tag.new(filename, ID3Lib::V_ALL)
  end


  # Uses ID3 tags to query Echonest and then store the resultant data.
  #
  # @see Song.catalog_via_enmfp for options
  # @return [MrEko::Song]
  def self.catalog_via_tags(filename, opts={})
    tags = parse_id3_tags(filename)
    return unless has_required_tags? tags

    md5 = opts[:md5] || MrEko.md5(filename)
    begin
      analysis = MrEko.nest.song.search(:artist => tags.artist,
                                        :title => tags.title,
                                        :bucket => 'audio_summary',
                                        :limit => 1).songs.first
    rescue => e
      log "BAD TAGS? #{tags.artist} - #{tags.title} - #{filename}"
      log e.message
      log e.backtrace.join("\n")
      return
    end

    create do |song|
      song.filename       = File.expand_path(filename)
      song.md5            = md5
      song.tempo          = analysis.audio_summary.tempo
      song.duration       = analysis.audio_summary.duration
      song.key            = analysis.audio_summary['key']
      song.mode           = analysis.audio_summary.mode
      song.loudness       = analysis.audio_summary.loudness
      song.time_signature = analysis.audio_summary.time_signature
      song.echonest_id    = analysis.id
      song.title          = tags.title
      song.artist         = tags.artist
      song.album          = tags.album
      song.danceability   = analysis.audio_summary.danceability
      song.energy         = analysis.audio_summary.energy
      # XXX: Won't have these from tags - worth getting from EN?
      # song.code           = fingerprint_json.code
      # XXX: ID3Lib doesn't return these - worth parsing?
      # song.bitrate        =  profile.bitrate
    end if analysis
  end

  def self.has_required_tags?(tags)
    found = REQUIRED_ID3_TAGS.inject([]) do |present, meth|
      present << tags.send(meth)
    end

    found.compact.size == REQUIRED_ID3_TAGS.size ? true : false
  end

  # Using the Echonest Musical Fingerprint lib in the hopes
  # of sidestepping the mp3 upload process.
  #
  # @param [String] file path of the MP3
  # @param [String] MD5 hash of the file
  # @return [Hash] data from the ENMFP process
  def self.enmfp_data(filename, md5)
    unless File.exists?(fp_location(md5))
      log 'Waiting for ENMFP binary...'
      `#{MrEko.enmfp_binary} "#{File.expand_path(filename)}" > #{fp_location(md5)}`
    end

    begin
      raw_json = File.read fp_location(md5)
      hash = Hashie::Mash.new(JSON.parse(raw_json).first)
      hash.raw_data = raw_json

      if hash.keys.include?('error')
        raise MrEko::EnmfpError, "Errors returned in the ENMFP fingerprint data: #{hash.error.inspect}"
      end

    rescue JSON::ParserError => e
      raise MrEko::EnmfpError, e.message
    end

    hash
  end

  # Returns the analysis and profile data from Echonest for the given track.
  #
  # @param [String] file path of the MP3
  # @return [Array] Analysis and profile data from EN
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

  # Is the song over a sane limit for uploading and ENMFP?
  #
  # @param [String] filename
  # @return [Boolean]
  def self.file_too_big?(file)
    File.size(file)/1024/1024 > 50
  end

  # @param [Hash]
  # @return [Hashie, EnmfpError] EN song API result
  def self.identify_from_enmfp_data(json)
    identify_options = {}.tap do |opts|
      opts[:code]    = json.raw_data
      opts[:artist]  = json.metadata.artist
      opts[:title]   = json.metadata.title
      opts[:release] = json.metadata.release
      opts[:bucket]  = 'audio_summary'
    end

    profile = MrEko.nest.song.identify(identify_options)
    raise MrEko::EnmfpError, "Nothing returned from song/identify API call" if profile.songs.empty?

    profile.songs.first
  end

  # Return the file path of the EN fingerprint JSON file
  #
  # @param [String] MD5 hash of the file
  # @return [String] full path of file with passed MP5
  def self.fp_location(md5)
    File.expand_path File.join(MrEko::FINGERPRINTS_DIR, "#{md5}.json")
  end

  # @param [Array<ID3Lib::Tag>]
  # @return [Array<ID3Lib::Tag>]
  def self.clean_tags(tags)

    (REQUIRED_ID3_TAGS + [:album]).each do |rt|
      tag = tags.send(rt).to_s
      if tag.encoding != Encoding::UTF_8
        decoded = tag.encode
      else
        decoded = tag
      end

      tags.send("#{rt}=", decoded)
    end

    tags
  end
end
