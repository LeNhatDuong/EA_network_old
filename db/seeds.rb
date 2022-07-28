# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Gateway.destroy_all
# Result.destroy_all

config = YAML::load_file(Rails.root.join('config', 'gateway.yml'))
config['gateway'].each do |name, ip|
  gateway = Gateway.create(name: name, ip: ip)
  gateway.results.create(download: 0, upload: 0, type: 'Result')
end
