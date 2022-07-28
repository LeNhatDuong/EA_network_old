class GatewayPerformance
  CHART_TYPES = [ALL_CHART = "all", SINGLE_CHART = 'single']

  def initialize(start_time, end_time, selected_gateway_id = nil)
    @start_time = ::TimeCalculator.parse_time(start_time).beginning_of_day
    @end_time = ::TimeCalculator.parse_time(end_time).end_of_day
    @gateway_id = selected_gateway_id
    @chart_type = @gateway_id.present? ? SINGLE_CHART : ALL_CHART
    @data_type = ResultCalculator.calculator_type(@start_time, @end_time)
  end

  def results
    if invalid_period?
      error_message = I18n.t("notice.invalid")
      performance_results = Gateway.all_gateway_current_time_results(@gateway_id)
    else
      performance_results = Gateway.all_gateway_results_in_duration(@start_time, @end_time, @gateway_id)

      if performance_results.blank?
        error_message = I18n.t("notice.no_record")
        performance_results = Gateway.all_gateway_current_time_results(@gateway_id)
      else
        error_message = I18n.t("notice.success")
      end
    end
    { type: @chart_type, error: error_message, data: performance_results, chart_name: chart_name, time_range: time_range }
  end

  def invalid_period?
    @start_time > @end_time || @start_time > Time.current.end_of_day || @end_time > Time.current.end_of_day
  end

  def chart_name
    if gateway = Gateway.find_by_id(@gateway_id)
      "#{gateway.name} Gateway Performance"
    else
      "All Gateway Performance"
    end
  end

  def time_range
    ResultCalculator.time_range(@start_time, @end_time, @data_type)
  end
end
