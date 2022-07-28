require "rails_helper"

describe ChartsController do
  describe 'GET index' do
    let(:response_body) { JSON(response.body).symbolize_keys }
    let(:expected_result) { { success: true, data: data, gateways: Gateway::NAMES_WITH_IP } }
    let(:data) { {} }

    before do
      expect(Gateway).to receive(:latest_results).and_return(data)
    end

    it 'should render json' do
      get :index
      expect(response_body).to eq expected_result
    end
  end

  describe 'GET filter' do
    let(:from) { 1.day.ago.to_s }
    let(:to) { Time.now.to_s }
    let(:params) { { start: from, end: to, selected_gateway: Gateway.first.id.to_s} }

    let(:gateway_performance) { GatewayPerformance.new(params[:start], params[:end], params[:selected_gateway]) }
    let(:data) { [] }
    let(:performance_results) { { type: GatewayPerformance::SINGLE_CHART, error: "", data: data } }

    let(:response_body) { JSON(response.body).symbolize_keys }
    let(:expected_result) { performance_results.merge(success: true) }

    before do
      expect(GatewayPerformance).to receive(:new).with(params[:start], params[:end], params[:selected_gateway]).and_return(gateway_performance)
      expect(gateway_performance).to receive(:results).and_return(performance_results)
    end

    it 'should render performance_results json' do
      get :filter, params

      expect(response_body).to eq expected_result
    end
  end
end
