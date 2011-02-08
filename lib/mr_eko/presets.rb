module MrEko::Presets
  FACTORY = {
    :gym => {
      :tempo    => 125..300, # sweat, sweat, sweat!
      :mode     => 'major',  # bring the HappyHappy
      :duration => 180..300  # shorter, poppier tunes
    },
    :chill => {
      :tempo    => 60..120,  # mellow
      :duration => 180..600  # bring the epic, long-players
    }
  }

  module ClassMethods

    def load_preset(name)
      FACTORY[name.to_sym]
    end

  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
