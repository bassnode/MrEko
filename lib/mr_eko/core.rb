module MrEko

  module Core
    def self.included(base)
      base.send(:include, GlobalHelpers)
      base.extend GlobalHelpers
    end

    module GlobalHelpers
      def log(string, level=:debug)
        MrEko.logger.send(level, string)
      end
    end
  end
end
