require 'spec_helper'
require_relative '../../lib/sign_in_with_apple_user_migrator/transfer_id_generator'

RSpec.describe SignInWithAppleUserMigrator::TransferIdGenerator do
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:access_token) { 'test_access_token' }
  let(:target_team_id) { 'test_team_id' }
  let(:sub) { 'test_user_sub' }

  let(:generator) do
    described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      access_token: access_token,
      target_team_id: target_team_id
    )
  end

  describe '#generate_transfer_id' do
    context 'when the request is successful' do
      before do
        success_response = double(
          code: '200',
          body: {
            transfer_sub: 'test_transfer_sub'
          }.to_json
        )

        allow(Net::HTTP).to receive(:start).and_return(success_response)
      end

      it 'returns transfer_id' do
        transfer_id, error = generator.generate_transfer_id(sub)

        expect(transfer_id).to eq('test_transfer_sub')
        expect(error).to be_nil
      end
    end

    context 'when the request fails' do
      before do
        error_response = double(
          code: '400',
          body: {
            error: 'invalid_request',
            error_description: 'Invalid sub'
          }.to_json
        )

        allow(Net::HTTP).to receive(:start).and_return(error_response)
      end

      it 'returns error information' do
        transfer_id, error = generator.generate_transfer_id(sub)

        expect(transfer_id).to be_nil
        expect(error).to include('Invalid sub')
      end
    end

    context 'when JSON parsing fails' do
      before do
        invalid_response = double(
          code: '200',
          body: 'invalid json'
        )

        allow(Net::HTTP).to receive(:start).and_return(invalid_response)
      end

      it 'raises JSON::ParserError' do
        expect {
          generator.generate_transfer_id(sub)
        }.to raise_error(JSON::ParserError)
      end
    end
  end
end
