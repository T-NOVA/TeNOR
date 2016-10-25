class CreateSlas < ActiveRecord::Migration
  def change
    create_table :slas do |t|
      t.string :nsi_id, null: false
      
      t.timestamps null: false
    end

  end
end
