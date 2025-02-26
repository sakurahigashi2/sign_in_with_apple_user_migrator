require 'csv'
require 'fileutils'
require 'thor'
require_relative '../sign_in_with_apple_user_migrator'

module SignInWithAppleUserMigrator
  class CLI < Thor
    COMMON_OPTIONS = {
      client_id: { required: true, desc: 'Client ID' },
      key_id: { required: true, desc: 'Key ID' },
      private_key_path: { required: true, desc: 'Private Key Path' },
      team_id: { required: true, desc: 'Team ID' }
    }

    desc 'generate_user_transfer_ids', 'Generate user transfer IDs'
    COMMON_OPTIONS.each { |name, opts| option(name, opts) }
    option :transfer_user_id_csv_path, required: true, desc: 'Transfer User ID CSV Path'
    option :target_team_id, required: true, desc: 'Target Team ID'

    def generate_user_transfer_ids
      token_manager = TokenManager.new(**common_options)
      transfer_user_id_csv_path = options[:transfer_user_id_csv_path]
      target_team_id = options[:target_team_id]

      FileUtils.mkdir_p('tmp')
      result_csv_name = "generated_transfer_ids_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
      result_csv_path = File.join('tmp', result_csv_name)
      File.write("tmp/#{result_csv_name}", "user_id,transfer_id,error\n")

      CSV.open(result_csv_path, 'w') do |result_csv|
        result_csv << %w[user_id transfer_id error]

        CSV.foreach(transfer_user_id_csv_path, headers: true) do |row|
          user_id = row['user_id']
          next if user_id.nil? || user_id.empty?

          client_secret, access_token = token_manager.ensure_valid_token
          generator = TransferIdGenerator.new(
            client_id: options[:client_id],
            client_secret: client_secret,
            access_token: access_token,
            target_team_id: target_team_id
          )

          transfer_id, error = generator.generate_transfer_id(user_id)
          result_csv << [user_id, transfer_id, error]
        end
      end

    end

    desc 'migrate_user_transfer_ids', 'Migrate user transfer IDs'
    COMMON_OPTIONS.each { |name, opts| option(name, opts) }
    option :transfer_id_csv_path, required: true, desc: 'Transfer ID CSV Path'

    def migrate_user_transfer_ids
      token_manager = TokenManager.new(**common_options)
      transfer_id_csv_path = options[:transfer_id_csv_path]

      FileUtils.mkdir_p('tmp')
      result_csv_name = "exchanged_transfer_ids_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
      result_csv_path = File.join('tmp', result_csv_name)
      File.write("tmp/#{result_csv_name}", "transfer_id,sub,error\n")

      CSV.open(result_csv_path, 'w') do |result_csv|
        result_csv << %w[transfer_id sub email is_private_email error]

        CSV.foreach(transfer_id_csv_path, headers: true) do |row|
          transfer_id = row['transfer_id']
          next if transfer_id.nil? || transfer_id.empty?

          client_secret, access_token = token_manager.ensure_valid_token
          exchanger = TransferIdExchanger.new(
            client_id: options[:client_id],
            client_secret: client_secret,
            access_token: access_token
          )

          transfer_id, sub, email, is_private_email, error = exchanger.migrate(transfer_id)
          result_csv << [transfer_id, sub, email, is_private_email, error]
        end
      end
    end

    private
      def common_options
        COMMON_OPTIONS.keys.each_with_object({}) do |key, hash|
          hash[key] = options[key]
        end
      end
  end

  class TokenManager
    TOKEN_DURATION = 3600
    TOKEN_REFRESH_THRESHOLD = 300

    def initialize(client_id:, key_id:, private_key_path:, team_id:)
      @client_id = client_id
      @key_id = key_id
      @private_key_path = private_key_path
      @team_id = team_id
      @token_generated_at = nil
      @client_secret = nil
      @access_token = nil
    end

    def ensure_valid_token
      return [@client_secret, @access_token] if valid_token?

      @token_generated_at = Time.now
      @client_secret = generate_client_secret
      @access_token = generate_access_token
      [@client_secret, @access_token]
    end

    private
      def valid_token?
        !@token_generated_at.nil? && (Time.now - @token_generated_at) <= (TOKEN_DURATION - TOKEN_REFRESH_THRESHOLD)
      end

      def generate_client_secret
        SignInWithAppleUserMigrator::ClientSecretGenerator.new(
          client_id: @client_id,
          key_id: @key_id,
          private_key_path: @private_key_path,
          team_id: @team_id
        ).generate_client_secret(iat: @token_generated_at.to_i, exp: @token_generated_at.to_i + TOKEN_DURATION)
      end

      def generate_access_token
        SignInWithAppleUserMigrator::AccessTokenGenerator.new(
          client_id: @client_id,
          client_secret: @client_secret
        ).get_access_token
      end
  end
end
