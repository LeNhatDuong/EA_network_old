class CreateResults < ActiveRecord::Migration[7.0]
  def change
    create_table :results do |t|
      t.integer :gateway_id
      t.float :upload
      t.float :download
      t.string :type

      t.timestamps null: false
    end
  end
end
