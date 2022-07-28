class GatewaysController < ApplicationController
  def update
    if gateway = Gateway.find_by(name: params[:gateway_name])
      gateway.add_speed_result(params.slice(:gateway_name, :result, :mode))
    end

    render nothing: true
  end

  def send_alert
    gateway_names = Gateway.available_gateway_names
    if gateway_names.present?
      unless gateway_names == Gateway::NAMES
        system("#{File.join(Rails.root, "script", "change_gateway")} #{gateway_names.first}")
      end
    else
      Rails.logger.error("All gateways are not working! Cannot send email.")
    end

    render :nothing => true
  end
end
