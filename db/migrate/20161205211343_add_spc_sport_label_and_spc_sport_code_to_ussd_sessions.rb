class AddSpcSportLabelAndSpcSportCodeToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_sport_label, :string
    add_column :ussd_sessions, :spc_sport_code, :string
  end
end
