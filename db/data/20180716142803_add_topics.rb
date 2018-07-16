class AddTopics < ActiveRecord::Migration[5.2]
  def up
    topics = YAML.load_file(Rails.root.join('config', 'topics.yml'))
    topics.each do |topic|
      if topic['site'].present?
        site = Site.find_by(name: topic['site'])
        Topic.create!(title: topic['title'], scope: 'site', site: site)
      else
        Topic.create!(title: topic['title'], scope: 'global')
      end
    end
  end

  def down
    Topic.destroy_all
    # raise ActiveRecord::IrreversibleMigration
  end
end
