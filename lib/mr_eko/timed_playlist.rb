class MrEko::TimedPlaylist

  #
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

    handle_opts(opts)

    yield self if block_given?

  end

  def save
    validate_attributes
    determine_steps
    find_songs

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

  # XXX Just sketching this part out at the moment...
  # needs tests (and complete logic!)
  def find_songs
    step_count, step_length = step_map[:tempo]
    return unless step_count && step_length
    direction = step_count > 0 ? :asc : :desc
    sorted_tempos = [attributes[:initial][:tempo], attributes[:final][:tempo]].sort
    tempo_range = Range.new(*sorted_tempos)
    all_songs = MrEko::Song.where({:tempo => tempo_range} & ~{:duration => nil}).order("tempo #{direction}".lit).all

    songs_to_examine_per_step = step_count > all_songs.size ? 1 : all_songs.size / step_count

    overall_seconds_used = 0
    all_songs.each_slice(songs_to_examine_per_step).each do |songs|
      break if overall_seconds_used >= @length

      song_length_proximity = 0
      length_map = songs.inject({}) do |hsh, song|
        song_length_proximity = (song.duration - step_length).abs
        hsh[song_length_proximity] = song
        hsh
      end

      step_seconds_used = 0
      length_map.sort_by{ |key, song| key }.each do |length, song|
        @songs << song
        step_seconds_used += song.duration
        overall_seconds_used += song.duration
        break if step_seconds_used >= step_length
      end

    end
    # Might need to make a cluster map here instead of just choosing enough
    # songs to fulfill the step_length.  This is because the over
    # Playlist#length can be fulfilled even before we reach the target/final
    # target.  I think a better rule would be to pluck a song having the
    # initial and final values and then try to evenly spread out the remaining
    # time with the songs in the middle...hence the map of the clusters of
    # songs.  Then we can make selections more intelliegently.

    @songs
  end
end

# @length = 3600 # 1hr
# tempo range 20bpm
#
# get count of all songs with the params, eg: tempo => 120..140
# => 100

# so take 100songs / 20steps = 5 songs per step
# out of the first 5 songs, select 3min worth using the first

