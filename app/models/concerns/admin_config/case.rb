
module AdminConfig::Case
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :rt_ticket_id do
          hide
        end
        configure :token do
          hide
        end
        configure :maintenance_windows do
          hide
        end
        configure :display_id do
          hide
        end
        configure :log do
          hide
        end
        configure :case_comments do
          hide
        end
        configure :case_state_transitions do
          hide
        end
        configure :change_motd_request do
          hide
        end
      end
    end
  end

end
