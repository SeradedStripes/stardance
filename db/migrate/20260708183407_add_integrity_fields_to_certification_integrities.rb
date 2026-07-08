class AddIntegrityFieldsToCertificationIntegrities < ActiveRecord::Migration[8.1]
  def change
    add_column :certification_integrities, :integrity_text, :text
    add_column :certification_integrities, :integrity_number, :float
    add_column :certification_integrities, :integrity_text_share, :float
    add_column :certification_integrities, :integrity_selection_share, :float
  end
end
