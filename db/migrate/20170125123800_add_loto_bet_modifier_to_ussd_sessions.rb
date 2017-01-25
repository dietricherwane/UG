class AddLotoBetModifierToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :loto_bet_modifier, :string
  end
end
