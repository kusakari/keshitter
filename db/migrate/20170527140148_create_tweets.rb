class CreateTweets < ActiveRecord::Migration[5.1]
  def change
    create_table :tweets do |t|
      t.integer :status_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.text :body
      t.text :media_uris
      t.datetime :deleted_at
      t.datetime :created_at

      t.timestamps
    end
    add_index :tweets, [:status_id], :name => "by_status_id", :unique => true
  end
end
