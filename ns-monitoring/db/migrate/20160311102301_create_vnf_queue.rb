class CreateVnfQueue < ActiveRecord::Migration
  def change
    create_table :vnf_queues do |t|
      t.string :nsi_id
      t.string :vnfi_id
      t.string :parameter_id
      t.string :value
      t.string :unit
      t.string :timestamp

    end
  end
  def down
    drop_table :vnf_queues
  end
end