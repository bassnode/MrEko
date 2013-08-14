class MrEko::TagParser

  def self.parse(filename)
    TagLib::FileRef.open(filename, false) do |file|
      tag = file.tag
      result = Result.new
      result.artist = tag.artist
      result.title = tag.title
      result.album = tag.album

      result
    end

  end

  class Result < Hash
    include Hashie::Extensions::MethodAccess
    include Hashie::Extensions::IndifferentAccess
  end

end

