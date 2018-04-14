class CreateTwitterUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :twitter_users do |t|
      t.integer :user_id, :limit => 8
      t.string :name
      t.string :screen_name
      t.string :profile_image_url

      t.timestamps
    end
    add_index :twitter_users, [:user_id], :name => "by_user_id", :unique => true
    add_index :twitter_users, [:screen_name], :name => "by_screen_name"
  end
end
