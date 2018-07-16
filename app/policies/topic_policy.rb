class TopicPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.where(site_id: nil)
      else
        scope.where(site_id: nil).or(scope.where(site_id: user.site))
      end
    end
  end
end
