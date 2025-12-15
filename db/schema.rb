# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_12_15_053747) do
  create_table "aboutnesses", force: :cascade do |t|
    t.bigint "embodiment_id"
    t.string "subject_heading_uri"
    t.string "source_name"
    t.string "subject_heading_label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contributor_id"
    t.bigint "reviewer_id"
    t.string "status", default: "verified"
    t.index ["contributor_id"], name: "index_aboutnesses_on_contributor_id"
    t.index ["embodiment_id"], name: "index_aboutnesses_on_embodiment_id"
    t.index ["reviewer_id"], name: "index_aboutnesses_on_reviewer_id"
    t.index ["source_name"], name: "index_aboutnesses_on_source_name"
    t.index ["status"], name: "index_aboutnesses_on_status"
  end

  create_table "embodiments", force: :cascade do |t|
    t.bigint "expression_id"
    t.bigint "manifestation_id"
    t.string "reltype"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sequence_number"
    t.index ["expression_id"], name: "index_embodiments_on_expression_id"
    t.index ["manifestation_id"], name: "index_embodiments_on_manifestation_id"
  end

  create_table "expression_relationships", force: :cascade do |t|
    t.bigint "exp1_id"
    t.bigint "exp2_id"
    t.string "reltype"
    t.bigint "creator_id"
    t.bigint "reviewer_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_expression_relationships_on_creator_id"
    t.index ["exp1_id"], name: "index_expression_relationships_on_exp1_id"
    t.index ["exp2_id"], name: "index_expression_relationships_on_exp2_id"
    t.index ["reviewer_id"], name: "index_expression_relationships_on_reviewer_id"
  end

  create_table "expressions", force: :cascade do |t|
    t.string "title"
    t.string "publication_date"
    t.string "creation_date"
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["language"], name: "index_expressions_on_language"
    t.index ["title"], name: "index_expressions_on_title"
  end

  create_table "manifestations", force: :cascade do |t|
    t.string "title"
    t.string "responsibility"
    t.string "edition"
    t.string "publisher"
    t.string "publication_date"
    t.string "publication_place"
    t.string "series_statement"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_manifestations_on_title"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.string "dates"
    t.string "title"
    t.string "affiliation"
    t.string "country"
    t.text "comment"
    t.integer "viaf_id"
    t.integer "wikidata_q"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "openlibrary_id"
    t.string "loc_id"
    t.integer "gutenberg_id"
    t.index ["gutenberg_id"], name: "index_people_on_gutenberg_id"
    t.index ["loc_id"], name: "index_people_on_loc_id"
    t.index ["openlibrary_id"], name: "index_people_on_openlibrary_id"
    t.index ["viaf_id"], name: "index_people_on_viaf_id"
    t.index ["wikidata_q"], name: "index_people_on_wikidata_q"
  end

  create_table "people_tocs", force: :cascade do |t|
    t.bigint "person_id"
    t.bigint "toc_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "toc_id"], name: "index_people_tocs_on_person_id_and_toc_id", unique: true
    t.index ["person_id"], name: "index_people_tocs_on_person_id"
    t.index ["toc_id"], name: "index_people_tocs_on_toc_id"
  end

  create_table "people_works", force: :cascade do |t|
    t.bigint "person_id"
    t.bigint "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_people_works_on_person_id"
    t.index ["work_id"], name: "index_people_works_on_work_id"
  end

  create_table "realizations", force: :cascade do |t|
    t.bigint "realizer_id"
    t.bigint "expression_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expression_id"], name: "index_realizations_on_expression_id"
    t.index ["realizer_id"], name: "index_realizations_on_realizer_id"
  end

  create_table "reifications", force: :cascade do |t|
    t.bigint "work_id"
    t.bigint "expression_id"
    t.string "reltype"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expression_id"], name: "index_reifications_on_expression_id"
    t.index ["work_id"], name: "index_reifications_on_work_id"
  end

  create_table "tocs", force: :cascade do |t|
    t.string "book_uri"
    t.text "toc_body"
    t.string "status", default: "empty"
    t.bigint "contributor_id"
    t.bigint "reviewer_id"
    t.text "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "manifestation_id"
    t.string "title"
    t.text "toc_page_urls"
    t.boolean "no_explicit_toc", default: false, null: false
    t.datetime "transcribed_at"
    t.datetime "verified_at"
    t.text "imported_subjects"
    t.text "book_data"
    t.integer "source"
    t.index ["book_uri"], name: "index_tocs_on_book_uri", unique: true
    t.index ["contributor_id"], name: "index_tocs_on_contributor_id"
    t.index ["manifestation_id"], name: "index_tocs_on_manifestation_id"
    t.index ["reviewer_id"], name: "index_tocs_on_reviewer_id"
    t.index ["source"], name: "index_tocs_on_source"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.boolean "editor", default: false
    t.boolean "help_enabled", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["help_enabled"], name: "index_users_on_help_enabled"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "work_relationships", force: :cascade do |t|
    t.bigint "work1_id"
    t.bigint "work2_id"
    t.string "reltype"
    t.bigint "creator_id"
    t.bigint "reviewer_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_work_relationships_on_creator_id"
    t.index ["reviewer_id"], name: "index_work_relationships_on_reviewer_id"
    t.index ["work1_id"], name: "index_work_relationships_on_work1_id"
    t.index ["work2_id"], name: "index_work_relationships_on_work2_id"
  end

  create_table "works", force: :cascade do |t|
    t.string "title"
    t.string "form"
    t.string "creation_date"
    t.text "comment"
    t.string "status"
    t.bigint "superseded_by"
    t.integer "wikidata_q"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_works_on_title"
    t.index ["wikidata_q"], name: "index_works_on_wikidata_q"
  end

  add_foreign_key "expression_relationships", "expressions", column: "exp1_id"
  add_foreign_key "expression_relationships", "expressions", column: "exp2_id"
  add_foreign_key "expression_relationships", "users", column: "creator_id"
  add_foreign_key "expression_relationships", "users", column: "reviewer_id"
  add_foreign_key "people_tocs", "people"
  add_foreign_key "people_tocs", "tocs"
  add_foreign_key "people_works", "people"
  add_foreign_key "people_works", "works"
  add_foreign_key "realizations", "expressions"
  add_foreign_key "realizations", "people", column: "realizer_id"
  add_foreign_key "reifications", "expressions"
  add_foreign_key "reifications", "works"
  add_foreign_key "work_relationships", "users", column: "creator_id"
  add_foreign_key "work_relationships", "users", column: "reviewer_id"
  add_foreign_key "work_relationships", "works", column: "work1_id"
  add_foreign_key "work_relationships", "works", column: "work2_id"
end
