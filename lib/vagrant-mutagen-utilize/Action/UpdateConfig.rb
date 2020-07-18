require_relative "../Mutagen"

module VagrantPlugins
  module Mutagen
    module Action
      class UpdateConfig
        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @ui = env[:ui]
        end

        def call(env)
          m = Mutagen.new(@machine, @ui)
          return unless m.plugin_orchestrate?

          m.addConfigEntries
          @app.call(env)
        end

      end
    end
  end
end
