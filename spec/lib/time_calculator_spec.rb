require "rails_helper"

describe TimeCalculator do
  describe '.period' do
    let(:from) { 10.hours.ago }
    let(:to) { Time.current }
    let(:result) { TimeCalculator.period(from, to) }

    it 'should return period of duration in days and round up' do
      expect(result).to eq 1
    end
  end

  describe '.parse_time' do
    let(:result) { TimeCalculator.parse_time(time) }

    context 'time is present' do
      let(:time) { 1.day.ago.to_s }

      it 'should return parsed time' do
        expect(result.to_date).to eq Date.yesterday
      end
    end

    context 'time is blank' do
      let(:time) { "" }
      let!(:current_time) { Time.current }

      it 'should return current time' do
        allow(Time).to receive(:current).and_return(current_time)
        expect(result).to eq current_time
      end
    end
  end

  describe '.next_day' do
    let(:time) { 1.day.ago }
    let(:result) { TimeCalculator.next_day(time) }

    it 'should return the next day' do
      expect(result.to_date).to eq Date.today
    end
  end
end
