# frozen_string_literal: true

require_relative '../mutagen'

module Vagrant
  module Mutagen
    module Utilize
      module Action
        # Update ssh config entry
        # If ssh config entry already exists, just entry appended
        class UpdateConfig
          def initialize(app, env)
            @app = app
            @machine = env[:machine]
            @config = env[:machine].config
            @console = env[:ui]
          end

          def call(env)
            return unless @config.orchestrate?

            m = Mutagen.new(@machine, @console)
            m.update_ssh_config_entry
            @app.call(env)
          end
        end
      end
    end
  end
end
