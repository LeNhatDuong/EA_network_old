require "rails_helper"

describe ManualUpdate do
  let(:request_ip) { Faker::Internet.ip_v4_address }
  let(:manual_update) { ManualUpdate.new(request_ip) }

  describe '#initialize' do
    let(:result_ip) { manual_update.instance_variable_get('@request_ip') }

    it 'should set instance variable @request_ip' do
      expect(result_ip).to eq request_ip
    end
  end

  describe '#perform' do
    before do
      expect(ManualUpdate).to receive(:check_auto_update).and_return(check_auto_update)
    end

    context 'Check auto update: Not allow to manual update' do
      let(:error_message) { "Reason not be able to manual update" }
      let(:check_auto_update) { { updatable: false, message: error_message } }

      it 'should return error message and not perform manual update' do
        expect(manual_update).not_to receive(:perform_manual_update)

        expect(manual_update.perform).to eq error_message
      end
    end

    context 'Check auto update: Allow to manual update' do
      let(:check_auto_update) { { updatable: true, message: 'Can proceed to manual update' } }

      before do
        expect(ManualUpdate).to receive(:can_update?).and_return(can_update)
      end

      context 'Check last manual update log: Not allow to update' do
        let(:can_update) { false }

        it 'should return error message and not perform manual update' do
          expect(manual_update).not_to receive(:perform_manual_update)

          expect(manual_update.perform).to eq "The result was updated few minutes ago"
        end
      end

      context 'Check last manual update log: Allow to update' do
        let(:can_update) { true }

        it 'should return success message and perform manual update' do
          expect(manual_update).to receive(:perform_manual_update)

          expect(manual_update.perform).to eq "Manual updating is activated"
        end
      end
    end
  end

  describe '.authenticate_to_update' do
    context 'Correct input password' do
      let(:password) { Constant::PASSWORD_UPDATE }

      it 'should return true' do
        expect(ManualUpdate).to be_authenticate_to_update(password)
      end
    end

    context 'Incorrect input password' do
      let(:password) { 'something' }

      it 'should return false' do
        expect(ManualUpdate).not_to be_authenticate_to_update(password)
      end
    end
  end

  describe '.can_update?' do
    context 'No Manual Update log' do
      it 'should return true' do
        expect(ManualUpdate).to be_can_update
      end
    end

    context 'Manual Update logs exists' do
      context 'Duration is less than 10 minutes' do
        let!(:manual_update_log) { create(:manual_update_log, created_at: 5.minutes.ago) }

        it 'should return false' do
          expect(ManualUpdate).not_to be_can_update
        end
      end

      context 'Duration is larger than 10 minutes' do
        let!(:manual_update_log) { create(:manual_update_log, created_at: 15.minutes.ago) }

        it 'should return true' do
          expect(ManualUpdate).to be_can_update
        end
      end
    end
  end

  describe '.check_auto_update' do
    let!(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
    end

    context 'Current time minutes is less than 10' do
      let(:expected_result) { { updatable: false, message: "Auto updating is on process, manual mode is disabled" } }

      it 'should return false with error message' do
        allow(current_time).to receive(:min).and_return(5)

        expect(ManualUpdate.check_auto_update).to eq expected_result
      end
    end

    context 'Current time minutes is larger than 50' do
      let(:expected_result) { { updatable: false, message: "Auto updating will be activated soon, manual mode is disabled" } }

      it 'should return false with error message' do
        allow(current_time).to receive(:min).and_return(55)

        expect(ManualUpdate.check_auto_update).to eq expected_result
      end
    end

    context 'Otherwise' do
      let(:expected_result) { { updatable: true, message: "Can proceed to manual update" } }

      it 'should return true with success message' do
        allow(current_time).to receive(:min).and_return(15)

        expect(ManualUpdate.check_auto_update).to eq expected_result
      end
    end
  end

  describe '#perform_manual_update' do
    let(:manual_update_log) { ManualUpdateLog.last }

    it 'should queue manual update job and create manual_update_log' do
      expect(HardWorker).to receive(:perform_async)

      expect { manual_update.send(:perform_manual_update) }.to change(ManualUpdateLog, :count).by(1)
      expect(manual_update_log.client_ip).to eq request_ip
    end
  end
end
