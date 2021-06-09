require 'mysql2'

module AuroraBootstrapper
  class Exporter
    attr_reader :client

    def initialize( client:, prefix: "", export_bucket:, blacklisted_tables: "", whitelisted_tables: "", blacklisted_fields: "", notifier: nil )
      @match              = "#{prefix}.*"
      @export_bucket      = export_bucket
      @blacklisted_tables = blacklisted_tables.split(",")
      @whitelisted_tables = whitelisted_tables.split(",")
      @blacklisted_fields = blacklisted_fields.split(",")
      @client             = client
      @notifier           = notifier
    end

    def export!
      @client.query( "set sql_mode='NO_BACKSLASH_ESCAPES'" )
      database_names.all? do | database_name |
        begin
          @client.query( "use `#{database_name}`" )
          database = Database.new database_name: database_name,
                                         client: @client,
                             blacklisted_tables: @blacklisted_tables,
                             whitelisted_tables: @whitelisted_tables,
                             blacklisted_fields: @blacklisted_fields
          database.export! into_bucket: @export_bucket
        rescue => e
          AuroraBootstrapper.logger.error message: "Error in database #{database_name}", error: e
        end
      end

      @notifier.push_state?( into_bucket: @export_bucket )
    end

    def database_names
      @database_names ||= @client.query( "SHOW DATABASES" )
                            .map do |db|
                              db[ "Database" ]
                            end.select do | database_name |
                              database_name.match @match
      end
    rescue => e
      AuroraBootstrapper.logger.fatal message: "Error getting databases", error: e
      []
    end
  end
end
