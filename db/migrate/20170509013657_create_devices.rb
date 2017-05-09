class CreateDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :devices do |t|
      t.integer :reference_id

      t.timestamps
    end
  end
end
