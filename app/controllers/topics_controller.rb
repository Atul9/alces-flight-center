class TopicsController < ApplicationController
  def index
    if current_user.nil?
      render status: :unauthorized,
        json: { error: 'Authentication required' }
      return
    end

    render json: {
      topics: policy_scope(Topic).all.map do |t|
        {
          title: t.title,
          articles: t.articles.map do |a|
            {
              title: a.title,
              url: a.url,
              meta: a.meta,
            }
          end,
        }
      end
    }
  end
end
