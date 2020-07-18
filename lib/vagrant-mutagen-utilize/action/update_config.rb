require_relative '../mutagen'

module Vagrant
  module Mutagen
    module Utilize
      module Action
        class UpdateConfig
          def initialize(app, env)
            @app = app
            @machine = env[:machine]
            @config = env[:machine].config
            @ui = env[:ui]
          end

          def call(env)
            return unless @config.orchestrate?

            m = Mutagen.new(@machine, @ui)
            m.update_ssh_config_entry
            @app.call(env)
          end
        end
      end
    end
  end
end
