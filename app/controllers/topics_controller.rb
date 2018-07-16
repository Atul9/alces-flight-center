class TopicsController < ApplicationController
  def index
    if current_user.nil?
      render status: :unauthorized,
        json: { error: 'Authentication required' }
      return
    end
    topics = YAML.load_file(Rails.root.join('config', 'topics.yml'))
    render json: {
      topics: topics
    }
  end
end
