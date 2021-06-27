require 'test_helper'

class DatabaseTest < Minitest::Test
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

  def test_table_names
    database = AuroraBootstrapper::Database.new database_name: "master", client: @client, blacklisted_tables: []

    assert_equal [ "users", "websites" ], database.table_names
  end

  def test_table_names_for_dashed_databases
    database = AuroraBootstrapper::Database.new database_name: "user_name-test", client: @client, blacklisted_tables: []

    assert_equal [ "images" ], database.table_names
  end

  def test_globally_blacklisted_tables
    blacklist       = ["websites"]
    master_database = AuroraBootstrapper::Database.new database_name: "master", client: @client, blacklisted_tables: blacklist
    stuff_database  = AuroraBootstrapper::Database.new database_name: "user_stuff", client: @client, blacklisted_tables: blacklist

    assert_equal [ "users" ], master_database.table_names
    assert_equal [ "photos" ], stuff_database.table_names
  end

  def test_db_specific_blacklisted_tables
    blacklist           = ["master.websites", "user_properties.hypersensitive_data"]
    master_database     = AuroraBootstrapper::Database.new database_name: "master", client: @client, blacklisted_tables: blacklist
    properties_database = AuroraBootstrapper::Database.new database_name: "user_properties", client: @client, blacklisted_tables: blacklist
    stuff_database      = AuroraBootstrapper::Database.new database_name: "user_stuff", client: @client, blacklisted_tables: blacklist


    assert_equal [ "users" ], master_database.table_names
    assert_equal [ "photos", "websites" ], stuff_database.table_names
    assert_equal [ "avatars" ], properties_database.table_names
  end

  def test_regexp_blacklisted_tables
    blacklist           = ["master.websites", "/.*sensitive.*/"]
    master_database     = AuroraBootstrapper::Database.new database_name: "master", client: @client, blacklisted_tables: blacklist
    properties_database = AuroraBootstrapper::Database.new database_name: "user_properties", client: @client, blacklisted_tables: blacklist
    stuff_database      = AuroraBootstrapper::Database.new database_name: "user_stuff", client: @client, blacklisted_tables: blacklist


    assert_equal [ "users" ], master_database.table_names
    assert_equal [ "photos", "websites" ], stuff_database.table_names
    assert_equal [ "avatars" ], properties_database.table_names
  end

  def test_regexp_whitelisted_tables
    whitelist           = ["master.websites", "/.*sensitive.*/"]
    master_database     = AuroraBootstrapper::Database.new database_name: "master", client: @client, whitelisted_tables: whitelist
    properties_database = AuroraBootstrapper::Database.new database_name: "user_properties", client: @client, whitelisted_tables: whitelist
    stuff_database      = AuroraBootstrapper::Database.new database_name: "user_stuff", client: @client, whitelisted_tables: whitelist


    assert_equal [ "websites" ], master_database.table_names
    assert_equal [ ], stuff_database.table_names
    assert_equal [ "hypersensitive_data" ], properties_database.table_names
  end

  def test_export_calls_table
    AuroraBootstrapper::Table.any_instance.stubs( :export! ).returns( true )

    AuroraBootstrapper::Notifier.any_instance.stubs( :notify ).returns( true )

    AuroraBootstrapper::Notifier.any_instance.stubs( :export_date ).returns( '2021-06-01' )
    
    assert @exporter.export!
  end
end