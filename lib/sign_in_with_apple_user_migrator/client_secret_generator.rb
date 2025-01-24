require_relative 'base'

module SignInWithAppleUserMigrator
  class ClientSecretGenerator < Base
    def initialize(client_id:, key_id:, private_key_path:, team_id:)
      @client_id   = client_id
      @key_id      = key_id
      @private_key = File.read(private_key_path)
      @team_id     = team_id
      super()
    end

    ##
    # Generates a JSON Web Token (JWT) for Sign in with Apple authentication (client_secret).
    #
    # @param [Integer] iat The issued at time (default: current Unix timestamp)
    # @param [Integer] exp The expiration time (default: current time + 1 hour)
    #
    # @return [String] A signed JWT token that can be used as client_secret
    #
    # @example
    #   generator = ClientSecretGenerator.new
    #   jwt = generator.generate_client_secret
    #   # => "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1..."
    #
    # @see https://developer.apple.com/documentation/accountorganizationaldatasharing/creating-a-client-secret
    #
    def generate_client_secret(iat: Time.now.to_i, exp: Time.now.to_i + 3600)
      header = {
        'kid' => @key_id,
        'alg' => 'ES256',
      }

      payload = {
        'iss' => @team_id,
        'iat' => iat,
        'exp' => exp,
        'aud' => 'https://appleid.apple.com',
        'sub' => @client_id,
      }

      JWT.encode(payload, OpenSSL::PKey::EC.new(@private_key), 'ES256', header)
    end
  end
end
