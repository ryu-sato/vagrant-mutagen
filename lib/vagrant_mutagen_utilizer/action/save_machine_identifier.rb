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
        #   o = Orchestrator.new(@machine, @console)
        #   o.remove_ssh_config_entry
          @app.call(env)
        end
      end
    end
  end
end
