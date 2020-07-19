# frozen_string_literal: true

module Vagrant
  module Mutagen
    module Utilize
      # Class for orchestrate with mutagen
      class Orchestrator
        def initialize(machine, console)
          @machine = machine
          @console = console
        end

        # Update ssh config entry
        # If ssh config entry already exists, just entry appended
        def update_ssh_config_entry
          hostname = @machine.config.vm.hostname

          logging(:info, 'Checking for SSH config entries')
          if ssh_config_entry_exist?
            logging(:info, "  updating SSH Config entry for: #{hostname}")
            remove_from_ssh_config
          else
            logging(:info, "  adding entry to SSH config for: #{hostname}")
          end
          append_to_ssh_config(ssh_config_entry)
        end

        # Remove ssh config entry
        def remove_ssh_config_entry
          return unless ssh_config_entry_exist?

          logging(:info, 'Removing SSH config entry')
          remove_from_ssh_config
        end

        def start_orchestration
          return if mutagen_project_started?

          logging(:info, 'Starting mutagen project orchestration (config: /mutagen.yml)')
          start_mutagen_project || logging(:error, 'Failed to start mutagen project (see error above)')
          # show project status to indicate if there are conflicts
          list_mutagen_project
        end

        def terminate_orchestration
          return unless mutagen_project_started?

          logging(:info, 'Terminating mutagen project orchestration')
          terminate_mutagen_project || logging(:error, 'Failed to terminate mutagen project (see error above)')
        end

        private

        def logging(level, message, with_prefix = true)
          prefix = with_prefix ? '[vagrant-mutagen-utilize] ' : ''

          @console.send(level, "#{prefix}#{message}")
        end

        def ssh_user_config_path
          @machine.config.mutagen_utilize.ssh_user_config_path
        end

        # Create a regular expression that will match the vagrant-mutagen-utilize signature
        def ssh_config_entry_pattern
          hostname = @machine.config.vm.hostname

          Regexp.new("^(#{Regexp.escape(signature)}).*$\nHost #{hostname}.*$")
        end

        def ssh_config_removing_pattern
          escaped_signature = Regexp.escape(signature)

          Regexp.new("^(#{escaped_signature}).*?(^#{escaped_signature}).*$", Regexp::MULTILINE)
        end

        def signature
          name = @machine.name
          uuid = @machine.id
          hashed_id = Digest::MD5.hexdigest(uuid)

          %(# VAGRANT: #{hashed_id} (#{name}) / #{uuid})
        end

        def ssh_config_entry
          hostname = @machine.config.vm.hostname

          # Get the SSH config from Vagrant
          sshconfig = `vagrant ssh-config --host #{hostname}`
          # Trim Whitespace from end
          sshconfig = sshconfig.gsub(/^$\n/, '')
          sshconfig = sshconfig.chomp

          %(#{signature}\n#{sshconfig}\n#{signature})
        end

        def ssh_config_entry_exist?
          File.read(ssh_user_config_path).match?(ssh_config_entry_pattern)
        end

        def validate_ssh_config_writable
          return true if File.writable_real?(ssh_user_config_path)

          logging(:info, "You don't have permission of #{ssh_user_config_path}. " \
                  'You should manually adding equivalent entries to the config file.')

          false
        end

        def append_to_ssh_config(entry)
          return if entry.length.zero?
          return unless validate_ssh_config_writable

          logging(:info, "Writing the following config to (#{ssh_user_config_path})")
          logging(:info, entry, false)
          append_line_feed_to_end_of_file_if_not_exist(ssh_user_config_path)
          File.open(ssh_user_config_path, 'a') do |f|
            f.write(entry)
          end
        end

        def remove_from_ssh_config
          return unless validate_ssh_config_writable

          content = File.read(ssh_user_config_path)
          new_content = content.gsub(ssh_config_removing_pattern, '')
          File.open(ssh_user_config_path, 'w') do |f|
            f.write(new_content)
          end
        end

        def append_line_feed_to_end_of_file_if_not_exist(path)
          # It is set "true" as default because
          #   when it doesn't know if file is ending with line feed or not, it should not add the line feed.
          is_file_end_with_line_feed = true
          File.open(path, 'a+') do |f|
            f.seek(-1, IO::SEEK_END).zero? || (logging(:warning, "Cannot seek file #{path}") && break)
            c = f.getc
            is_file_end_with_line_feed = false if c != "\r" && c != "\n"
          end
          return if is_file_end_with_line_feed

          File.open(path, 'a') do |f|
            f.puts('')
          end
        end

        # Define methods to controll mutagen
        DISCARD_STDOUT = Vagrant::Util::Platform.windows? ? '>nul'  : '>/dev/null'
        DISCARD_STDERR = Vagrant::Util::Platform.windows? ? '2>nul' : '2>/dev/null'
        MUTAGEN_METHODS = {
          # mutagen project list returns 1 on error when no project is started
          "mutagen_project_started?": "mutagen project list #{DISCARD_STDOUT} #{DISCARD_STDERR}",
          'start_mutagen_project': 'mutagen project start',
          'terminate_mutagen_project': 'mutagen project terminate',
          'list_mutagen_project': 'mutagen project list'
        }.freeze
        MUTAGEN_METHODS.each_pair do |method_name, command|
          define_method method_name do
            system(command)
          end
        end
      end
    end
  end
end
