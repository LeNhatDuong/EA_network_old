class ResultCalculator
  TYPES = [
    CURRENT = "current",
    BY_CREATED_AT = "by_created_at",
    BY_DAYS = "by_days",
    BY_WEEKS = "by_weeks",
    BY_MONTHS = "by_months"
  ]

  def initialize(gateway, from, to)
    @gateway = gateway
    @from = from
    @to = to
  end

  def self.time_range(start_time, end_time, type)
    case type
    when ResultCalculator::BY_DAYS, ResultCalculator::BY_WEEKS, ResultCalculator::BY_MONTHS
      start_label = time_label(start_time, type)
      end_label = time_label(end_time, type)
    else
      start_label = start_time.strftime('%H:%M')
      end_label = end_time.strftime('%H:%M • %d %b %Y')
    end
    "#{start_label} – #{end_label}"
  end

  def self.time_label(time, type)
    case type
    when ResultCalculator::BY_DAYS
      time.strftime "%d %b"
    when ResultCalculator::BY_WEEKS
      current_week = time.to_date.cweek - time.beginning_of_month.to_date.cweek + 1
      "Week #{current_week} of #{time.strftime '%B'}"
    when ResultCalculator::BY_MONTHS
      time.strftime "%B %Y"
    else
      time.strftime "%H:%M"
    end
  end

  def self.calculator_type(from, to)
    case TimeCalculator.period(from, to)
    when 0..1
      BY_CREATED_AT
    when 2..7
      BY_DAYS
    when 8..31
      BY_WEEKS
    when 32..366
      BY_MONTHS
    else
      CURRENT
    end
  end

  def analysis_quantity
    case calculator_type
    when BY_CREATED_AT
      ActiveModel::ArraySerializer.new(@gateway.results.created_at(@from..@to), each_serializer: ResultSerializer)
    when BY_DAYS
      calculate_by_days
    when BY_WEEKS
      calculate_by_weeks
    when BY_MONTHS
      calculate_by_months
    else
      @gateway.current_time_results
    end
  end

  def calculate_a_day(data_of_day)
    upload_average = calculate_average(data_of_day.pluck(:upload))
    download_average = calculate_average(data_of_day.pluck(:download))

    upload_average == 0 && download_average == 0 ? nil : format(data_of_day.first.created_at, data_of_day.pluck(:upload), data_of_day.pluck(:download), BY_DAYS)
  end

  def calculate_by_days
    current_time = @from
    result = []
    while current_time.end_of_day <= @to
      if data = calculate_a_day(@gateway.results.created_at(current_time.all_day))
        result << data
      end
      current_time = TimeCalculator.next_day(current_time)
    end
    result
  end

  def calculate_by_weeks
    data_of_weeks = @gateway.results.created_at(@from.beginning_of_week..@to.end_of_week)
    result = []
    split_week(data_of_weeks.pluck(:created_at)).each do |week|
      week_uploads = data_of_weeks.select { |r| r.created_at.beginning_of_week == week }.map(&:upload)
      week_downloads = data_of_weeks.select { |r| r.created_at.beginning_of_week == week }.map(&:download)

      result << format(week, week_uploads, week_downloads, BY_WEEKS)
    end
    result
  end

  def calculate_by_months
    data_of_month = @gateway.results.created_at(@from.beginning_of_month..@to.end_of_month)
    result = []
    split_month(data_of_month.pluck(:created_at)).each do |month|
      month_uploads = data_of_month.select { |r| r.created_at.beginning_of_month == month }.map(&:upload)
      month_downloads = data_of_month.select { |r| r.created_at.beginning_of_month == month }.map(&:download)

      result << format(month, month_uploads, month_downloads, BY_MONTHS)
    end
    result
  end

  private
  def calculator_type
    @calculator_type ||= ResultCalculator.calculator_type(@from, @to)
  end

  def calculate_average(data)
    average = data.inject(0) { |total, result| total += result }
    average /= data.count unless data.count.zero?
    average
  end

  def split_month(months)
    result = []
    months.each do |time|
      result << time.beginning_of_month unless result.include?(time.beginning_of_month)
    end
    result
  end

  def split_week(weeks)
    result = []
    weeks.each do |time|
      result << time.beginning_of_week unless result.include?(time.beginning_of_week)
    end
    result
  end

  def format(created_at, uploads, downloads, type)
    { "gateway_id" => @gateway.id,
      "upload" => calculate_average(uploads),
      "download" => calculate_average(downloads),
      "label" => ResultCalculator.time_label(created_at, type),
      "created_at" => created_at }
  end
end
