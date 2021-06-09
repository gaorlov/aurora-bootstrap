module AuroraBootstrapper
  class Database
    def initialize( database_name:, client:, blacklisted_tables: [], whitelisted_tables: [], blacklisted_fields: [], export_date: nil )
      @database_name      = database_name
      @blacklisted_tables = blacklisted_tables
      @whitelisted_tables = whitelisted_tables
      @blacklisted_fields = blacklisted_fields
      @client             = client
      @export_date        = export_date
    end

    def table_names
      @table_names ||= begin
        # if we only whitelist, assume that everything else is blacklisted
        filtered_tables = whitelist_only? ? [] : tables

        filtered_tables -= blacklisted unless blacklisted.empty?
        filtered_tables += whitelisted unless whitelisted.empty?
        filtered_tables
      end
    end

    def export!( into_bucket: )
      table_names.all? do | table_name |
        table = Table.new database_name: @database_name,
                             table_name: table_name,
                                 client: @client,
                     blacklisted_fields: @blacklisted_fields,
                     export_date: @export_date

        table.export!( into_bucket: into_bucket )
      end
    end

    private

    def tables
      @tables ||= @client.query( "SHOW TABLES IN `#{@database_name}`" ).map do | row |
        row[ "Tables_in_#{@database_name}" ]
      end
    end

    def blacklisted
      tables.select do | table_name |
        matches? table_name, @blacklisted_tables
      end
    end

    def whitelisted
      tables.select do | table_name |
        matches? table_name, @whitelisted_tables
      end
    end

    def whitelist_only?
      @blacklisted_tables.empty? and !@whitelisted_tables.empty?
    end

    def matches?( table_name, filter_list )
      filter_list.any? do | filtered_table |
        # blacklisted tables can be in the format of "table" or "database.table"
        
        bl_table_name    = filtered_table
        bl_database_name = @database_name

        if filtered_table.match( /\/.*\// )
          regexp         = filtered_table.slice(1...-1)
          qualified_name = "#{@database_name}.#{table_name}"

          bl_table_name  = qualified_name.match( /#{regexp}/ ) ? table_name : false
        
        elsif filtered_table.match( /[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+/ )
          bl_database_name, bl_table_name = filtered_table.split(".")
        end

        bl_table_name    == table_name &&
        bl_database_name == @database_name
      end
    end
  end
end
