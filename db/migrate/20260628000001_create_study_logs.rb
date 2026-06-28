class CreateStudyLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :study_logs do |t|
      t.references :study_unit, null: false, foreign_key: true

      t.date :studied_on, null: false
      t.integer :rating, null: false
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :study_logs, [ :study_unit_id, :studied_on ]
  end
end
