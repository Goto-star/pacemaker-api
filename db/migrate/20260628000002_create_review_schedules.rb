class CreateReviewSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :review_schedules do |t|
      t.references :study_unit, null: false, foreign_key: true

      t.date :scheduled_on, null: false
      t.integer :review_count, null: false, default: 0
      t.boolean :completed, null: false, default: false

      t.timestamps
    end

    add_index :review_schedules, [ :study_unit_id, :scheduled_on ]
    add_index :review_schedules, :scheduled_on
  end
end
