class AddOpportunitiesFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :opportunities_trash, :text
    add_column :ussd_sessions, :spc_opportunities_list_request, :text
    add_column :ussd_sessions, :spc_opportunities_list_response, :text
  end
end
