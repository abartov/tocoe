class FixForeignKeyTypes < ActiveRecord::Migration[7.2]
  def up
    # Remove foreign keys from people_tocs before changing column types
    remove_foreign_key :people_tocs, :people if foreign_key_exists?(:people_tocs, :people)
    remove_foreign_key :people_tocs, :tocs if foreign_key_exists?(:people_tocs, :tocs)

    # Change all foreign key columns to bigint
    # aboutnesses
    change_column :aboutnesses, :embodiment_id, :bigint
    change_column :aboutnesses, :contributor_id, :bigint
    change_column :aboutnesses, :reviewer_id, :bigint

    # embodiments
    change_column :embodiments, :expression_id, :bigint
    change_column :embodiments, :manifestation_id, :bigint

    # expression_relationships
    change_column :expression_relationships, :exp1_id, :bigint
    change_column :expression_relationships, :exp2_id, :bigint
    change_column :expression_relationships, :creator_id, :bigint
    change_column :expression_relationships, :reviewer_id, :bigint

    # people_works
    change_column :people_works, :person_id, :bigint
    change_column :people_works, :work_id, :bigint

    # realizations
    change_column :realizations, :realizer_id, :bigint
    change_column :realizations, :expression_id, :bigint

    # reifications
    change_column :reifications, :work_id, :bigint
    change_column :reifications, :expression_id, :bigint

    # tocs
    change_column :tocs, :contributor_id, :bigint
    change_column :tocs, :reviewer_id, :bigint
    change_column :tocs, :manifestation_id, :bigint

    # people_tocs
    change_column :people_tocs, :person_id, :bigint
    change_column :people_tocs, :toc_id, :bigint

    # work_relationships
    change_column :work_relationships, :work1_id, :bigint
    change_column :work_relationships, :work2_id, :bigint
    change_column :work_relationships, :creator_id, :bigint
    change_column :work_relationships, :reviewer_id, :bigint

    # works
    change_column :works, :superseded_by, :bigint

    # Re-add foreign keys to people_tocs
    add_foreign_key :people_tocs, :people
    add_foreign_key :people_tocs, :tocs
  end

  def down
    # Remove foreign keys from people_tocs before changing column types
    remove_foreign_key :people_tocs, :people if foreign_key_exists?(:people_tocs, :people)
    remove_foreign_key :people_tocs, :tocs if foreign_key_exists?(:people_tocs, :tocs)

    # Revert all foreign key columns to integer
    # aboutnesses
    change_column :aboutnesses, :embodiment_id, :integer
    change_column :aboutnesses, :contributor_id, :integer
    change_column :aboutnesses, :reviewer_id, :integer

    # embodiments
    change_column :embodiments, :expression_id, :integer
    change_column :embodiments, :manifestation_id, :integer

    # expression_relationships
    change_column :expression_relationships, :exp1_id, :integer
    change_column :expression_relationships, :exp2_id, :integer
    change_column :expression_relationships, :creator_id, :integer
    change_column :expression_relationships, :reviewer_id, :integer

    # people_works
    change_column :people_works, :person_id, :integer
    change_column :people_works, :work_id, :integer

    # realizations
    change_column :realizations, :realizer_id, :integer
    change_column :realizations, :expression_id, :integer

    # reifications
    change_column :reifications, :work_id, :integer
    change_column :reifications, :expression_id, :integer

    # tocs
    change_column :tocs, :contributor_id, :integer
    change_column :tocs, :reviewer_id, :integer
    change_column :tocs, :manifestation_id, :integer

    # people_tocs
    change_column :people_tocs, :person_id, :integer
    change_column :people_tocs, :toc_id, :integer

    # work_relationships
    change_column :work_relationships, :work1_id, :integer
    change_column :work_relationships, :work2_id, :integer
    change_column :work_relationships, :creator_id, :integer
    change_column :work_relationships, :reviewer_id, :integer

    # works
    change_column :works, :superseded_by, :integer

    # Re-add foreign keys to people_tocs
    add_foreign_key :people_tocs, :people
    add_foreign_key :people_tocs, :tocs
  end
end
