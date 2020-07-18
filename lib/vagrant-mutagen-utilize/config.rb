require 'vagrant'

module VagrantPlugins
  module Mutagen
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :orchestrate
      attr_accessor :ssh_user_config_path

      def initialize
        super

        @orchestrate = UNSET_VALUE
        @ssh_user_config_path = UNSET_VALUE
      end

      def finalize!
        @orchestrate = false if @orchestrate == UNSET_VALUE
        @ssh_user_config_path = File.expand_path('~/.ssh/config') if @ssh_user_config_path == UNSET_VALUE
      end

      def orchestrate?
        @orchestrate
      end
    end
  end
end
