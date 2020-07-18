module VagrantPlugins
  module Mutagen
    module Action
      class RemoveConfig
        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @config = env[:machine].config
          @ui = env[:ui]
        end

        def call(env)
          return unless @config.orchestrate?

          m = Mutagen.new(@machine, @ui)
          m.remove_ssh_config_entry
          @app.call(env)
        end
      end
    end
  end
end
