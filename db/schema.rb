# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150717151208) do

  create_table "embodiments", force: :cascade do |t|
    t.integer  "expression_id"
    t.integer  "manifestation_id"
    t.string   "reltype"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "sequence_number"
  end

  add_index "embodiments", ["expression_id"], name: "index_embodiments_on_expression_id"
  add_index "embodiments", ["manifestation_id"], name: "index_embodiments_on_manifestation_id"

  create_table "expression_relationships", force: :cascade do |t|
    t.integer  "exp1_id"
    t.integer  "exp2_id"
    t.string   "reltype"
    t.integer  "creator_id"
    t.integer  "reviewer_id"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "expression_relationships", ["creator_id"], name: "index_expression_relationships_on_creator_id"
  add_index "expression_relationships", ["exp1_id"], name: "index_expression_relationships_on_exp1_id"
  add_index "expression_relationships", ["exp2_id"], name: "index_expression_relationships_on_exp2_id"
  add_index "expression_relationships", ["reviewer_id"], name: "index_expression_relationships_on_reviewer_id"

  create_table "expressions", force: :cascade do |t|
    t.string   "title"
    t.string   "publication_date"
    t.string   "creation_date"
    t.string   "language"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "expressions", ["language"], name: "index_expressions_on_language"
  add_index "expressions", ["title"], name: "index_expressions_on_title"

  create_table "manifestations", force: :cascade do |t|
    t.string   "title"
    t.string   "responsibility"
    t.string   "edition"
    t.string   "publisher"
    t.string   "publication_date"
    t.string   "publication_place"
    t.string   "series_statement"
    t.text     "comment"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "manifestations", ["title"], name: "index_manifestations_on_title"

  create_table "people", force: :cascade do |t|
    t.string   "name"
    t.string   "dates"
    t.string   "title"
    t.string   "affiliation"
    t.string   "country"
    t.text     "comment"
    t.integer  "viaf_id"
    t.integer  "wikidata_q"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "openlibrary_id"
  end

  add_index "people", ["openlibrary_id"], name: "index_people_on_openlibrary_id"
  add_index "people", ["viaf_id"], name: "index_people_on_viaf_id"
  add_index "people", ["wikidata_q"], name: "index_people_on_wikidata_q"

  create_table "people_works", force: :cascade do |t|
    t.integer  "person_id"
    t.integer  "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "people_works", ["person_id"], name: "index_people_works_on_person_id"
  add_index "people_works", ["work_id"], name: "index_people_works_on_work_id"

  create_table "realizations", force: :cascade do |t|
    t.integer  "realizer_id"
    t.integer  "expression_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "realizations", ["expression_id"], name: "index_realizations_on_expression_id"
  add_index "realizations", ["realizer_id"], name: "index_realizations_on_realizer_id"

  create_table "reifications", force: :cascade do |t|
    t.integer  "work_id"
    t.integer  "expression_id"
    t.string   "reltype"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "reifications", ["expression_id"], name: "index_reifications_on_expression_id"
  add_index "reifications", ["work_id"], name: "index_reifications_on_work_id"

  create_table "tocs", force: :cascade do |t|
    t.string   "book_uri"
    t.text     "toc_body"
    t.string   "status"
    t.integer  "contributor_id"
    t.integer  "reviewer_id"
    t.text     "comments"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "tocs", ["book_uri"], name: "index_tocs_on_book_uri", unique: true
  add_index "tocs", ["contributor_id"], name: "index_tocs_on_contributor_id"
  add_index "tocs", ["reviewer_id"], name: "index_tocs_on_reviewer_id"

  create_table "work_relationships", force: :cascade do |t|
    t.integer  "work1_id"
    t.integer  "work2_id"
    t.string   "reltype"
    t.integer  "creator_id"
    t.integer  "reviewer_id"
    t.string   "status"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "work_relationships", ["creator_id"], name: "index_work_relationships_on_creator_id"
  add_index "work_relationships", ["reviewer_id"], name: "index_work_relationships_on_reviewer_id"
  add_index "work_relationships", ["work1_id"], name: "index_work_relationships_on_work1_id"
  add_index "work_relationships", ["work2_id"], name: "index_work_relationships_on_work2_id"

  create_table "works", force: :cascade do |t|
    t.string   "title"
    t.string   "form"
    t.string   "creation_date"
    t.text     "comment"
    t.string   "status"
    t.integer  "superseded_by"
    t.integer  "wikidata_q"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "works", ["title"], name: "index_works_on_title"
  add_index "works", ["wikidata_q"], name: "index_works_on_wikidata_q"

end
