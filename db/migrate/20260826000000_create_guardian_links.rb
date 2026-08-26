# frozen_string_literal: true

class CreateGuardianLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :guardian_links do |t|
      t.integer :parent_id, null: false
      t.integer :student_id, null: false
      t.string :relationship_type, null: false, default: "parent"
      t.timestamps
    end

    add_index :guardian_links, :parent_id
    add_index :guardian_links, :student_id
    add_index :guardian_links, %i[parent_id student_id], unique: true

    add_foreign_key :guardian_links, :users, column: :parent_id, on_delete: :cascade
    add_foreign_key :guardian_links, :users, column: :student_id, on_delete: :cascade
  end
end
