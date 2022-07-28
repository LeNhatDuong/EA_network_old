class ChartsController < ApplicationController
  def index
    render json: { success: true, data: Gateway.latest_results, gateways: Gateway::NAMES_WITH_IP }
  end

  def filter
    gateway_performance = GatewayPerformance.new(params[:start], params[:end], params[:selected_gateway]).results

    render json: gateway_performance.merge(success: true)
  end
end
