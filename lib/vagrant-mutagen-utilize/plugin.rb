require 'vagrant-mutagen-utilize/action/update_config'
require 'vagrant-mutagen-utilize/action/cache_config'
require 'vagrant-mutagen-utilize/action/remove_config'
require 'vagrant-mutagen-utilize/action/start_orchestration'
require 'vagrant-mutagen-utilize/action/terminate_orchestration'

module VagrantPlugins
  module Mutagen
    class MutagenUtilizePlugin < Vagrant.plugin('2')
      name 'Mutagen Utilize'
      description <<-DESC
      This plugin manages the ~/.ssh/config file for the host machine. An entry is
      created for the hostname attribute in the vm.config.
      DESC

      config(:mutagen_utilize) do
        require_relative 'config'
        Config
      end

      action_hook(:mutagen_utilize, :machine_action_up) do |hook|
        hook.append(Action::UpdateConfig)
        hook.append(Action::StartOrchestration)
      end

      action_hook(:mutagen_utilize, :machine_action_provision) do |hook|
        hook.before(Vagrant::Action::Builtin::Provision, Action::UpdateConfig)
        hook.before(Vagrant::Action::Builtin::Provision, Action::StartOrchestration)
      end

      action_hook(:mutagen_utilize, :machine_action_halt) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::RemoveConfig)
      end

      action_hook(:mutagen_utilize, :machine_action_suspend) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::RemoveConfig)
      end

      action_hook(:mutagen_utilize, :machine_action_destroy) do |hook|
        hook.prepend(Action::RemoveConfig)
        hook.prepend(Action::TerminateOrchestration)
      end

      action_hook(:mutagen_utilize, :machine_action_reload) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::UpdateConfig)
        hook.append(Action::StartOrchestration)
      end

      action_hook(:mutagen_utilize, :machine_action_resume) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::UpdateConfig)
        hook.append(Action::StartOrchestration)
      end
    end
  end
end
