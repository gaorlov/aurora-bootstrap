module AuroraBootstrapper
  class Utility
    class << self
      def db_pass
        from_env 'DB_PASS'
      end
          
      def db_user
        from_env 'DB_USER'
      end
        
      def rollbar_token
        from_env 'ROLLBAR_TOKEN'
      end
          
      private
          
      def from_env( var )
        ENV.fetch( var ) do
          File.open( ENV.fetch( "#{var}_FILE" ) ).read
        end
      end
    end
  end
end
