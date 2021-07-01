require 'test_helper'

class LoggerTest < Minitest::Test
  def setup
    @logger = AuroraBootstrapper::Logger.new( '/dev/null' )
  end

  def test_severeties_with_rollbar_token_from_env
    [ :fatal, :error, :warn, :info, :debug ].each do |severity|
      @logger.send severity, message: "hello", error: IOError.new
    end
  end

  def test_severeties_with_rollbar_token_from_file
    ENV.delete("ROLLBAR_TOKEN")
    local_logger = AuroraBootstrapper::Logger.new( '/dev/null' )
    [ :fatal, :error, :warn, :info, :debug ].each do |severity|
      local_logger.send severity, message: "hello", error: IOError.new
    end
    ENV['ROLLBAR_TOKEN']=nil
  end
end