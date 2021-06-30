$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "zeitwerk"
require 'simplecov'
require 'dotenv'
require 'mysql2'

Dotenv.load('.env.test')

SimpleCov.start do
  add_filter "/test/"
end

class PutsLogger
  [:fatal, :error, :warn, :info, :debug].each do |severity|
    define_method severity do | args, &block |
      puts args.inspect
    end
  end
end

def with_logger( logger )
  old_logger = AuroraBootstrapper.logger
  AuroraBootstrapper.logger = logger

  yield
  
  AuroraBootstrapper.logger = old_logger
end

def with_puts_logger
  with_logger PutsLogger.new do
    yield
  end
end

def with_nil_logger
  with_logger Logger.new( "/dev/null" ) do
    yield
  end
end

# Greg's local services
module Gls
  # something storage
  class S2
    class << self
      attr_accessor :files_written
    end

    def get_object( bucket:, key:, range: "" )
      FileObject.new path: "#{bucket}/#{key}", range: range
    end

    def put_object( acl:, body:, bucket:, key: )
      self.class.files_written ||= []

      self.class.files_written << { acl: acl,
                                   body: body,
                                 bucket: bucket,
                                    key: key }

      return { etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
         version_id: "Kirh.unyZwjQ69YxcQLA8z4F5j3kJJKr" }
    end
  end

  class FileObject
    def initialize( path:, range: "" )
      @string    = StringIO.new( File.new( path, 'r' ).read )
      @raw_range = range
    end

    def body
      self
    end

    def content_length
      @string.length
    end

    def read( &block )
      if range
        @string.read range.begin, &block
        @string.read @range.end - range.begin, &block
      else
        @string.read &block
      end
    end

    def range
      @range ||= begin
        if @raw_range.empty?
          nil
        else
          numbers = @raw_range.split('=').last.split('-').map(&:to_i)
          Range.new *numbers
        end
      end
    end
  end
end

loader = Zeitwerk::Loader.new
loader.log!
loader.push_dir( File.expand_path( "../../lib/", __FILE__) )
loader.setup
loader.eager_load

require "minitest/autorun"
require "mocha/minitest"
