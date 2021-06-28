module AuroraBootstrapper
    class S3file
      MB_IN_BYTES            = 1048576
      CONTENT_LENGTH_PAYLOAD = 1/512
  
      def initialize( file_name:, bucket:, client:, csv_chunk_size: 10 )
        @client         = client
        @bucket         = bucket
        @file_name      = file_name
        @csv_chunk_size = csv_chunk_size
      end
  
      def body( part_number: 0, size_in_mb: @csv_chunk_size )
        range = range_header( part_number: part_number, size_in_mb: size_in_mb )
        object( range: range ).body.read
      end
  
      def number_of_parts
        @number_of_parts ||= ( content_length * 1.0 / ( MB_IN_BYTES * @csv_chunk_size ) ).ceil
      end
  
      def content_length
        @content_length ||= begin
          range = range_header( part_number: 0, size_in_mb: CONTENT_LENGTH_PAYLOAD )
  
          object( range: range ).content_length
        end
      end
  
      def object( range: "" )
        @client.get_object( bucket: @bucket,
                               key: @file_name,
                             range: range )
      end
  
      def range_header( part_number:, size_in_mb: @csv_chunk_size )
        start = part_number * size_in_mb * MB_IN_BYTES
        stop  = start + size_in_mb * MB_IN_BYTES
  
        "bytes=#{start.floor}-#{stop.floor}"
      end
  
      def to_h
        {      bucket: @bucket,
            file_name: @file_name,
       csv_chunk_size: @csv_chunk_size }
      end
    end
  end