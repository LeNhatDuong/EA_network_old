require "rails_helper"

describe HomeController do
  describe 'GET index' do
    let(:gateways) { Gateway.where(name: Gateway::NAMES).map { |i| { id: i.id, name: i.name, ip: i.ip } } }

    it 'should set neccessary instance variables' do
      get :index

      expect(assigns(:gateways)).to eq gateways
    end
  end
end
