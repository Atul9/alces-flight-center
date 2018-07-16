class CreateTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :topics do |t|
      t.string :title,
        null: false,
        limit: 255,
        unique: true

      t.timestamps
    end
  end
end
