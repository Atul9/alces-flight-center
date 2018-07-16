class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :title, null: false, limit: 255
      t.string :url, null: false, limit: 512
      t.json :meta, null: false, default: '{}'
      t.references :topic, foreign_key: true

      t.timestamps
    end
  end
end
