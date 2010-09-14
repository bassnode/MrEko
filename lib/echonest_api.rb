module Eko
  module Nest
    
    def md5(filename)
      Digest::MD5.hexdigest(open(filename).read)
    end
  #   module ClassMethods
  #     
  #   end
  #   
  #   module InstanceMethods
  #     def go
  #       puts Eko.nest
  #     end
  #   end
  #   
  #   def self.included(receiver)
  #     receiver.extend         ClassMethods
  #     receiver.send :include, InstanceMethods
  #   end
  # end
end