module VagrantPlugins
  module Mutagen
    module Action
      class RemoveConfig
        include Mutagen

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @ui = env[:ui]
        end

        def call(env)
          return unless plugin_orchestrate?(env)

          @ui.info "[vagrant-mutagen-utilize] Removing SSH config entry"
          removeConfigEntries
          @app.call(env)
        end

      end
    end
  end
end
