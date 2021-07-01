require 'test_helper'

class LoggerTest < Minitest::Test

  def test_severeties_with_rollbar_token_from_env
    ENV.stub(:key?, true) do 
      local_logger = AuroraBootstrapper::Logger.new( '/dev/null' )
      [ :fatal, :error, :warn, :info, :debug ].each do |severity|
        local_logger.send severity, message: "hello", error: IOError.new
      end
    end
  end

  def test_severeties_with_rollbar_token_from_file
    ENV.stub(:key?, false) do 
      local_logger = AuroraBootstrapper::Logger.new( '/dev/null' )
      [ :fatal, :error, :warn, :info, :debug ].each do |severity|
        local_logger.send severity, message: "hello", error: IOError.new
      end
    end
  end
end