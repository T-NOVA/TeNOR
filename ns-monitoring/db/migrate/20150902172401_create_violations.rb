class CreateViolations < ActiveRecord::Migration
  def change
  	create_table :violations do |t|
  		t.references :parameter, index: true
  		t.integer :breaches_count
  		t.integer :interval

  		t.timestamps null: false
  	end
  end
end