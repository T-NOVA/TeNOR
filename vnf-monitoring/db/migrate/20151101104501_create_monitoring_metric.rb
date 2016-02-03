class CreateMonitoringMetric < ActiveRecord::Migration
  def change
    create_table :monitoring_metrics do |t|
      t.string :vnfi_id
      t.string :name
      t.string :unit
      
    end
  end
  def down
    drop_table :monitoring_metrics
  end
end
