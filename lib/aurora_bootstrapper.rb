require "json"

module AuroraBootstrapper
  autoload :Converter, "converter"
  autoload :CsvParser, "csv_parser"
  autoload :Database,  "database"
  autoload :Exporter,  "exporter"
  autoload :File,      "file"
  autoload :Logger,    "logger"
  autoload :Table,     "table"

  ROW_DELIMITER = -'AURORA-BOOTSTRAP-EXPORT-ROW-DELIMITER'
  COL_DELIMITER = -'AURORA-BOOTSTRAP-EXPORT-COL-DELIMITER'

  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new( STDOUT )
end
