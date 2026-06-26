class CreateStudyUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :study_units do |t|
      t.references :material, null: false, foreign_key: true

      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.integer :estimated_minutes, null: false

      t.timestamps
    end
  end
end
