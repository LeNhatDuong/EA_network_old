class ManualUpdate
  def initialize(request_ip)
    @request_ip = request_ip
  end

  def perform
    auto_update_check = ManualUpdate.check_auto_update

    return auto_update_check[:message] unless auto_update_check[:updatable]
    return "The result was updated few minutes ago" unless ManualUpdate.can_update?

    perform_manual_update
    return "Manual updating is activated"
  end

  def self.authenticate_to_update?(password)
    password == Constant::PASSWORD_UPDATE
  end

  def self.can_update?
    return true unless ManualUpdateLog.count > 0

    duration = (Time.current - ManualUpdateLog.last.created_at) / 60
    duration < 10 ? false : true
  end

  def self.check_auto_update
    if Time.current.min < 10
      { updatable: false, message: "Auto updating is on process, manual mode is disabled" }
    elsif Time.current.min > 50
      { updatable: false, message: "Auto updating will be activated soon, manual mode is disabled" }
    else
      { updatable: true, message: "Can proceed to manual update" }
    end
  end

  private
  def perform_manual_update
    HardWorker.perform_async
    ManualUpdateLog.create(client_ip: @request_ip)
  end
end
