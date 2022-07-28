class Gateway < ActiveRecord::Base

  NAMES = Rails.configuration.gateway_names
  NAMES_WITH_IP = Rails.configuration.gateway_names_with_ip
  UPLOAD_MANUAL_MODE = 'manual'

  has_many :results
  has_many :manual_results

  validates :name, inclusion: NAMES

  default_scope { order(:ip) }

  def self.all_gateway_current_time_results(gateway_id = nil)
    if gateway_id.present?
      gateway = Gateway.find_by id: gateway_id
      gateway.present? ? [{ name: gateway.name, performances: gateway.current_time_results }] : []
    else
      Gateway.all.inject([]) do |result, gateway|
        result << { name: gateway.name, performances: gateway.current_time_results }
      end
    end
  end

  def self.all_gateway_results_in_duration(from, to, gateway_id = nil)
    if gateway_id.present?
      gateway = Gateway.find_by id: gateway_id
      gateway.present? ? [{ name: gateway.name, performances: gateway.results_in_duration(from, to) }] : []
    else
      Gateway.all.inject([]) do |result, gateway|
        result << { name: gateway.name, performances: gateway.results_in_duration(from, to) }
      end
    end
  end

  def self.latest_results
    Gateway.all.inject({}) do |result, gateway|
      result.update(gateway.name => gateway.latest_results)
    end
  end

  def self.available_gateway_names
    gateway_names = []
    Gateway.all.each do |gateway|
      gateway_names << gateway.name if gateway.working?
    end
    gateway_names
  end

  def working?
    last_result = results.last
    last_result.present? && last_result.download > 0 && last_result.upload > 0
  end

  def current_time_results
    results.created_at(Time.now.all_day)
  end

  def results_in_duration(from, to)
    ResultCalculator.new(self, from, to).analysis_quantity
  end

  def latest_results
    last_result_record = results.last
    last_manual_result_record = manual_results.last

    if last_result_record.present? && last_manual_result_record.present?
      last_result_record.created_at > last_manual_result_record.created_at ? last_result_record : last_manual_result_record
    else
      last_result_record || last_manual_result_record
    end
  end

  def add_speed_result(params)
    result = SpeedTestClient.parse_result(params[:result])

    attrs = { download: result[:download].to_f, upload: result[:upload].to_f, type: 'Result' }
    attrs.update(type: 'ManualResult') if params[:mode] == UPLOAD_MANUAL_MODE

    results.create(attrs)
  end
end
