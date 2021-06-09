require 'aws-sdk-s3'

module AuroraBootstrapper
  class Notifier
    def initialize( s3_client )
      @s3_client          = s3_client
      d                   = DateTime.now
      d_str               = d.strftime("%Y-%m-%d")
      @export_date        = ENV.fetch( 'EXPORT_DATE', d_str )
    end

    def push_state?( into_bucket: )

      # remove the last subfolder which contains db partition name and the prefix s3://
      index = into_bucket.rindex('/')
      if index > 5
        into_bucket = into_bucket[5..index-1]
      else
        into_bucket = into_bucket[5..-1]
      end

      # append export_date (if there is any) and empty state file DONE.txt
      path = [into_bucket, @export_date, 'DONE.txt' ].compact.join('/')
      index = path.index('/')
      bucket_name = path[0, index]
      object_key = path[index + 1..-1]

      result = false
    #   if @s3_client
    #     if object_uploaded?(bucket_name, object_key)
    #       AuroraBootstrapper.logger.info( message: "State file has been uploaded to S3 bucket '#{bucket_name}/#{object_key}'." )
    #       result = true
    #     else
    #       AuroraBootstrapper.logger.info( message: "State file fails in being uploaded to S3 bucket '#{bucket_name}#{object_key}'." )
    #     end
    #   else
    #     AuroraBootstrapper.logger.info( message: "No need to save state file in the S3 bucket '#{bucket_name}/#{object_key}'." )
    #     result = true
    #   end

      response = @s3_client.put_object(
        bucket: bucket_name,
        key: object_key
      )

      if response.etag
        AuroraBootstrapper.logger.info( message: "State file has been uploaded to S3 bucket '#{bucket_name}/#{object_key}'." )
        result = true
      else
        result = false
      end

      result
    end

    def object_uploaded?( bucket_name, object_key )
      response = @s3_client.put_object(
        bucket: bucket_name,
        key: object_key
      )

      if response.etag
        true
      else
        false
      end
    rescue => e
      AuroraBootstrapper.logger.fatal( mesasge: "State file fails in being uploaded to S3 bucket '#{bucket_name}#{object_key}'.",  error: e )
      false
    end
  end
end