require "rails_helper"

describe GatewaysController do
  describe 'GET update' do
    let(:gateway) { Gateway.first }
    let(:params) { { "gateway_name" => gateway.name, "result" => "Result of speedtest" } }

    before do
      expect(Gateway).to receive(:find_by).with(name: gateway.name).and_return(gateway)
      expect(gateway).to receive(:add_speed_result).with(params)
    end

    it 'should render nothing' do
      get :update, params

      expect(response.body).to be_blank
    end
  end

  describe 'GET send_alert' do
    context 'Available gateways present' do
      it 'should call change_gateway if available gateways are not the same as Gateway::NAMES list' do
        expect(Gateway).to receive(:available_gateway_names).and_return Gateway::NAMES.slice(0, 2)
        expect(controller).to receive(:system)

        get :send_alert
      end
    end

    context 'No available gateways' do
      it 'should log to Rails log' do
        expect(Gateway).to receive(:available_gateway_names).and_return []
        expect(Rails).to receive(:logger).and_return(logger = double)
        expect(logger).to receive(:error).with("All gateways are not working! Cannot send email.")

        get :send_alert
      end
    end

    it 'should render nothing' do
      get :send_alert

      expect(response.body).to be_blank
    end
  end
end
