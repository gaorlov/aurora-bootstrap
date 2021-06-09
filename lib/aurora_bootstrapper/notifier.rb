require 'aws-sdk-s3'

module AuroraBootstrapper
  class Notifier
    def initialize( stub_responses: false )
      region              = ENV.fetch( 'REGION', 'us-west-2')
      @s3_client          = stub_responses ? Aws::S3::Client.new(stub_responses: true) : Aws::S3::Client.new(region: region)
    end

    def push_state?( export_date:, into_bucket: )

      # remove the last subfolder which contains db partition name and the prefix s3://
      index = into_bucket.rindex('/')
      if index > 5
        into_bucket = into_bucket[5..index-1]
      else
        into_bucket = into_bucket[5..-1]
      end

      # append export_date (if there is any) and empty state file DONE.txt
      path = [into_bucket, export_date, 'DONE.txt' ].compact.join('/')
      index = path.index('/')
      bucket_name = path[0, index]
      object_key = path[index + 1..-1]

      if object_uploaded?(bucket_name, object_key)
        AuroraBootstrapper.logger.info( message: "State file has been uploaded to S3 bucket '#{bucket_name}/#{object_key}'." )
        true
      else
        AuroraBootstrapper.logger.info( message: "State file fails in being uploaded to S3 bucket '#{bucket_name}#{object_key}'." )
        false
      end
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