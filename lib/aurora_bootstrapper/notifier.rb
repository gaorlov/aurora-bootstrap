module AuroraBootstrapper
  class Notifier
    def initialize( s3_path: s3_path)
        @s3_path = s3_path
        if ENV.fetch( 'EXPORT_DATE_OVERRIDE', false )
          @export_date ||= ENV.fetch( 'EXPORT_DATE', DateTime.now.strftime("%Y-%m-%d") )
        else
          @export_date ||= ENV.fetch('EXPORT_DATE', nil)
        end
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

    def export_date
      @export_date
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