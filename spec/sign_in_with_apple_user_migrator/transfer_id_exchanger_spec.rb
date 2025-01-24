require 'spec_helper'
require_relative '../../lib/sign_in_with_apple_user_migrator/transfer_id_exchanger'

RSpec.describe SignInWithAppleUserMigrator::TransferIdExchanger do
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:access_token) { 'test_access_token' }
  let(:transfer_sub) { 'test_transfer_sub' }

  let(:exchanger) do
    described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      access_token: access_token
    )
  end

  describe '#migrate' do
    context 'when the request is successful' do
      before do
        success_response = double(
          code: '200',
          body: {
            sub: 'user123',
            email: 'test@example.com',
            is_private_email: true
          }.to_json
        )

        allow(Net::HTTP).to receive(:start).and_return(success_response)
      end

      it 'returns user information' do
        transfer_id, sub, email, is_private_email, error = exchanger.migrate(transfer_sub)

        expect(transfer_id).to eq('test_transfer_sub')
        expect(sub).to eq('user123')
        expect(email).to eq('test@example.com')
        expect(is_private_email).to be true
        expect(error).to be_nil
      end
    end

    context 'when the request fails' do
      before do
        error_response = double(
          code: '400',
          body: {
            error: 'invalid_request',
            error_description: 'Invalid transfer_sub'
          }.to_json
        )

        allow(Net::HTTP).to receive(:start).and_return(error_response)
      end

      it 'returns error information' do
        transfer_id, sub, email, is_private_email, error = exchanger.migrate(transfer_sub)

        expect(transfer_id).to eq('test_transfer_sub')
        expect(sub).to be_nil
        expect(email).to be_nil
        expect(is_private_email).to be_nil
        expect(error).to include('Invalid transfer_sub')
      end
    end
  end
end
