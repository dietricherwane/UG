class AddListSportcashSportsFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :list_sportcash_sports_request, :text
    add_column :ussd_sessions, :list_sportcash_sports_response, :text
    add_column :ussd_sessions, :sportcash_sport_label, :string
    add_column :ussd_sessions, :sportcash_sport_code, :string
  end
end
