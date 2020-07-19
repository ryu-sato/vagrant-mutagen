# frozen_string_literal: true

require_relative '../orchestrator'

module Vagrant
  module Mutagen
    module Utilize
      module Action
        # Remove SSH config entry from user ssh config file
        class RemoveConfig
          def initialize(app, env)
            @app = app
            @machine = env[:machine]
            @config = env[:machine].config
            @console = env[:ui]
          end

          def call(env)
            return unless @config.orchestrate?

            o = Orchestrator.new(@machine, @console)
            o.remove_ssh_config_entry
            @app.call(env)
          end
        end
      end
    end
  end
end
