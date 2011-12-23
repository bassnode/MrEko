class MrEko::TimedPlaylist

  # The playlist content
  attr_reader :songs

  # The number of seconds the playlist should be.
  attr_reader :length

  attr_reader :name

  # The hash which holds all the controlling parameters for the Playlist.
  attr_reader :attributes

  # Hash keyed by the attribute w/ a value of the number of steps to reach the
  # final setting.
  attr_reader :step_map

  class InvalidAttributes < Exception; end


  def initialize(opts={})
    @attributes = Hash.new{ |hsh, key| hsh[key] = {} }
    @step_map   = Hash.new
    @songs = []
    @overall_seconds_used = 0

    handle_opts(opts)

    yield self if block_given?

  end

  def save
    validate_attributes
    determine_steps
    populate

    self
  end

  def initial(opt, value)
    add_attribute(:initial, opt, value)
  end

  def final(opt, value)
    add_attribute(:final, opt, value)
  end

  def static(opt, value)
    add_attribute(:static, opt, value)
  end


  private

  def handle_opts(opts)
    @length = opts.delete(:length)
    @name   = opts.delete(:name)
  end

  def add_attribute(att_type, opt, value)
    attributes[att_type][opt] = value
  end

  def validate_attributes
    init_atts  = attributes[:initial]
    final_atts = attributes[:final]

    unless init_atts.keys.map(&:to_s).sort == final_atts.keys.map(&:to_s).sort
      raise InvalidAttributes, "You must provide values for both the initial and final settings, not just one."
    end
  end

  def determine_steps

    attributes[:initial].each_pair do |attr, val|

      denominator = case attr
      when :tempo, :loudness
        attributes[:final][attr] - attributes[:initial][attr]
      when :danceability, :energy
        ( ( attributes[:final][attr] - attributes[:initial][attr] ) * 10 ).round
      when :mode
        2
      when :key
        MrEko.key_lookup(attributes[:final][attr]) - MrEko.key_lookup(attributes[:initial][attr])
      end

      step_length = @length.to_f / denominator
      step_length = 4.minutes if step_length.in_minutes < 4

      step_map[attr] = [denominator, step_length.round]
    end

    step_map
  end

  def find_songs(attribute=:tempo)
    step_count, step_length = step_map[attribute]
    direction = step_count > 0 ? :asc : :desc

    sorted = [attributes[:initial][attribute], attributes[:final][attribute]].sort
    all_songs = MrEko::Song.where({attribute => Range.new(*sorted)} & ~{:duration => nil}).order("#{attribute} #{direction}".lit).all

    raise MrEko::NoSongsError, "no songs with those #{attribute} parameters" if all_songs.blank?

    all_songs
  end

  # XXX Just sketching this part out at the moment...
  # needs tests and to work with attributes other than tempo!
  # NOTE: Might need to make a cluster map here instead of just choosing
  # enough songs to fulfill the step_length.  This is because the
  # Playlist#length can be fulfilled even before we reach the target/final
  # target.  I think a better rule would be to pluck a song having the
  # initial and final values and then try to evenly spread out the remaining
  # time with the songs in the middle...hence the map of the clusters of
  # songs.  Then we can make selections more intelliegently.
  def populate
    step_count, step_length = step_map[:tempo]
    return unless step_count && step_length

    all_songs = find_songs

    # Handle low song count by making 1 the min step size.
    songs_to_examine_per_step = [1, all_songs.size / step_count].max

    # Make sure the playlist starts/ends well.
    grouped_songs = all_songs.in_groups_of(songs_to_examine_per_step, false)
    [grouped_songs.shift, grouped_songs.pop].map{ |bookend| append_songs(bookend, step_length) }

    loop do
      batch = grouped_songs.shift
      break if @overall_seconds_used >= @length or batch.blank?

      append_songs(batch, step_length)
    end

    # Sort em
    direction = step_count > 0 ? :asc : :desc
    @songs = direction == :asc ? @songs.sort_by(&:tempo) : @songs.sort_by(&:tempo).reverse
  end

  private
  def append_songs(song_batch, step_length)
    return if song_batch.blank?

    step_seconds_used = 0
    song_set = []

    length_map = song_batch.inject({}) do |hsh, song|
      song_length_proximity = (song.duration - step_length).abs
      hsh[song_length_proximity] = song
      hsh
    end

    length_map.sort_by{ |key, song| key }.each do |length, song|
      song_set << song
      step_seconds_used += song.duration
      break if step_seconds_used >= step_length
    end

    @overall_seconds_used += step_seconds_used

    @songs = @songs + song_set
  end
end

# @length = 3600 # 1hr
# tempo range 20bpm
#
# get count of all songs with the params, eg: tempo => 120..140
# => 100

# so take 100songs / 20steps = 5 songs per step
# out of the first 5 songs, select 3min worth using the first

