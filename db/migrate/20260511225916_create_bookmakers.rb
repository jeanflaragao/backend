class CreateBookmakers < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmakers do |t|
      t.string :name
      t.string :website
      t.string :country
      t.string :status

      t.timestamps
    end
  end
end
