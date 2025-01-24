require 'csv'
require 'fileutils'
require 'thor'
require_relative '../sign_in_with_apple_user_migrator'

module SignInWithAppleUserMigrator
  class CLI < Thor
    desc 'generate_user_transfer_ids', 'Generate user transfer IDs'
    option :client_id, required: true, desc: 'Client ID'
    option :key_id, required: true, desc: 'Key ID'
    option :private_key_path, required: true, desc: 'Private Key Path'
    option :team_id, required: true, desc: 'Team ID'
    option :transfer_user_id_csv_path, required: true, desc: 'Transfer User ID CSV Path'
    option :target_team_id, required: true, desc: 'Target Team ID'

    def generate_user_transfer_ids
      client_id = options[:client_id]
      key_id = options[:key_id]
      private_key_path = options[:private_key_path]
      team_id = options[:team_id]
      transfer_user_id_csv_path = options[:transfer_user_id_csv_path]
      target_team_id = options[:target_team_id]

      client_secret = SignInWithAppleUserMigrator::ClientSecretGenerator.new(
        client_id: client_id,
        key_id: key_id,
        private_key_path: private_key_path,
        team_id: team_id,
      ).generate_client_secret

      access_token = SignInWithAppleUserMigrator::AccessTokenGenerator.new(
        client_id: client_id,
        client_secret: client_secret,
      ).get_access_token

      transfer_id_generator_client = SignInWithAppleUserMigrator::TransferIdGenerator.new(
        client_id: client_id,
        client_secret: client_secret,
        access_token: access_token,
        target_team_id: target_team_id,
      )

      FileUtils.mkdir_p('tmp')
      result_csv_name = "generated_transfer_ids_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
      result_path = File.join('tmp', result_csv_name)
      File.write("tmp/#{result_csv_name}", "user_id,transfer_id,error\n")

      CSV.open(result_path, 'w') do |csv|
        csv << %w[user_id transfer_id error]

        CSV.foreach(transfer_user_id_csv_path, headers: true) do |row|
          user_id = row['user_id']
          next if user_id.nil? || user_id.empty?

          transfer_id, error = transfer_id_generator_client.generate_transfer_id(user_id)
          csv << [user_id, transfer_id, error]
        end
      end
    end

    desc 'migrate_user_transfer_ids', 'Migrate user transfer IDs'
    option :client_id, required: true, desc: 'Client ID'
    option :key_id, required: true, desc: 'Key ID'
    option :private_key_path, required: true, desc: 'Private Key Path'
    option :team_id, required: true, desc: 'Team ID'
    option :transfer_id_csv_path, required: true, desc: 'Transfer ID CSV Path'

    def migrate_user_transfer_ids
      client_id = options[:client_id]
      key_id = options[:key_id]
      private_key_path = options[:private_key_path]
      team_id = options[:team_id]
      transfer_id_csv_path = options[:transfer_id_csv_path]

      client_secret = SignInWithAppleUserMigrator::ClientSecretGenerator.new(
        client_id: client_id,
        key_id: key_id,
        private_key_path: private_key_path,
        team_id: team_id,
      ).generate_client_secret

      access_token = SignInWithAppleUserMigrator::AccessTokenGenerator.new(
        client_id: client_id,
        client_secret: client_secret,
      ).get_access_token

      transfer_id_exchanger_client = SignInWithAppleUserMigrator::TransferIdExchanger.new(
        client_id: client_id,
        client_secret: client_secret,
        access_token: access_token,
      )

      FileUtils.mkdir_p('tmp')
      result_csv_name = "exchanged_transfer_ids_#{Time.now.strftime('%Y%m%d%H%M%S')}.csv"
      result_path = File.join('tmp', result_csv_name)
      File.write("tmp/#{result_csv_name}", "transfer_id,sub,error\n")

      CSV.open(result_path, 'w') do |csv|
        csv << %w[transfer_id sub email is_private_email error]

        CSV.foreach(transfer_id_csv_path, headers: true) do |row|
          transfer_id = row['transfer_id']
          next if transfer_id.nil? || transfer_id.empty?

          transfer_id, sub, email, is_private_email, error = transfer_id_exchanger_client.migrate(transfer_id)
          csv << [transfer_id, sub, email, is_private_email, error]
        end
      end
    end
  end
end
