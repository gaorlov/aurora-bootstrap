require 'test_helper'

class UtilityTest < Minitest::Test

  def test_db_user_from_env
    assert_equal 'root', AuroraBootstrapper::Utility.get_db_user
  end

  def test_db_user_from_file
    ENV.stub(:key?, false) do 
      assert_equal 'user', AuroraBootstrapper::Utility.get_db_user
    end
  end

  def test_db_pass_from_env
    assert_equal 'root', AuroraBootstrapper::Utility.get_db_pass
  end

  def test_db_pass_from_file
    ENV.stub(:key?, false) do 
      assert_equal 'pass', AuroraBootstrapper::Utility.get_db_pass
    end
  end

  def test_rollbar_token_from_env
    assert_equal '', AuroraBootstrapper::Utility.get_rollbar_token
  end

  def test_rollbar_token_from_file
    ENV.stub(:key?, false) do 
      assert_equal 'rollbar', AuroraBootstrapper::Utility.get_rollbar_token
    end
  end
end