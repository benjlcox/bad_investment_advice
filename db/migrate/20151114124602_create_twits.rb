class CreateTwits < ActiveRecord::Migration
  def self.up
    create_table :twits do |t|
      t.string :stock
      t.integer :key
      t.text :body
      t.timestamps
    end
  end

  def self.down
    drop_table :twits
  end
end
