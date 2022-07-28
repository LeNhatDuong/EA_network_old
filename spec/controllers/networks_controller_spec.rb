require "rails_helper"

describe NetworksController do
  describe 'GET manual_update' do
    let(:response_body) { JSON(response.body) }

    context 'Invalid password' do
      let(:expected_result) { { "success" => false, "message" => "Invalid password" } }

      it 'should return json error' do
        get :manual_update, password: "Invalid password"

        expect(response_body).to eq expected_result
      end
    end

    context 'Valid password' do
      let(:password) { 'password' }
      let(:client_ip) { Faker::Internet.ip_v4_address }
      let(:manual_update) { double }
      let(:message) { "Message returned after trying to manually update" }
      let(:expected_result) { { "success" => true, "message" => message } }

      it 'should render json' do
        expect(ManualUpdate).to receive(:authenticate_to_update?).with(password).and_return(true)

        expect(request).to receive(:remote_ip).and_return(client_ip)
        expect(ManualUpdate).to receive(:new).with(client_ip).and_return(manual_update)
        expect(manual_update).to receive(:perform).and_return(message)

        get :manual_update, password: password

        expect(response_body).to eq expected_result
      end
    end
  end
end
