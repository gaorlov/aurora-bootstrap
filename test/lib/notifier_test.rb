require 'test_helper'

class NotifierTest < Minitest::Test
  def setup
    @bukkit               = ENV.fetch "EXPORT_BUCKET"
  end

  def test_export_date
    export_date = ENV.fetch "EXPORT_DATE"
    assert_equal export_date, AuroraBootstrapper::Notifier.new(s3_path: @bukkit).export_date
  end

  def test_region
    region = ENV.fetch "REGION"
    assert_equal region, AuroraBootstrapper::Notifier.new(s3_path: @bukkit).send(:region)
  end

  def test_unprefixed_path
    assert_equal "bukkit/blah1/blah2", AuroraBootstrapper::Notifier.new(s3_path: "s3://bukkit/blah1/blah2").send(:unprefixed_path)
  end

  def test_bucket
    assert_equal "bukkit", AuroraBootstrapper::Notifier.new(s3_path: "s3://bukkit/blah1/blah2").send(:bucket)
  end

  def test_filename
    assert_equal "DONE.txt", AuroraBootstrapper::Notifier.new(s3_path: @bukkit).send(:filename)
  end

  def test_bucket_path
    assert_equal "blah1/blah2", AuroraBootstrapper::Notifier.new(s3_path: "s3://bukkit/blah1/blah2").send(:bucket_path)
  end

  def test_object_key
    export_date = ENV.fetch "EXPORT_DATE"
    assert_equal "blah1/blah2/#{export_date}/DONE.txt", AuroraBootstrapper::Notifier.new(s3_path: "s3://bukkit/blah1/blah2").send(:object_key)
  end

  def test_notify_happy_path
    stub_client = Aws::S3::Client.new(stub_responses: {
        put_object: { etag: 'etag_id' },
      })

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( stub_client )

    with_logger PutsLogger.new do
      assert_output( /State file has been uploaded to S3/ ) do
        AuroraBootstrapper::Notifier.new(s3_path: @bukkit).notify
      end
    end
  end

  def test_notify_sad_path
    stub_client = Aws::S3::Client.new(stub_responses: true)

    stub_client.stub_responses(:put_object, RuntimeError.new('custom message'))

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( stub_client )

    with_logger PutsLogger.new do
      assert_output( /State file failed to upload to S3/ ) do
        AuroraBootstrapper::Notifier.new(s3_path: @bukkit).notify
      end
    end
  end
end