class EkoTest < Test::Unit::TestCase  
  
  context "a new playlist" do
    setup do
      @playlist = Eko::Playlist.new
    end
    
    should "have no songs" do
      assert_equal 0, @playlist.songs.size
    end
  end
  
  # context "instantiation of a new instance" do
  # 
  #   context "without a block" do
  #     should "not save the playlist" do
  #       Eko::Playlist.any_instance.expects(:save).never
  #       Eko::Playlist.new
  #     end
  #   end
  #   
  #   context "with a block" do
  #     should "yield self" do
  #       p = Eko::Playlist.new do |list|
  #         list.name = 'temp'
  #       end
  #       assert_equal 'temp', p.name
  #     end
  #     
  #     should "save the playlist" do
  #       Eko::Playlist.any_instance.expects(:save).once
  #       Eko::Playlist.new{ |p| p.add_song(Eko::Song.new) }
  #     end
  #   end
  # end
  # 
end