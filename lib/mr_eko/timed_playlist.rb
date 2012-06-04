class MrEko::TimedPlaylist < MrEko::Playlist

  # The number of seconds the playlist should be.
  attr_accessor :length

  # The name of the Song attribute to build on (tempo, key, etc.).
  attr_accessor :facet

  # The start and end value for the facet
  attr_accessor :initial, :final

  def initialize(opts={})
    @facet = opts.delete(:facet)
    @length = opts.delete(:length).to_i

    super
  end

  # Run these essential steps before saving, so that any fatal exception halt
  # the creation of the playlist.
  def before_save
    prepare_attributes
    find_song_groups!
  end

  # Have to add songs after save due to the Playlist needing to have a primary
  # key (generated at time of save). Lame.
  def after_save
    songs = @song_groups.sort_by{ |group| cost_of group }.first

    # Sort em
    direction = final - initial > 0 ? :asc : :desc
    songs = songs.sort_by(&facet)
    songs = songs.reverse if direction == :desc

    songs.each_with_index do |song, position|
      MrEko::PlaylistEntry.create(:playlist_id => self.id, :song_id => song.id, :position => position)
    end
  end

  private

  def prepare_attributes
    unless initial && final
      raise MrEko::InvalidAttributes, "You must provide values for both the initial and final settings, not just one."
    end

    case facet
    when :danceability, :energy
      @initial = (initial.to_i / 100.0)
      @final = (final.to_i / 100.0)
    when :mode
      @initial = MrEko.mode_lookup(initial)
      @final = MrEko.mode_lookup(final)
    when :key
      @initial = MrEko.key_lookup(initial)
      @final = MrEko.key_lookup(final)
    else
      @initial = initial.to_i
      @final = final.to_i
    end

  end

  def find_song_groups!(iterations=50)
    sorted = [initial, final].sort
    # Get every song in the required range
    all_songs = MrEko::Song.where({facet => Range.new(*sorted)} & ~{:duration => nil}).all

    if all_songs.blank?
      raise MrEko::NoSongsError, "no songs with those '#{facet}' parameters"
    elsif all_songs.length == 1 # Might want to warn/raise here?
      @song_groups = [ all_songs ]
      return
    end

    # Populate a number of potential playlists
    @song_groups = Array.new(iterations) do
      seconds_used = 0
      group = []
      available_songs = all_songs.dup

      until seconds_used >= @length or available_songs.empty? do
        random_index = rand(available_songs.length - 1)
        song = available_songs.delete_at(random_index)
        seconds_used += song.duration
        group << song
      end

      group
    end
  end

  # How bad is the passed group of songs with respect to the TimedPlaylist's
  # facet and length contraints?
  #
  # @param [Array<MrEko::Song>] the songs
  # @return [Float] the score - the lower, the better
  def cost_of(song_group)

    # Make sure we're sorted by the facet
    song_group.sort!{ |a,b| a[facet] <=> b[facet] }

    first_song_distance_to_target = song_group.first[facet] - initial
    last_song_distance_to_target = final - song_group.last[facet]

    # Calculate the facet differences between each song
    diffs = []
    song_group.in_groups_of(2) do |x,y|
      diffs << ( (x.nil? || y.nil?) ? 0 : x[facet] - y[facet])
    end

    diff_cost = diffs.inject(0){ |sum, n| sum + n }.abs

    # Penalty if the playlist is 20% longer than it should be
    total_length = song_group.inject(0.0){ |sum, song| sum + song.duration }
    length_penalty = total_length / @length > 0.20 ? 1.25 : 1

    (first_song_distance_to_target + last_song_distance_to_target + diff_cost) * length_penalty
  end
end
