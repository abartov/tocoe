class AddTocPageFieldsToTocs < ActiveRecord::Migration[7.2]
  def change
    add_column :tocs, :toc_page_urls, :text
    add_column :tocs, :no_explicit_toc, :boolean, default: false, null: false
  end
end
