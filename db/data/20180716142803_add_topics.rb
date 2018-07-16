class AddTopics < ActiveRecord::Migration[5.2]
  def up
    topics = YAML.load_file(Rails.root.join('config', 'topics.yml'))
    topics.each do |topic|
      Topic.create!(title: topic['title'])
    end
  end

  def down
    Topic.destroy_all
    # raise ActiveRecord::IrreversibleMigration
  end
end
