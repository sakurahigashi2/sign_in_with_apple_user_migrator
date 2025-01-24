require 'spec_helper'
require 'webmock/rspec'

RSpec.describe SignInWithAppleUserMigrator::AccessTokenGenerator do
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:generator) { described_class.new(client_id: client_id, client_secret: client_secret) }
  let(:token_url) { 'https://appleid.apple.com/auth/token' }

  describe '#get_access_token' do
    context 'when the request is successful' do
      before do
        stub_request(:post, token_url)
          .with(
            body: {
              client_id: client_id,
              client_secret: client_secret,
              grant_type: 'client_credentials',
              scope: 'user.migration'
            },
            headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
          )
          .to_return(
            status: 200,
            body: { access_token: 'dummy_access_token' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'should successfully retrieve the access token' do
        expect(generator.get_access_token).to eq 'dummy_access_token'
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, token_url)
          .to_return(
            status: 400,
            body: { error: 'invalid_request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'should raise an AuthorizationError' do
        expect { generator.get_access_token }
          .to raise_error(SignInWithAppleUserMigrator::AuthorizationError)
      end
    end
  end
end
