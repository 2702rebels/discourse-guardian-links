# frozen_string_literal: true

module ::GuardianLinks
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace GuardianLinks
  end
end
