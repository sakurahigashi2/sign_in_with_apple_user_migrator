require 'spec_helper'
require 'sign_in_with_apple_user_migrator/cli'

RSpec.describe SignInWithAppleUserMigrator::CLI do
  let(:client_id) { 'test.client.id' }
  let(:key_id) { 'KEY123' }
  let(:private_key_path) { 'path/to/key.p8' }
  let(:private_key_content) { 'dummy_private_key_content' }
  let(:team_id) { 'TEAM123' }
  let(:transfer_user_id_csv_path) { 'path/to/users.csv' }
  let(:target_team_id) { 'TARGET123' }
  let(:client_secret) { 'dummy_secret' }
  let(:access_token) { 'dummy_token' }

  describe '#generate_user_transfer_ids' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      allow(CSV).to receive(:open)
      allow(File).to receive(:read).with(private_key_path).and_return(private_key_content)

      allow_any_instance_of(SignInWithAppleUserMigrator::TokenManager)
        .to receive(:ensure_valid_token)
        .and_return([client_secret, access_token])
    end

    it 'creates required directories and files' do
      cli = described_class.new
      options = {
        "client_id" => client_id,
        "key_id" => key_id,
        "private_key_path" => private_key_path,
        "team_id" => team_id,
        "transfer_user_id_csv_path" => transfer_user_id_csv_path,
        "target_team_id" => target_team_id
      }

      cli.options = Thor::CoreExt::HashWithIndifferentAccess.new(options)
      cli.generate_user_transfer_ids

      expect(FileUtils).to have_received(:mkdir_p).with('tmp')
      expect(File).to have_received(:write).with(
        match(/tmp\/generated_transfer_ids_\d{14}\.csv/),
        "user_id,transfer_id,error\n"
      )
    end

    it 'initializes required services with correct parameters' do
      cli = described_class.new
      options = {
        "client_id" => client_id,
        "key_id" => key_id,
        "private_key_path" => private_key_path,
        "team_id" => team_id,
        "transfer_user_id_csv_path" => transfer_user_id_csv_path,
        "target_team_id" => target_team_id
      }

      cli.options = Thor::CoreExt::HashWithIndifferentAccess.new(options)

      expect(SignInWithAppleUserMigrator::TokenManager)
        .to receive(:new)
        .with(
          client_id: client_id,
          key_id: key_id,
          private_key_path: private_key_path,
          team_id: team_id
        )
        .and_call_original

      cli.generate_user_transfer_ids
    end
  end

  describe '#migrate_user_transfer_ids' do
    let(:transfer_id_csv_path) { 'path/to/transfer_ids.csv' }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      allow(CSV).to receive(:open)
      allow(File).to receive(:read).with(private_key_path).and_return(private_key_content)

      allow_any_instance_of(SignInWithAppleUserMigrator::TokenManager)
        .to receive(:ensure_valid_token)
        .and_return([client_secret, access_token])
    end

    it 'creates required directories and files' do
      cli = described_class.new
      options = {
        "client_id" => client_id,
        "key_id" => key_id,
        "private_key_path" => private_key_path,
        "team_id" => team_id,
        "transfer_id_csv_path" => transfer_id_csv_path
      }

      cli.options = Thor::CoreExt::HashWithIndifferentAccess.new(options)
      cli.migrate_user_transfer_ids

      expect(FileUtils).to have_received(:mkdir_p).with('tmp')
      expect(File).to have_received(:write).with(
        match(/tmp\/exchanged_transfer_ids_\d{14}\.csv/),
        "transfer_id,sub,error\n"
      )
    end

    it 'initializes required services with correct parameters' do
      cli = described_class.new
      options = {
        "client_id" => client_id,
        "key_id" => key_id,
        "private_key_path" => private_key_path,
        "team_id" => team_id,
        "transfer_id_csv_path" => transfer_id_csv_path
      }

      cli.options = Thor::CoreExt::HashWithIndifferentAccess.new(options)

      expect(SignInWithAppleUserMigrator::TokenManager)
        .to receive(:new)
        .with(
          client_id: client_id,
          key_id: key_id,
          private_key_path: private_key_path,
          team_id: team_id
        )
        .and_call_original

      cli.migrate_user_transfer_ids
    end
  end
end
