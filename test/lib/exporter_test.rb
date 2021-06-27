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
    stub_client = Aws::S3::Client.new(stub_responses: true)
    stubbed_objs = {
      contents: [
        { key: 'DONE.txt' },
      ]
    }
    stub_client.stub_responses(:list_objects_v2, stubbed_objs)
    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( stub_client )

    with_puts_logger do
      AuroraBootstrapper::Database.any_instance.stubs( :table_names ).returns( 5 )

      AuroraBootstrapper::Notifier.any_instance.stubs( :notify ).returns( true )

      assert_output "{:message=>\"Error in database user_name-test\", :error=>#<NoMethodError: undefined method `all?' for 5:Integer>}\n" do
        @exporter.export!
      end
    end
  end

  def test_export_calls_database
    AuroraBootstrapper::Database.any_instance.stubs( :export! ).returns( true )
    
    AuroraBootstrapper::Notifier.any_instance.stubs( :notify ).returns( true )

    AuroraBootstrapper::Notifier.any_instance.stubs( :export_date ).returns( '2021-06-01' )

    assert @exporter.export!
  end
end