require 'test_helper'

class NotifierTest < Minitest::Test
  def setup
    @bukkit               = ENV.fetch "EXPORT_BUCKET"

    stubbed_objs = {
      contents: [
        { key: 'DONE.txt' },
      ]
    }
    @stub_client = Aws::S3::Client.new(stub_responses: {
      put_object: { etag: 'etag_id' },
      list_objects_v2: stubbed_objs,
    })
  end

  def test_export_date
    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( @stub_client )

    export_date = ENV.fetch "EXPORT_DATE"
    assert_equal export_date, AuroraBootstrapper::Notifier.new(s3_path: @bukkit).export_date
  end

  def test_notifier_with_no_s3_path
    assert_raises ArgumentError do
      AuroraBootstrapper::Notifier.new
    end
  end

  def test_exists_export_with_done_file
    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( @stub_client )
    someday = Date.new(2021, 6, 1)
    assert AuroraBootstrapper::Notifier.new(s3_path: @bukkit).exists_export?(date: someday)
  end

  def test_exists_export_with_zero_file
    stubbed_objs = {
    }
    local_stub_client = Aws::S3::Client.new(stub_responses: {
      list_objects_v2: stubbed_objs,
    })

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( local_stub_client )
    someday = Date.new(2021, 6, 1)
    assert !AuroraBootstrapper::Notifier.new(s3_path: @bukkit).exists_export?(date: someday)
  end

  def test_exists_export_without_done_file
    stubbed_objs = {
      contents: [
        { key: 'other.txt' },
      ]
    }
    local_stub_client = Aws::S3::Client.new(stub_responses: {
      list_objects_v2: stubbed_objs,
    })

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( local_stub_client )
    assert !AuroraBootstrapper::Notifier.new(s3_path: @bukkit).exists_export?(date: DateTime.now-1)
  end

  def test_export_date_override_with_done_file
    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( @stub_client )
    assert_equal DateTime.now.strftime("%Y-%m-%d"), AuroraBootstrapper::Notifier.new(s3_path: @bukkit).export_date_override
  end

  def test_export_date_override_without_done_file
    stubbed_objs = {
      contents: [
        { key: 'other.txt' },
      ]
    }
    local_stub_client = Aws::S3::Client.new(stub_responses: {
      list_objects_v2: stubbed_objs,
    })

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( local_stub_client )
    someday = Date.new(2021, 6, 1)
    Date.stub :today, someday do
      assert_equal someday.strftime("%Y-%m-%d"), AuroraBootstrapper::Notifier.new(s3_path: @bukkit).export_date_override
    end
  end

  def test_no_export_date_with_export_date_override
    export_date = ENV.fetch "EXPORT_DATE"
    ENV.delete("EXPORT_DATE")

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( @stub_client )

    someday = Date.new(2021, 6, 1)
    Date.stub :today, someday do
      assert_equal someday.strftime("%Y-%m-%d"), AuroraBootstrapper::Notifier.new(s3_path: @bukkit).export_date
    end
    ENV["EXPORT_DATE"] = export_date
  end

  def test_no_export_date_with_no_export_date_override
    export_date = ENV.fetch "EXPORT_DATE"
    ENV.delete("EXPORT_DATE")
    ENV.delete("EXPORT_DATE_OVERRIDE")
    assert_nil AuroraBootstrapper::Notifier.new(s3_path: @bukkit).export_date
    ENV["EXPORT_DATE"] = export_date
    ENV["EXPORT_DATE_OVERRIDE"] = "true"
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
    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( @stub_client )

    export_date = ENV.fetch "EXPORT_DATE"
    assert_equal "blah1/blah2/#{export_date}/DONE.txt", AuroraBootstrapper::Notifier.new(s3_path: "s3://bukkit/blah1/blah2").send(:object_key)
  end

  def test_notify_happy_path
    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( @stub_client )

    with_logger PutsLogger.new do
      assert_output( /State file has been uploaded to S3/ ) do
        AuroraBootstrapper::Notifier.new(s3_path: @bukkit).notify
      end
    end
  end

  def test_notify_sad_path
    stubbed_objs = {
      contents: [
        { key: 'DONE.txt' },
      ]
    }
    local_stub_client = Aws::S3::Client.new(stub_responses: {
      put_object: RuntimeError.new('custom message'),
      list_objects_v2: stubbed_objs,
    })

    AuroraBootstrapper::Notifier.any_instance.stubs( :client ).returns( local_stub_client )

    with_logger PutsLogger.new do
      assert_output( /State file failed to upload to S3/ ) do
        AuroraBootstrapper::Notifier.new(s3_path: @bukkit).notify
      end
    end
  end
end