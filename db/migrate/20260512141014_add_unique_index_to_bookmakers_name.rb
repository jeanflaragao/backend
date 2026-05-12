class AddUniqueIndexToBookmakersName < ActiveRecord::Migration[8.0]
  def change
    add_index :bookmakers, :name, unique: true
  end
end
