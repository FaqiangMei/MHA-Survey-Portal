class CreateEvidenceUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :evidence_uploads, primary_key: :evidenceupload_id do |t|
      t.bigint :student_id, null: false
      t.bigint :questionresponse_id
      t.string :link, null: false
      t.bigint :created_by
      t.timestamps
    end

    add_index :evidence_uploads, :student_id
    add_index :evidence_uploads, :questionresponse_id
    add_foreign_key :evidence_uploads, :students, column: :student_id, primary_key: :student_id, on_delete: :cascade
    add_foreign_key :evidence_uploads, :question_responses, column: :questionresponse_id, primary_key: :questionresponse_id, on_delete: :cascade
  end
end
