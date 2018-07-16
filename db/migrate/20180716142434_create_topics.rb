class CreateTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :topics do |t|
      t.string :title,
        null: false,
        limit: 255,
        unique: true

      t.string :scope, null: false

      t.references :site, foreign_key: true

      t.timestamps
    end
  end
end
