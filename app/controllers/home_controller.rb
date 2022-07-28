class HomeController < ApplicationController
  def index
    @gateways = Gateway.where(name: Gateway::NAMES).map { |i| { id: i.id, name: i.name, ip: i.ip } }
  end
end
