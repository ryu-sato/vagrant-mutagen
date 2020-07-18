require_relative "../Mutagen"
module VagrantPlugins
  module Mutagen
    module Action
      class TerminateOrchestration
        include Mutagen


        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @ui = env[:ui]
        end

        def call(env)
          return unless plugin_orchestrate?(env)

          terminateOrchestration
          @app.call(env)
        end

      end
    end
  end
end
