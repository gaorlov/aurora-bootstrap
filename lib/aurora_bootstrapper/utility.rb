module AuroraBootstrapper
  class Utility
    def self.get_db_pass
      db_pass = nil

      if ENV.key?('DB_PASS')
        # read from ENV directly
        db_pass = ENV.fetch( 'DB_PASS')
      else
        file_object = File.open(ENV.fetch( 'DB_CRED_FILE' ))
        # read from file stored in e.g. Vault etc
        db_pass = file_object.read
      end

      db_pass
    end

    def self.get_db_user
      db_user = nil

      if ENV.key?('DB_USER')
        # read from ENV directly
        db_user = ENV.fetch( 'DB_USER')
      else
        file_object = File.open(ENV.fetch( 'DB_USER_FILE' ))
        # read from file stored in e.g. Vault etc
        db_user = file_object.read
      end

      db_user
    end

    def self.get_rollbar_token
      rollbar_token = nil

      if ENV.key?('ROLLBAR_TOKEN')
        # read from ENV directly
        rollbar_token = ENV.fetch( 'ROLLBAR_TOKEN')
      else
        file_object = File.open(ENV.fetch( 'ROLLBAR_TOKEN_FILE' ))
        # read from file stored in e.g. Vault etc
        rollbar_token = file_object.read
      end

      rollbar_token
    end
  end
end
