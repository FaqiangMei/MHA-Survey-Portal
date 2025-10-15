class AddTrackAndGroupingToSurveys < ActiveRecord::Migration[8.0]
  def change
    add_column :surveys, :track, :string
    add_index :surveys, :track

    create_table :survey_assignments do |t|
      t.references :survey, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :advisor_id, null: false
      t.timestamps
    end

    add_foreign_key :survey_assignments, :advisors, column: :advisor_id, primary_key: :advisor_id, on_delete: :cascade
    add_index :survey_assignments, [:survey_id, :advisor_id], unique: true

    create_table :survey_category_tags do |t|
      t.references :survey, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :category_id, null: false
      t.timestamps
    end

    add_foreign_key :survey_category_tags, :categories, column: :category_id, on_delete: :cascade
    add_index :survey_category_tags, [:survey_id, :category_id], unique: true

    create_table :survey_audit_logs do |t|
      t.bigint :survey_id
      t.bigint :admin_id, null: false
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_foreign_key :survey_audit_logs, :surveys, on_delete: :nullify
    add_foreign_key :survey_audit_logs, :admins, column: :admin_id, primary_key: :admin_id, on_delete: :cascade
    add_index :survey_audit_logs, :created_at
    add_index :survey_audit_logs, :action
  end
end
