class CreateMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :materials do |t|
      t.references :user, null: false, foreign_key: true

      t.string :title, null: false
      t.integer :total_amount
      t.string :unit_label
      t.date :deadline

      t.timestamps
    end
  end
end
