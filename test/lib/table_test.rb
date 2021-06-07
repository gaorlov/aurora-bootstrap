require 'test_helper'
require 'aws-sdk-s3'

class TableTest < Minitest::Test
  def setup
    @prefix   = ENV.fetch "PREFIX", ""
    @bukkit   = ENV.fetch "EXPORT_BUCKET"

    @client   = Mysql2::Client.new( host: ENV.fetch( "DB_HOST" ),
                                username: ENV.fetch( "DB_USER" ),
                                password: ENV.fetch( "DB_PASS" ))

    @s3_client = Aws::S3::Client.new(stub_responses: true)
    @s3_client.stub_responses(:put_object, { etag: "test" })

    @exporter = AuroraBootstrapper::Exporter.new( client: @client,
                                                  prefix: @prefix,
                                           export_bucket: @bukkit )

    @table    = AuroraBootstrapper::Table.new database_name: "master",
                                                 table_name: "users",
                                                     client: @client,
                                                     s3_client: @s3_client
    @table2   = AuroraBootstrapper::Table.new database_name: "user_name-test",
                                                 table_name: "images",
                                                     client: @client,
                                                     s3_client: @s3_client
  end

  def test_fields
    assert_equal [ "id", "email", "first_name", "last_name" ], @table.fields
  end

  def test_json_object
    assert_equal "JSON_OBJECT( 'database', 'master', 'table', 'users', 'type', 'backfill', 'ts', unix_timestamp(), 'data', JSON_OBJECT('id', `id`, 'email', `email`, 'first_name', `first_name`, 'last_name', `last_name` ) )",
                 @table.json_object
  end

  def test_timestamp
    assert_equal 'unix_timestamp()', @table.timestamp
  end

  def test_export_statement
    expected = <<~SQL
      SELECT JSON_OBJECT( 'database', 'master', 'table', 'users', 'type', 'backfill', 'ts', unix_timestamp(), 'data', JSON_OBJECT('id', `id`, 'email', `email`, 'first_name', `first_name`, 'last_name', `last_name` ) )
        FROM `master`.`users`
      INTO OUTFILE S3 's3://bukkit/10-12-2020/master/users'
        MANIFEST ON
        OVERWRITE ON
    SQL
    assert_equal expected, @table.export_statement( into_bucket: "s3://bukkit")
  end

  def test_undated_export_statement
    @table.instance_variable_set(:@export_date, nil)
    expected = <<~SQL
      SELECT JSON_OBJECT( 'database', 'master', 'table', 'users', 'type', 'backfill', 'ts', unix_timestamp(), 'data', JSON_OBJECT('id', `id`, 'email', `email`, 'first_name', `first_name`, 'last_name', `last_name` ) )
        FROM `master`.`users`
      INTO OUTFILE S3 's3://bukkit/master/users'
        MANIFEST ON
        OVERWRITE ON
    SQL
    assert_equal expected, @table.export_statement( into_bucket: "s3://bukkit")
  end

  def test_dashed_db_export_statement
    expected = <<~SQL
      SELECT JSON_OBJECT( 'database', 'user_name-test', 'table', 'images', 'type', 'backfill', 'ts', unix_timestamp(), 'data', JSON_OBJECT('id', `id`, 'user_id', `user_id`, 'link', `link` ) )
        FROM `user_name-test`.`images`
      INTO OUTFILE S3 's3://bukkit/10-12-2020/user_name-test/images'
        MANIFEST ON
        OVERWRITE ON
    SQL
    assert_equal expected, @table2.export_statement( into_bucket: "s3://bukkit")
  end

  def test_export_logs
    with_logger PutsLogger.new do
      assert_output( /Export statement/ ) do
        @table.export!( into_bucket: "s3://bukkit")
      end

      @client.stubs( :query ).returns( "yay" )
      @table.stubs( :object_uploaded? ).returns( true )
      assert_output( /State file fails to be uploaded to S3 bucket / ) do
        assert @table.export!( into_bucket: "s3://bukkit")
      end
    end
  end

  def test_blacklisted_fields
    table = table_with_blacklist( ["first_name", "users.last_name", "master.users.email"] )
    
    assert table.blacklisted_field?( "first_name" )
    assert table.blacklisted_field?( "last_name" )
    assert table.blacklisted_field?( "email" )
  end

  def test_blacklisted_fields_with_regexps 
    table = table_with_blacklist( ["/first.*/", "/users.last.*/", "/.*.users.email/"] )
    
    assert table.blacklisted_field?( "email" )
    assert table.blacklisted_field?( "first_name" )
    assert table.blacklisted_field?( "last_name" )    
  end

  def test_blacklisting_fields_across_tables
    blacklisted_fields = [ '/pho.*.link/', 'user_id' ]

    tables = [ AuroraBootstrapper::Table.new( database_name: "user_stuff",
                                                 table_name: "photos",
                                                     client: @client,
                                         blacklisted_fields: blacklisted_fields ),

               AuroraBootstrapper::Table.new( database_name: "user_stuff",
                                                 table_name: "websites",
                                                     client: @client,
                                         blacklisted_fields: blacklisted_fields ) ]
    assert_equal [["id"], ["id", "link"]], tables.map(&:fields)
  end

  def test_export
    # because those logs aren't actually useful
    with_nil_logger do

      AuroraBootstrapper::Table.any_instance.stubs( :export_statement ).returns( "select 'hurrah'" )
      AuroraBootstrapper::Table.any_instance.stubs( :object_uploaded? ).returns( true )

      assert @exporter.export!

    end
  end

  private

  def table_with_blacklist( blacklisted_fields )
    AuroraBootstrapper::Table.new database_name: "master",
                                     table_name: "users",
                                         client: @client,
                             blacklisted_fields: blacklisted_fields
  end
end