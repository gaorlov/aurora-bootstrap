require 'aws-sdk-s3'

module AuroraBootstrapper
  class Notifier
    def initialize( stub_responses: false )
      region              = ENV.fetch( 'REGION', 'us-west-2')
      @s3_client          = stub_responses ? Aws::S3::Client.new(stub_responses: true) : Aws::S3::Client.new(region: region)
    end

    def push_state?( export_date:, into_bucket: )
      bento = into_bucket[/.*(app1[a-zA-Z])/, 0]
      # hard code the bucket name
      bucket_name = 'us-west-2.outreach-elt'
      # store DONE.txt at the top level of the folder for a given bento and a given day
      object_key = "backfill/#{bento}/#{export_date}/DONE.txt"

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