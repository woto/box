class CreateCells < ActiveRecord::Migration[5.1]
  def change
    create_table :cells do |t|
      t.references :device, foreign_key: true
      t.string :external_reference
      t.boolean :is_working
      t.boolean :is_fill
      t.integer :width
      t.integer :height
      t.integer :length

      t.timestamps
    end
  end
end
