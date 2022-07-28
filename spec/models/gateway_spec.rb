require "rails_helper"

describe Gateway do
  it { should have_many :results }
  it { should have_many :manual_results }
  it { should validate_inclusion_of(:name).in_array(Gateway::NAMES) }

  let(:gateway) { Gateway.first }

  context 'is initialized with contants' do
    let(:gateway_config) { YAML::load_file(Rails.root.join('config', 'gateway.yml')) }
    let(:expected_gateway_names) { gateway_config['gateways'].split(' ') }

    context 'NAMES' do
      it 'contains the gateway names array' do
        expect(Gateway::NAMES).to eq expected_gateway_names
      end
    end

    context 'NAMES_WITH_IP' do
      let(:expected_gateway_names_with_ip) do
        hash = {}
        expected_gateway_names.each { |name| hash[name] = gateway_config['gateway'][name] }
        hash
      end

      it 'contains the Gateways/IP hash' do
        expect(Gateway::NAMES_WITH_IP).to eq expected_gateway_names_with_ip
      end
    end
  end

  it 'has default scope of IP ascending' do
    expect(Gateway.all.to_sql).to eq Gateway.order(:ip).to_sql
  end

  describe '.all_gateway_current_time_results' do
    context 'Input gateway_id' do
      let(:result) { Gateway.all_gateway_current_time_results(gateway_id) }

      context 'Gateway exists' do
        let(:gateway_id) { Gateway.first.id }
        let(:gateway) { Gateway.first }
        let!(:gateway_current_time_results) { double }
        let(:expected_results) { { name: gateway.name, performances: gateway_current_time_results } }

        it 'should return current_time_results of gateway' do
          expect(Gateway).to receive(:find_by).with(id: gateway_id).and_return(gateway)
          expect(gateway).to receive(:current_time_results).and_return(gateway_current_time_results)
          expect(result).to eq [expected_results]
        end
      end

      context 'Invalid gateway' do
        let(:gateway_id) { -1 }

        it 'should return an empty array' do
          expect(result).to be_blank
        end
      end
    end

    context 'No input gateway_id' do
      let(:result) { Gateway.all_gateway_current_time_results }
      let(:gateways) { Gateway.all }

      it 'should return current_time_results of all gateways' do
        allow(Gateway).to receive(:all).and_return(gateways)
        expected_results = gateways.map do |gateway|
          expect(gateway).to receive(:current_time_results).and_return(performance_results = double)
          { name: gateway.name, performances: performance_results }
        end
        expect(result).to match_array expected_results
      end
    end
  end

  describe '.all_gateway_results_in_duration' do
    let(:from) { (1.day.ago) }
    let(:to) { (Time.now) }

    context 'Input gateway_id' do
      let(:result) { Gateway.all_gateway_results_in_duration(from, to, gateway_id) }

      context 'Gateway exists' do
        let(:gateway_id) { Gateway.first.id }
        let(:gateway) { Gateway.first }
        let!(:gateway_results_in_duration) { double }
        let!(:expected_result) { { name: gateway.name, performances: gateway_results_in_duration } }

        it 'should return results_in_duration of gateway' do
          expect(Gateway).to receive(:find_by).with(id: gateway_id).and_return(gateway)
          expect(gateway).to receive(:results_in_duration).with(from, to).and_return(gateway_results_in_duration)
          expect(result).to eq [expected_result]
        end
      end

      context 'Invalid gateway' do
        let(:gateway_id) { -1 }
        it 'should return an empty array' do
          expect(result).to be_blank
        end
      end
    end

    context 'No input gateway_id' do
      let(:result) { Gateway.all_gateway_results_in_duration(from, to, nil) }
      let(:gateways) { Gateway.all }

      it 'should return results_in_duration of all gateways' do
        allow(Gateway).to receive(:all).and_return(gateways)
        expected_results = gateways.map do |gateway|
          expect(gateway).to receive(:results_in_duration).with(from, to).and_return(performance_results = double)
          { name: gateway.name, performances: performance_results }
        end
        expect(result).to match_array expected_results
      end
    end
  end

  describe '.latest_results' do
    let(:result)  { Gateway.latest_results }
    let(:gateways) { Gateway.all }

    it 'should return latest results' do
      expect(Gateway).to receive(:all).and_return(gateways)
      expected_result = {}
      gateways.map do |gateway|
        expect(gateway).to receive(:latest_results).and_return(gateway_latest_result = double)
        expected_result[gateway.name] = gateway_latest_result
      end
      expect(result).to eq expected_result
    end
  end

  describe '.available_gateway_names' do
    let(:not_working_gateway) { Gateway.last }
    let!(:expected_results) { Gateway.where.not(name: not_working_gateway.name).pluck(:name) }
    let!(:gateways) { Gateway.all }

    before do
      allow(not_working_gateway).to receive(:working?).and_return(false)
      (gateways - [not_working_gateway]).each do |gateway|
        allow(gateway).to receive(:working?).and_return(true)
      end
      expect(Gateway).to receive(:all).and_return(gateways)
    end

    it 'should return list of wokring gateway' do
      expect(Gateway.available_gateway_names).to eq expected_results
    end
  end

  describe '#working?' do
    context 'No results record' do
      it 'should return false' do
        expect(gateway).not_to be_working
      end
    end

    context 'Download or upload speed of last result is 0' do
      let!(:result) { create(:result, gateway: gateway, upload: 0, download: 0) }

      it 'should return false' do
        expect(gateway).not_to be_working
      end
    end

    context 'Download and upload speed of last result is larger than 0' do
      let!(:result) { create(:result, gateway: gateway, upload: 5, download: 1) }

      it 'should return true' do
        expect(gateway).to be_working
      end
    end
  end

  describe '#current_time_results' do
    let!(:current_day) { Time.now.all_day }

    it 'should return results that have created_at within current day' do
      allow(Time).to receive_message_chain(:now, :all_day).and_return(current_day)
      expect(gateway.results).to receive(:created_at).with(current_day)

      gateway.current_time_results
    end
  end

  describe '#results_in_duration' do
    let(:from) { (1.day.ago) }
    let(:to) { (Time.now) }
    let!(:result_calculator) { ResultCalculator.new(gateway, from, to) }

    it 'should return analysis_quantity' do
      expect(ResultCalculator).to receive(:new).with(gateway, from, to).and_return(result_calculator)
      expect(result_calculator).to receive(:analysis_quantity).and_return(result = double)

      expect(gateway.results_in_duration(from, to)).to eq result
    end
  end

  describe '#latest_results' do
    let(:result) { gateway.latest_results }

    context 'last_result_record and last_manual_result_record are present' do
      context 'last_result_record is more current than last_manual_result_record' do
        let!(:last_result_record) { create(:result, gateway: gateway, created_at: Time.now) }
        let!(:last_manual_result_record) { create(:manual_result, gateway: gateway, created_at: 1.day.ago) }

        it 'should return last_result_record' do
          expect(gateway.results).to receive(:last).and_return(last_result_record)
          expect(gateway.manual_results).to receive(:last).and_return(last_manual_result_record)
          expect(result).to eq last_result_record
        end
      end

      context 'last_manual_result_record is more current than last_result_record' do
        let!(:last_result_record) { create(:result, gateway: gateway, created_at: 1.day.ago) }
        let!(:last_manual_result_record) { create(:manual_result, gateway: gateway, created_at: Time.now) }

        it 'should return last_manual_result_record' do
          expect(gateway.results).to receive(:last).and_return(last_result_record)
          expect(gateway.manual_results).to receive(:last).and_return(last_manual_result_record)
          expect(result).to eq last_manual_result_record
        end
      end
    end

    context 'last_result_record or last_manual_result_record is not present' do
      context 'last_result_record is present' do
        let!(:last_result_record) { create(:result, gateway: gateway) }

        it 'should return last_result_record' do
          expect(result).to eq last_result_record
        end
      end

      context 'last_manual_result_record is present' do
        let!(:last_manual_result_record) { create(:manual_result, gateway: gateway) }

        it 'should return last_manual_result_record' do
          expect(result).to eq last_manual_result_record
        end
      end
    end
  end

  describe '#add_speed_result' do
    let(:download) { 600 }
    let(:upload) { 500 }
    let(:parsed_speedtest) { { upload: upload, download: download } }
    let(:last_result) { gateway.results.last }

    before do
      expect(SpeedTestClient).to receive(:parse_result).and_return parsed_speedtest
    end

    context 'Manual Result' do
      let(:params) { { result: "Result from speedtest", mode: Gateway::UPLOAD_MANUAL_MODE } }

      it 'should create new manual_result for gateway' do
        expect { gateway.add_speed_result(params) }.to change(gateway.manual_results, :count).by(1)
        expect(last_result).to be_is_a ManualResult
        expect(last_result.upload).to eq upload
        expect(last_result.download).to eq download
      end
    end

    context "Result" do
      let(:params) { { result: "Result from speedtest" } }

      it 'should create new result for gateway' do
        expect { gateway.add_speed_result(params) }.to change(gateway.results, :count).by(1)
        expect(last_result).to be_is_a Result
        expect(last_result.upload).to eq upload
        expect(last_result.download).to eq download
      end
    end
  end
end
