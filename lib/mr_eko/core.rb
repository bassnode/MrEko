module MrEko

  module Core
    def self.included(base)
      base.send(:include, GlobalHelpers)
      base.extend GlobalHelpers

      # The Sequel timestamps plugin doesn't seem to work, so...
      def before_create; self.created_on = Time.now.utc; end
      def before_update; self.updated_on = Time.now.utc; end
    end

    module GlobalHelpers
      def log(string, level=:debug)
        MrEko.logger.send(level, string)
      end
    end

  end
end
