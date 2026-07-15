class AddCurrencyToBookmakers < ActiveRecord::Migration[8.0]
  def change
    add_column :bookmakers, :currency, :string
  end
end
