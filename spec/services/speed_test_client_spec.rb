require "rails_helper"

describe SpeedTestClient do
  describe '.parse_result' do
    context 'Speed Test succeeds' do
      let(:upload) { 12.85 }
      let(:download) { 20.68 }
      let(:speedtest_result) { "Retrieving speedtest.net configuration...\nRetrieving speedtest.net server list...\nTesting from Viettel Corporation (115.78.162.133)...\nHosted by Unwired (San Francisco, CA) [12589.38 km]: 250.301 ms\nTesting download speed........................................\nDownload: #{ download } Mbits/s\nTesting upload speed..................................................\nUpload: #{ upload } Mbits/s" }
      let(:parsed_result) { { upload: upload.to_s, download: download.to_s } }

      it 'should return hash of download and upload speed' do
        expect(SpeedTestClient.parse_result(speedtest_result)).to eq parsed_result
      end
    end

    context 'Speed Test fails' do
      let(:speedtest_result) { "Retrieving speedtest.net configuration...\nCannot retrieve speedtest configuration" }
      let(:parsed_result) { { upload: "", download: "" } }

      it 'should return hash of blank download and upload speed' do
        expect(SpeedTestClient.parse_result(speedtest_result)).to eq parsed_result
      end
    end
  end
end
