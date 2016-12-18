class AddSpcDrawDescriptionAndSpcOddToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_draw_description, :string
    add_column :ussd_sessions, :spc_odd, :string
  end
end
