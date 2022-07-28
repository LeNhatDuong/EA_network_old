require "rails_helper"

describe GatewayPerformance do
  let(:from_time) { 1.day.ago }
  let(:to_time) { Time.now }
  let(:from) { from_time.to_s }
  let(:to) { to_time.to_s }
  let(:from_time_label) { ResultCalculator.time_label(from_time, ResultCalculator::BY_DAYS) }
  let(:to_time_label) { ResultCalculator.time_label(to_time, ResultCalculator::BY_DAYS) }
  let(:time_range) { "#{from_time_label} – #{to_time_label}" }
  let(:gateway) { Gateway.first }
  let(:chart_name) { "#{ gateway.name } Gateway Performance" }
  let(:gateway_performance) { GatewayPerformance.new(from, to, gateway.id) }
  let(:all_gateways_performance) { GatewayPerformance.new(from, to) }

  describe '#initialize' do
    let(:performance_start_time) { gateway_performance.instance_variable_get('@start_time') }
    let(:performance_end_time) { gateway_performance.instance_variable_get('@end_time') }
    let(:performance_gateway_id) { gateway_performance.instance_variable_get('@gateway_id') }
    let(:performance_data_type) { gateway_performance.instance_variable_get('@data_type') }
    let(:performance_chart_type) { gateway_performance.instance_variable_get('@chart_type') }
    let(:all_performance_chart_type) { all_gateways_performance.instance_variable_get('@chart_type') }

    it 'should set instance variables' do
      expect(performance_start_time).to eq ::TimeCalculator.parse_time(from).beginning_of_day
      expect(performance_end_time).to eq ::TimeCalculator.parse_time(to).end_of_day
      expect(performance_gateway_id).to eq gateway.id
      expect(performance_data_type).to eq ResultCalculator.calculator_type(from_time, to_time)
      expect(all_performance_chart_type).to eq GatewayPerformance::ALL_CHART
      expect(performance_chart_type).to eq GatewayPerformance::SINGLE_CHART
    end
  end

  describe '#results' do
    let(:expected_result) { { type: GatewayPerformance::SINGLE_CHART, error: error_message, data: performance_results, chart_name: chart_name, time_range: time_range } }
    let(:performance_results) { double }

    context 'Invalid input period' do
      let(:error_message) { I18n.t('notice.invalid') }

      it 'should return performance result data' do
        expect(gateway_performance).to receive(:invalid_period?).and_return(true)
        expect(Gateway).to receive(:all_gateway_current_time_results).with(gateway.id).and_return(performance_results)

        expect(gateway_performance.results).to eq expected_result
      end
    end

    context 'Valid input period' do
      let(:start_time) { gateway_performance.instance_variable_get('@start_time') }
      let(:end_time) { gateway_performance.instance_variable_get('@end_time') }

      before do
        expect(gateway_performance).to receive(:invalid_period?).and_return(false)
      end

      context 'performance_results is empty' do
        let(:error_message) { I18n.t("notice.no_record") }

        it 'should return performance result data' do
          expect(Gateway).to receive(:all_gateway_results_in_duration).with(start_time, end_time, gateway.id).and_return([])
          expect(Gateway).to receive(:all_gateway_current_time_results).with(gateway.id).and_return(performance_results)

          expect(gateway_performance.results).to eq expected_result
        end
      end

      context 'performance_results is not empty' do
        let(:error_message) { I18n.t("notice.success") }

        it 'should return performance result data' do
          expect(Gateway).to receive(:all_gateway_results_in_duration).with(start_time, end_time, gateway.id).and_return(performance_results)

          expect(gateway_performance.results).to eq expected_result
        end
      end
    end
  end

  describe '#invalid_period?' do
    context 'start_time larger than end_time' do
      let(:from) { Time.now.to_s }
      let(:to) { 1.day.ago.to_s }

      it 'should return true' do
        expect(gateway_performance).to be_invalid_period
      end
    end

    context 'start_time larger than end of today' do
      let(:from) { 1.day.from_now.to_s }
      let(:to) { 2.days.from_now.to_s }

      it 'should return true' do
        expect(gateway_performance).to be_invalid_period
      end
    end

    context 'end_time larger than end of today' do
      let(:from) { 1.day.ago.to_s }
      let(:to) { 2.days.from_now.to_s }

      it 'should return true' do
        expect(gateway_performance).to be_invalid_period
      end
    end

    context 'Otherwise' do
      it 'should return false' do

        expect(gateway_performance).not_to be_invalid_period
      end
    end
  end

  describe '#chart_name' do
    context 'With Gateway' do
      let(:expected_result) { "#{ gateway.name } Gateway Performance" }

      it 'should return chart_name with gateway info' do
        expect(gateway_performance.chart_name).to eq expected_result
      end
    end

    context 'No Gateway' do
      let(:expected_result) { "All Gateway Performance" }

      it 'should return time duration info' do
        expect(all_gateways_performance.chart_name).to eq expected_result
      end
    end
  end

  describe '#time_range' do
    it 'should return chart_name with gateway and time duration info' do
      expect(gateway_performance.time_range).to eq time_range
    end
  end
end
