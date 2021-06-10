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
      d                   = DateTime.now
      d_str               = d.strftime("%Y-%m-%d")
      @export_date        = ENV.fetch( 'EXPORT_DATE', d_str )
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
                             blacklisted_fields: @blacklisted_fields,
                             export_date: @export_date 
          database.export! into_bucket: @export_bucket
        rescue => e
          AuroraBootstrapper.logger.error message: "Error in database #{database_name}", error: e
        end
      end

      result = true
      if @notifier
        result = @notifier.push_state?( export_date: @export_date, into_bucket: @export_bucket )
      end

      result
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
