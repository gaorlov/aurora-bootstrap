require 'test_helper'

class LoggerTest < Minitest::Test
  def setup
    @logger = AuroraBootstrapper::Logger.new( '/dev/null' )
  end

  def test_severeties
    [ :fatal, :error, :warn, :info, :debug ].each do |severity|
      @logger.send severity, message: "hello", error: IOError.new
    end
  end
end