require_relative 'base'

module SignInWithAppleUserMigrator
  class TransferIdGenerator < Base
    def initialize(client_id:, client_secret:, access_token:, target_team_id:)
      @client_id = client_id
      @client_secret = client_secret
      @target_team_id = target_team_id
      @access_token = access_token
      super()
    end

    ##
    # Generates transfer_id required for Sign in with Apple user migration.
    #
    # @param sub [String] The user identifier (sub) from Sign in with Apple
    #
    # @return [Array<String, String>]
    #   Success: [transfer_id, nil]
    #   Failure: [nil, error_message]
    #
    # @example
    #   generator = TransferIdGenerator.new(
    #     client_id: 'your_client_id',
    #     client_secret: 'your_client_secret',
    #     access_token: 'your_access_token',
    #     target_team_id: 'target_team_id'
    #   )
    #   transfer_id, error = generator.generate_transfer_id('user_sub')
    #
    # @raise [JSON::ParserError] When JSON parsing of response fails
    #
    # @see https://developer.apple.com/documentation/sign_in_with_apple/transferring_your_apps_and_users_to_another_team
    #
    def generate_transfer_id(sub)
      logger.debug "Generated transfer_id for #{sub}"

      request_data = {
        'sub' => sub,
        'target' => @target_team_id,
        'client_id' => @client_id,
        'client_secret' => @client_secret,
      }

      uri = URI('https://appleid.apple.com/auth/usermigrationinfo')
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/x-www-form-urlencoded'
      request['Authorization'] = "Bearer #{@access_token}"

      request.body = URI.encode_www_form(request_data)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      result = JSON.parse(response.body)

      if result['error']
        error_message = "HTTP Status: #{response.code}, Error: #{result.inspect}"
        logger.error "Failed to generate transfer_id: #{error_message}"
        return [nil, error_message]
      end

      transfer_id = result['transfer_sub']
      logger.info "Success to generate transfer_id: #{transfer_id}"
      [transfer_id, nil]
    end
  end
end
