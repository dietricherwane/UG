class AddWalletUrlToParameters < ActiveRecord::Migration
  def change
    add_column :parameters, :wallet_url, :string
  end
end
