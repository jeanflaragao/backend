class AddUserToBookmakers < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookmakers, :user, null: false, foreign_key: true
  end
end
