class CreateManualUpdateLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :manual_update_logs do |t|
      t.string :client_ip

      t.timestamps null: false
    end
  end
end
