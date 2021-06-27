require 'aws-sdk-s3'

module AuroraBootstrapper
  class Notifier
    def initialize( s3_path: )
      @s3_path = s3_path
    end
      
    def export_date
      @export_date ||= ENV.fetch('EXPORT_DATE', export_date_override )
    end
    
    # ENV is string to string dictionary
    def export_date_override
      # DateTime.now.strftime("%Y-%m-%d") if ENV.key?('EXPORT_DATE_OVERRIDE')

      datetime = nil

      if ENV.key?('EXPORT_DATE_OVERRIDE')
        now = Date.today
        # expiration time is 30 days
        for i in 1..30
          done = false

          prefix = [ bucket_path, (now-i).strftime("%Y-%m-%d") ].join( '/' )

          resp = client.list_objects_v2({
            bucket: bucket,
            prefix: prefix
          })

          objects = resp.contents

          if objects.count.zero?
            AuroraBootstrapper.logger.info( message: "No objects in bucket '#{bucket}/#{prefix}'." )
          else
            objects.each do |object|
              if object.key.include? "DONE"
                done = true
                break           
              end
            end

            if done
              datetime = (now-i+1).strftime("%Y-%m-%d")
              break
            end
          end
        end

        # the first run for the given db partition
        if datetime.nil?
          datetime = now.strftime("%Y-%m-%d")
        end
      end

      datetime
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