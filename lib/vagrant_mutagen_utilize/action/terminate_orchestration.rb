# frozen_string_literal: true

require_relative '../mutagen'

module Vagrant
  module Mutagen
    module Utilize
      module Action
        # Terminate mutagen project
        class TerminateOrchestration
          def initialize(app, env)
            @app = app
            @machine = env[:machine]
            @config = env[:machine].config
            @console = env[:ui]
          end

          def call(env)
            return unless @config.orchestrate?

            m = Mutagen.new(@machine, @console)
            m.terminate_orchestration
            @app.call(env)
          end
        end
      end
    end
  end
end
