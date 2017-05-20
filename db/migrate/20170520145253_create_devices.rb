class CreateDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :devices do |t|
      t.string :external_reference
      t.float :lat
      t.float :lng
      t.text :location
      t.boolean :is_working

      t.timestamps
    end
  end
end
