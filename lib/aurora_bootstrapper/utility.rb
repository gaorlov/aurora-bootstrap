module AuroraBootstrapper
  class Utility
    class << self
      def db_pass
        ENV.fetch( 'DB_PASS' ) do
          File.open( ENV.fetch( 'DB_CRED_FILE' ) ).read
        end
      end

      def db_user
        ENV.fetch( 'DB_USER' ) do
          File.open( ENV.fetch( 'DB_USER_FILE' ) ).read
        end
      end

      def rollbar_token
        ENV.fetch( 'ROLLBAR_TOKEN' ) do
          File.open( ENV.fetch( 'ROLLBAR_TOKEN_FILE' ) ).read
        end
      end
    end
  end
end
