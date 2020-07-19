# frozen_string_literal: true

require_relative '../orchestrator'

module VagrantPlugins
  module MutagenUtilizer
    module Action
      class SaveMachineIdentifier
        def initialize(app, env)
          @app = app
          @machine = env[:machine]
        end

        def call(env)
          o = Orchestrator.new(@machine, @console)
          o.save_machine_identifier
          @app.call(env)
        end
      end
    end
  end
end
