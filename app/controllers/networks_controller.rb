class NetworksController < ApplicationController
  #before_action :require_password, only: [:manual_update]

  def manual_update
    manual_update = ManualUpdate.new(request.remote_ip)

    render json: { success: true, message: manual_update.perform }
  end

  #private
  #def require_password
  #  unless ManualUpdate.authenticate_to_update?(params[:password])
  #    return render json: { success: false, message: "Invalid password" }
  #  end
  #end
end
