class AddArticles < ActiveRecord::Migration[5.2]
  def up
    topics = YAML.load_file(Rails.root.join('config', 'topics.yml'))
    topics.each do |t|
      articles = t['articles'] || []
      topic = Topic.find_by(title: t['title'])
      articles.each do |article|
        topic.articles.create!(article)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
