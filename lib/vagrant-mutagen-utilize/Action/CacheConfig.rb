module VagrantPlugins
  module Mutagen
    module Action
      class CacheConfig
        include Mutagen

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
        end

        def call(env)
          return unless plugin_orchestrate?(env)

          cacheConfigEntries
          @app.call(env)
        end

      end
    end
  end
end
