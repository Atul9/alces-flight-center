module TabsHelper
  class TabsBuilder
    def initialize(scope)
      @scope = scope.decorate
    end

    def overview
      { id: :overview, path: scope.scope_path }
    end

    def cases
      {
        id: :cases, path: scope.scope_cases_path,
        dropdown: [
          { text: 'Current', path: scope.scope_cases_path },
          { text: 'Archive', path: scope.archives_scope_cases_path }
        ]
      }
    end

    def asset_record
      { id: :asset_record, path: scope.scope_asset_record_path }
    end

    private

    attr_reader :scope
  end
end

