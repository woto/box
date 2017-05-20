class CreateDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :devices do |t|
      t.string :external_id
      t.float :lat
      t.float :lng
      t.text :location
      t.integer :is_working
      t.text :comment

      t.timestamps
    end
  end
end
