require 'test_helper'

class UtilityTest < Minitest::Test

  def test_db_user_from_env
    assert_equal 'root', AuroraBootstrapper::Utility.db_user
  end

  def test_db_user_from_file
    ENV.delete('DB_USER')
    assert_equal 'user', AuroraBootstrapper::Utility.db_user
    ENV['DB_USER'] = 'root'
  end

  def test_db_pass_from_env
    assert_equal 'root', AuroraBootstrapper::Utility.db_pass
  end

  def test_db_pass_from_file
    ENV.delete('DB_PASS')
    assert_equal 'pass', AuroraBootstrapper::Utility.db_pass
    ENV['DB_PASS'] = 'root'
  end

  def test_rollbar_token_from_env
    assert_equal '', AuroraBootstrapper::Utility.rollbar_token
  end

  def test_rollbar_token_from_file
    ENV.delete('ROLLBAR_TOKEN')
    assert_equal 'rollbar', AuroraBootstrapper::Utility.rollbar_token
    ENV['ROLLBAR_TOKEN'] = ''
  end
end