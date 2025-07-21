class AddDiffDataToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :diff_data, :text
  end
end
