class CreateGateways < ActiveRecord::Migration[7.0]
  def change
    create_table :gateways do |t|
      t.string :name
      t.string :ip

      t.timestamps null: false
    end
  end
end
