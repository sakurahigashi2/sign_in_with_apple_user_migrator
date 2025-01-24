require_relative 'base'

module SignInWithAppleUserMigrator
  class TransferIdExchanger < Base
    def initialize(client_id:, client_secret:, access_token:)
      @client_id   = client_id
      @client_secret = client_secret
      @access_token = access_token
      super()
    end

    ##
    # Exchanges a transfer_id for user information in Sign in with Apple user migration process.
    #
    # @param transfer_id [String] The transfer_id obtained from the source team
    #
    # @return [Array<String, String, String, Boolean, String>]
    #   Success: [transfer_id, sub, email, is_private_email, nil]
    #   Failure: [transfer_id, nil, nil, nil, error_message]
    #
    # @example
    #   exchanger = TransferIdExchanger.new(
    #     client_id: 'your_client_id',
    #     client_secret: 'your_client_secret',
    #     access_token: 'your_access_token'
    #   )
    #   transfer_id, sub, email, is_private_email, error = exchanger.migrate('transfer_id')
    #
    # @raise [JSON::ParserError] When JSON parsing of response fails
    #
    # @see https://developer.apple.com/documentation/sign_in_with_apple/transferring_your_apps_and_users_to_another_team
    #
    def migrate(transfer_id)
      logger.debug "Migrate transfer_id for #{transfer_id}"

      request_data = {
        'transfer_sub' => transfer_id,
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
        logger.error "Failed to exchange transfer_id: #{error_message}"
        return [transfer_id, nil, nil, nil, error_message]
      end

      sub = result['sub']
      email = result['email']
      is_private_email = result['is_private_email']
      logger.info "Success to migrate sub: #{transfer_id}"
      [transfer_id, sub, email, is_private_email, nil]
    end
  end
end
