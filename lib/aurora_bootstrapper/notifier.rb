require 'aws-sdk-s3'

module AuroraBootstrapper
  class Notifier
    DATE_FORMAT = "%Y-%m-%d"

    def initialize( s3_path: )
      @s3_path = s3_path
    end
      
    def export_date
      @export_date ||= ENV.fetch('EXPORT_DATE', export_date_override )
    end
    
    # ENV is string to string dictionary
    def export_date_override
      return nil unless ENV.key?('EXPORT_DATE_OVERRIDE')

      today = Date.today
      days_ago = (0..30).find do | days_ago |
        exists_export? date: today-days_ago
      end
      
      converted_days_ago = (days_ago.nil? || days_ago.to_i == 0) ? 1 : days_ago.to_i
      ( today - converted_days_ago + 1).strftime( DATE_FORMAT )
    end

    def exists_export?( date: )
      prefix = [ bucket_path, date.strftime( DATE_FORMAT ) ].join( '/' )

      found_object = client.list_objects_v2({ 
        bucket: bucket,
        prefix: prefix }).contents.find do | object | 
          object.key.include? "DONE"
        end

      !found_object.nil?
    end

    def notify
      client.put_object(
        bucket: bucket,
        key: object_key
      )
      AuroraBootstrapper.logger.info( message: "State file has been uploaded to S3 '#{bucket}/#{object_key}'." )
    rescue => e
      AuroraBootstrapper.logger.error( message: "State file failed to upload to S3 '#{bucket}/#{object_key}': #{e.message}." )
    end
    
    protected
    
    def region
      @region ||= ENV.fetch( 'REGION', 'us-west-2' )
    end
    
    def client
      @client ||= Aws::S3::Client.new(region: region)
    end
      
    def bucket
      @bucket  ||= unprefixed_path.split( '/' ).first
    end
      
    def object_key
      @object_key ||= [ bucket_path, export_date, filename ].join( '/' )
    end
    
    def bucket_path
      @bucket_path ||= ( unprefixed_path.split( '/' ) - [ bucket ] ).join( '/' )
    end
    
    def filename
      'DONE.txt'
    end
    
    def unprefixed_path
      @unprefixed_path ||= @s3_path.gsub(/s3:\/\//, "" )
    end

  end
end