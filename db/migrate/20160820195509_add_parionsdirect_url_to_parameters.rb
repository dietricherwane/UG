class AddParionsdirectUrlToParameters < ActiveRecord::Migration
  def change
    add_column :parameters, :parionsdirect_url, :string
  end
end
