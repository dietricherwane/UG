class AddDrawingBetFormulaToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :drawing, :string
    add_column :logs, :bet, :string
    add_column :logs, :formula, :string
  end
end
