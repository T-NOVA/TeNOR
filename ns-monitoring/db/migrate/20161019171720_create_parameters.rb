class CreateParameters < ActiveRecord::Migration
  def change
    create_table :parameters do |t|
      t.string :parameter_id, null: false
      t.string :threshold
      t.string :name

      t.belongs_to :sla, index: true
      t.timestamps null: false
    end

#    add_index :parameters, :name, unique: true
  end
end
