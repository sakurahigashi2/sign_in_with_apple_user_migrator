require_relative 'base'

module SignInWithAppleUserMigrator
  class AccessTokenGenerator < Base
    def initialize(client_id:, client_secret:)
      @client_id   = client_id
      @client_secret = client_secret
      super()
    end

    ##
    # Retrieves an access token from Apple's authentication servers
    #
    # @param [String] grant_type The type of grant to request (default: 'client_credentials')
    # @param [String] scope The requested scope for the access token (default: 'user.migration')
    #
    # @return [String] The access token string from Apple's authentication server
    #
    # @example
    #   generator = AccessTokenGenerator.new
    #   token = generator.get_access_token
    #   # => "eyJhbGciOiJIUzI1NiIsInR5cCI6Ikp..."
    #
    # @raise [StandardError] If the token request fails
    #
    def get_access_token(grant_type: 'client_credentials', scope: 'user.migration')
      logger.debug 'Retrieving access token...'

      uri = URI('https://appleid.apple.com/auth/token')
      params = {
        'client_id' => @client_id,
        'client_secret' => @client_secret,
        'grant_type' => grant_type,
        'scope' => scope,
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request.body = URI.encode_www_form(params)

      response = http.request(request)

      if response.code != '200'
        logger.error "HTTP Status: #{response.code}"
        logger.error "Response HEADER: #{response.to_hash}"
        raise AuthorizationError.new <<~LOG
          Failed to retrieve access token.
          HTTP Status: #{response.code}
          Response HEADER: #{response.to_hash}
          error: #{response.inspect}
        LOG
      else
        logger.debug response.body
        JSON.parse(response.body)['access_token']
      end
    end
  end
end
