class CreateCommunicates < ActiveRecord::Migration[5.1]
  def change
    create_table :communicates do |t|
      t.text :message

      t.timestamps
    end
  end
end
