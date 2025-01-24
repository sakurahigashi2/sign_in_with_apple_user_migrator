require 'spec_helper'

RSpec.describe SignInWithAppleUserMigrator::ClientSecretGenerator do
  let(:client_id) { 'com.example.app' }
  let(:key_id) { 'TEST123456' }
  let(:team_id) { 'TEAM123456' }
  let(:private_key_path) { '/path/to/private_key.p8' }
  let(:private_key) do
    OpenSSL::PKey::EC.generate('prime256v1').to_pem
  end
  let(:fixed_time) { Time.utc(2024, 1, 1, 0, 0, 0) }

  before do
    allow(File).to receive(:read).with(private_key_path).and_return(private_key)
    allow(Time).to receive(:now).and_return(fixed_time)
  end

  describe '#initialize' do
    it 'should initialize correctly' do
      generator = described_class.new(
        client_id: client_id,
        key_id: key_id,
        private_key_path: private_key_path,
        team_id: team_id
      )
      expect(generator).to be_a(described_class)
    end
  end

  describe '#generate_client_secret' do
    let(:generator) do
      described_class.new(
        client_id: client_id,
        key_id: key_id,
        private_key_path: private_key_path,
        team_id: team_id
      )
    end

    let(:decoded_token) do
      token = generator.generate_client_secret
      JWT.decode(
        token,
        OpenSSL::PKey::EC.new(private_key),
        true,
        algorithm: 'ES256'
      )
    end

    it 'should generate a valid JWT token' do
      expect(generator.generate_client_secret).to be_a(String)
    end

    it 'should contain valid header information' do
      header = decoded_token[1]
      expect(header['kid']).to eq(key_id)
      expect(header['alg']).to eq('ES256')
    end

    it 'should contain valid payload information' do
      payload = decoded_token[0]
      expect(payload['iss']).to eq(team_id)
      expect(payload['iat']).to eq(fixed_time.to_i)
      expect(payload['exp']).to eq(fixed_time.to_i + 3600)
      expect(payload['aud']).to eq('https://appleid.apple.com')
      expect(payload['sub']).to eq(client_id)
    end
  end
end
