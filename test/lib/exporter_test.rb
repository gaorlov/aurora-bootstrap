require 'test_helper'

class ExporterTest < Minitest::Test
  def setup
    @prefix   = ENV.fetch "PREFIX", ""
    @bukkit   = ENV.fetch "EXPORT_BUCKET"

    @client   = Mysql2::Client.new( host: ENV.fetch( "DB_HOST" ),
                                username: ENV.fetch( "DB_USER" ),
                                password: ENV.fetch( "DB_PASS" ))

    @exporter = AuroraBootstrapper::Exporter.new( client: @client,
                                                  prefix: @prefix,
                                           export_bucket: @bukkit)
  end

  def test_database_names
    assert_equal [ "user_name-test", "user_properties", "user_stuff" ], @exporter.database_names
  end

  def test_database_name_prefix
    assert_equal [ "user_name-test", "user_properties", "user_stuff" ], @exporter.database_names

    everything_exporter = AuroraBootstrapper::Exporter.new( client: @client,
                                                            prefix: "",
                                                     export_bucket: @bukkit)

    assert_empty [ "information_schema", "master", "mysql", "performance_schema", "sys", "user_properties", "user_stuff" ] - everything_exporter.database_names
  end

  def test_database_names_logs_on_bad_connection
    with_puts_logger do
      exporter = AuroraBootstrapper::Exporter.new( client: nil,
                                                    prefix: @prefix,
                                             export_bucket: @bukkit)

      assert_output "{:message=>\"Error getting databases\", :error=>#<NoMethodError: undefined method `query' for nil:NilClass>}\n" do
        exporter.database_names
      end
    end
  end

  def test_export_logs_on_error
    with_puts_logger do
      AuroraBootstrapper::Database.any_instance.stubs( :table_names ).returns( 5 )

      mock = Minitest::Mock.new
      mock.expect :notify, true

      AuroraBootstrapper::Notifier.any_instance.stubs( :notify ).returns( true )

      assert_output "{:message=>\"Error in database user_name-test\", :error=>#<NoMethodError: undefined method `all?' for 5:Integer>}\n" do
        @exporter.export!
      end
    end
  end

  def test_export_calls_database
    mock = Minitest::Mock.new
    mock.expect :export!, nil

    AuroraBootstrapper::Database.any_instance.stubs( :export! ).returns( true )
    
    mock = Minitest::Mock.new
    mock.expect :notify, true

    AuroraBootstrapper::Notifier.any_instance.stubs( :notify ).returns( true )

    assert @exporter.export!
  end
end