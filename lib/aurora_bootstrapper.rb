require "json"

module AuroraBootstrapper
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new( STDOUT )
end