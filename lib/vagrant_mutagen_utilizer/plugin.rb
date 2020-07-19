# frozen_string_literal: true

require_relative 'action/update_config'
require_relative 'action/remove_config'
require_relative 'action/start_orchestration'
require_relative 'action/terminate_orchestration'

module VagrantPlugins
  module MutagenUtilizer
    # Plugin to utilize mutagen
    class MutagenUtilizerPlugin < Vagrant.plugin('2')
      name 'Mutagen Utilize'
      description <<-DESC
        This plugin manages the ~/.ssh/config file for the host machine. An entry is
        created for the hostname attribute in the vm.config.
      DESC

      config(:mutagen_utilizer) do
        require_relative 'config'
        Config
      end

      action_hook(:mutagen_utilizer, :machine_action_up) do |hook|
        hook.append(Action::UpdateConfig)
        hook.append(Action::StartOrchestration)
      end

      action_hook(:mutagen_utilizer, :machine_action_provision) do |hook|
        hook.before(Vagrant::Action::Builtin::Provision, Action::UpdateConfig)
        hook.before(Vagrant::Action::Builtin::Provision, Action::StartOrchestration)
      end

      action_hook(:mutagen_utilizer, :machine_action_halt) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::RemoveConfig)
      end

      action_hook(:mutagen_utilizer, :machine_action_suspend) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::RemoveConfig)
      end

      action_hook(:mutagen_utilizer, :machine_action_destroy) do |hook|
        hook.prepend(Action::RemoveConfig)
        hook.prepend(Action::TerminateOrchestration)
      end

      action_hook(:mutagen_utilizer, :machine_action_reload) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::UpdateConfig)
        hook.append(Action::StartOrchestration)
      end

      action_hook(:mutagen_utilizer, :machine_action_resume) do |hook|
        hook.append(Action::TerminateOrchestration)
        hook.append(Action::UpdateConfig)
        hook.append(Action::StartOrchestration)
      end
    end
  end
end
