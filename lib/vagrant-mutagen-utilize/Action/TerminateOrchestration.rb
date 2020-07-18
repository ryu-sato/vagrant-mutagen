require_relative '../Mutagen'
module VagrantPlugins
  module Mutagen
    module Action
      class TerminateOrchestration
        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @config = env[:machine].config
          @ui = env[:ui]
        end

        def call(env)
          return unless @config.orchestrate?

          m = Mutagen.new(@machine, @ui)
          m.terminate_orchestration
          @app.call(env)
        end
      end
    end
  end
end
