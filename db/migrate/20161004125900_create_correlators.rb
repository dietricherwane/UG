class CreateCorrelators < ActiveRecord::Migration
  def change
    create_table :correlators do |t|
      t.string :correlator_id

      t.timestamps
    end
  end
end
