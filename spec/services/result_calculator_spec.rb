require "rails_helper"

describe ResultCalculator do
  let(:gateway) { Gateway.first }
  let(:from) { 2.day.ago }
  let(:to) { Time.current }
  let(:service) { ResultCalculator.new(gateway, from, to) }

  describe '#initialize' do
    it 'should set instance variables' do
      expect(service.instance_variable_get('@gateway')).to eq gateway
      expect(service.instance_variable_get('@from')).to eq from
      expect(service.instance_variable_get('@to')).to eq to
    end
  end

  describe '.time_label' do
    let(:time) { Time.now }
    let(:result) { ResultCalculator.time_label(time, type) }

    context 'Format type BY_DAYS' do
      let(:type) { ResultCalculator::BY_DAYS }
      let(:expected_result) { time.strftime "%d %b" }

      it 'should return time format for BY_DAYS' do
        expect(result).to eq expected_result
      end
    end

    context 'Format type BY_WEEKS' do
      let(:type) { ResultCalculator::BY_WEEKS }
      let(:current_week) { time.to_date.cweek - time.beginning_of_month.to_date.cweek + 1 }
      let(:expected_result) { "Week #{ current_week } of #{ time.strftime '%B' }" }

      it 'should return time format for BY_DAYS' do
        expect(result).to eq expected_result
      end
    end

    context 'Format type BY_MONTHS' do
      let(:type) { ResultCalculator::BY_MONTHS }
      let(:expected_result) { time.strftime "%B %Y" }

      it 'should return time format for BY_DAYS' do
        expect(result).to eq expected_result
      end
    end

    context 'Other format type' do
      let(:type) { ResultCalculator::CURRENT }
      let(:expected_result) { time.strftime "%H:%M" }

      it 'should return time format for other formats' do
        expect(result).to eq expected_result
      end
    end
  end

  describe '.calculator_type' do
    let(:to) { Time.now }
    let(:result) { ResultCalculator.calculator_type(from, to) }

    before do
      expect(TimeCalculator).to receive(:period).with(from, to).and_call_original
    end

    context 'Time less than a day' do
      let(:from) { 3.hours.ago }

      it 'should return type BY_CREATED_AT' do
        expect(result).to eq ResultCalculator::BY_CREATED_AT
      end
    end

    context 'Time less than 7 days' do
      let(:from) { 3.days.ago }

      it 'should return type BY_DAYS' do
        expect(result).to eq ResultCalculator::BY_DAYS
      end
    end

    context 'Time less than a month' do
      let(:from) { 2.weeks.ago }

      it 'should return type BY_WEEKS' do
        expect(result).to eq ResultCalculator::BY_WEEKS
      end
    end

    context 'Time less than a year' do
      let(:from) { 2.months.ago }

      it 'should return type BY_MONTHS' do
        expect(result).to eq ResultCalculator::BY_MONTHS
      end
    end

    context 'should return type CURRENT' do
      let(:from) { 2.years.ago }

      it 'should return results created_at by months' do
        expect(result).to eq ResultCalculator::CURRENT
      end
    end
  end

  describe '#analysis_quantity' do
    let(:result) { service.analysis_quantity }

    context 'Calculate by created_at' do
      it 'should return results created_at between period' do
        expect(service).to receive(:calculator_type).and_return(ResultCalculator::BY_CREATED_AT)
        expect(gateway.results).to receive(:created_at).with(from..to).and_return(results_performance = double)
        expect(ActiveModel::ArraySerializer).to receive(:new).with(results_performance, each_serializer: ResultSerializer).and_return(expected_results = double)

        expect(result).to eq expected_results
      end
    end

    context 'Calculate by days' do
      it 'should return results by days' do
        expect(service).to receive(:calculator_type).and_return(ResultCalculator::BY_DAYS)
        expect(service).to receive(:calculate_by_days).and_return(expected_results = double)

        expect(result).to eq expected_results
      end
    end

    context 'Calculate by weeks' do
      it 'should return results by weeks' do
        expect(service).to receive(:calculator_type).and_return(ResultCalculator::BY_WEEKS)
        expect(service).to receive(:calculate_by_weeks).and_return(expected_results = double)

        expect(result).to eq expected_results
      end
    end

    context 'Calculate by months' do
      it 'should return results by months' do
        expect(service).to receive(:calculator_type).and_return(ResultCalculator::BY_MONTHS)
        expect(service).to receive(:calculate_by_months).and_return(expected_results = double)

        expect(result).to eq expected_results
      end
    end

    context 'Calculate current results' do
      it 'should return current time results' do
        expect(service).to receive(:calculator_type).and_return(ResultCalculator::CURRENT)
        expect(gateway).to receive(:current_time_results).and_return(expected_results = double)

        expect(result).to eq expected_results
      end
    end
  end

  describe '#calculate_a_day' do
    context 'upload_average and download_average are not both 0' do
      let!(:results) { create_list(:result, 3, gateway: gateway) }

      let(:expected_result) { {
        "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, results.map(&:upload)),
        "download" => service.send(:calculate_average, results.map(&:download)),
        "created_at" => Result.first.created_at,
        "label" => ResultCalculator.time_label(Result.first.created_at, ResultCalculator::BY_DAYS)
      } }

      it 'should return average upload and average download' do
        expect(service.calculate_a_day(Result.all)).to eq expected_result
      end
    end

    context 'upload_average and download_average are both 0' do
      it 'should return nil' do
        expect(service.calculate_a_day(Result.none)).to eq nil
      end
    end
  end

  describe '#calculate_by_days' do
    let(:to) { Time.now }
    let(:from) { 3.days.ago }

    let!(:expected_results) do
      (1..3).map do |n|
        performance = gateway.results.created_at(n.days.ago.all_day)
        expect(service).to receive(:calculate_a_day).with(performance).and_return(data = double)
        data
      end
    end

    it 'should return results within given days' do
      expect(service.calculate_by_days).to eq expected_results
    end
  end

  describe '#calculate_by_weeks' do
    let(:begin_day) { Date.today.beginning_of_week }
    let!(:current_week_results) { create_list(:result, 4, gateway: gateway, created_at: begin_day + 1.day) }
    let!(:last_week_results) { create_list(:result, 4, gateway: gateway, created_at: begin_day - 1.day) }
    let!(:two_week_ago_results) { create_list(:result, 4, gateway: gateway, created_at: begin_day - 9.days) }

    let(:from) { (begin_day - 9.days).beginning_of_week }
    let(:to) { (begin_day + 1.day).end_of_week }

    let(:expected_result) { [
      { "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, current_week_results.map(&:upload)),
        "download" => service.send(:calculate_average, current_week_results.map(&:download)),
        "created_at" => begin_day.in_time_zone,
        "label" => ResultCalculator.time_label(begin_day.in_time_zone, ResultCalculator::BY_WEEKS) },
      { "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, last_week_results.map(&:upload)),
        "download" => service.send(:calculate_average, last_week_results.map(&:download)),
        "created_at" => (begin_day - 1.day).beginning_of_week.in_time_zone,
        "label" => ResultCalculator.time_label((begin_day - 1.day).beginning_of_week.in_time_zone, ResultCalculator::BY_WEEKS) },
      { "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, two_week_ago_results.map(&:upload)),
        "download" => service.send(:calculate_average, two_week_ago_results.map(&:download)),
        "created_at" => (begin_day - 9.days).beginning_of_week.in_time_zone,
        "label" => ResultCalculator.time_label((begin_day - 9.days).beginning_of_week.in_time_zone, ResultCalculator::BY_WEEKS) }
    ] }

    it 'should return array of average upload and download by weeks of input results' do
      expect(service.calculate_by_weeks).to match_array expected_result
    end
  end

  describe '#calculate_by_months' do
    let(:begin_day) { Date.today.beginning_of_month }
    let!(:current_month_results) { create_list(:result, 4, gateway: gateway, created_at: begin_day + 1.day) }
    let!(:last_month_results) { create_list(:result, 4, gateway: gateway, created_at: begin_day - 1.week) }
    let!(:two_month_ago_results) { create_list(:result, 4, gateway: gateway, created_at: begin_day - 7.weeks) }

    let(:from) { (begin_day - 7.weeks).beginning_of_month }
    let(:to) { (begin_day + 1.day).end_of_month }

    let(:expected_result) { [
      { "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, current_month_results.map(&:upload)),
        "download" => service.send(:calculate_average, current_month_results.map(&:download)),
        "created_at" => begin_day.in_time_zone,
        "label" => ResultCalculator.time_label(begin_day.in_time_zone, ResultCalculator::BY_MONTHS) },
      { "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, last_month_results.map(&:upload)),
        "download" => service.send(:calculate_average, last_month_results.map(&:download)),
        "created_at" => (begin_day - 1.week).beginning_of_month.in_time_zone,
        "label" => ResultCalculator.time_label((begin_day - 1.week).beginning_of_month.in_time_zone, ResultCalculator::BY_MONTHS) },
      { "gateway_id" => gateway.id,
        "upload" => service.send(:calculate_average, two_month_ago_results.map(&:upload)),
        "download" => service.send(:calculate_average, two_month_ago_results.map(&:download)),
        "created_at" => (begin_day - 7.weeks).beginning_of_month.in_time_zone,
        "label" => ResultCalculator.time_label((begin_day - 7.weeks).beginning_of_month.in_time_zone, ResultCalculator::BY_MONTHS) }
    ] }

    it 'should return array of average upload and download by months of input results' do
      expect(service.calculate_by_months).to match_array expected_result
    end
  end

  describe '#calculator_type' do
    it 'should call class method .calculator_type' do
      expect(ResultCalculator).to receive(:calculator_type).with(from, to).and_return(result = double)

      expect(service.send(:calculator_type)).to eq result
    end
  end

  describe '#calculate_average' do
    let(:result) { service.send(:calculate_average, data) }

    context 'data is not empty' do
      let(:data) { [7, 2, 8, 13] }
      let(:expected_result) { data.sum / 4 }

      it 'should return average data' do
        expect(result).to eq expected_result
      end
    end

    context 'data is empty' do
      let!(:data) { [] }

      it 'should return 0' do
        expect(result).to eq 0
      end
    end
  end

  describe '#split_month' do
    let(:begin_day) { Date.today.beginning_of_month }
    let(:months) { [begin_day - 7.weeks, begin_day - 1.weeks, begin_day - 1.day, begin_day + 1.week, begin_day + 2.weeks] }
    let(:expected_result) { [(begin_day - 7.weeks).beginning_of_month, (begin_day - 1.day).beginning_of_month, begin_day] }

    it 'should return array of unique beginning of months' do
      expect(service.send(:split_month, months)).to match_array expected_result
    end
  end

  describe '#split_week' do
    let(:begin_day) { Date.today.beginning_of_week }
    let(:weeks) { [begin_day - 12.days, begin_day - 2.days, begin_day - 1.day, begin_day + 1.day, begin_day + 2.days] }
    let(:expected_result) { [(begin_day - 12.days).beginning_of_week, (begin_day - 1.day).beginning_of_week, begin_day] }

    it 'should return array of unique beginning of weeks' do
      expect(service.send(:split_week, weeks)).to match_array expected_result
    end
  end

  describe '#format' do
    let(:time) { Time.now }
    let!(:results) { create_list(:result, 4, gateway: gateway) }
    let(:type) { ResultCalculator::BY_DAYS }
    let(:expected_result) { {
      "gateway_id" => gateway.id,
      "upload" => service.send(:calculate_average, results.map(&:upload)),
      "download" => service.send(:calculate_average, results.map(&:download)),
      "label" => ResultCalculator.time_label(time, type),
      "created_at" => time
    } }

    it 'should return hash of info' do
      expect(service.send(:format, time, results.map(&:upload), results.map(&:download), type)).to eq expected_result
    end
  end
end
