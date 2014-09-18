class MrEko::TagParser

  def self.parse(filename)
    Mp3Info.open(filename) do |file|
      result = Result.new
      result.artist = file.tag.artist
      result.title = file.tag.title
      result.album = file.tag.album

      result
    end

  end

  class Result < Hash
    include Hashie::Extensions::MethodAccess
    include Hashie::Extensions::IndifferentAccess
  end

end

