module VagrantPlugins
  module Mutagen
    class Mutagen
      def initialize(machine, ui)
        @machine = machine
        @ui = ui
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

      def remove_ssh_config_entry
        if !@machine.id && !@machine.config.mutagen_utilize.id
          logging(:info, "No machine id, nothing removed from #{ssh_user_config_path}")
          return
        end
        return unless ssh_config_entry_exist?

        logging(:info, 'Removing SSH config entry')
        remove_from_ssh_config
      end

      def start_orchestration
        return if mutagen_project_started?

        logging(:info, 'Starting mutagen project orchestration (config: /mutagen.yml)')
        start_mutagen_project || logging(:error, 'Failed to start mutagen project (see error above)')
        list_mutagen_project # show project status to indicate if there are conflicts
      end

      def terminate_orchestration
        return unless mutagen_project_started?

        logging(:info, 'Terminating mutagen project orchestration')
        terminate_mutagen_project || logging(:error, 'Failed to terminate mutagen project (see error above)')
      end

      def cache_config_entry
        @machine.config.mutagen_utilize.id = @machine.id
      end

      private

      def logging(level, message, with_prefix = true)
        prefix = with_prefix ? '[vagrant-mutagen-utilize] ' : ''
        @ui.send(level, "#{prefix}#{message}")
      end

      def ssh_user_config_path
        @machine.config.mutagen_utilize.ssh_user_config_path
      end

      # Create a regular expression that will match the vagrant-mutagen-utilize signature
      def ssh_config_entry_pattern(hostname, _name, uuid = self.uuid)
        hashedId = Digest::MD5.hexdigest(uuid)
        Regexp.new("^# VAGRANT: #{hashedId}.*$\nHost #{hostname}.*$")
      end

      def signature(name, uuid = self.uuid)
        hashedId = Digest::MD5.hexdigest(uuid)
        %(# VAGRANT: #{hashedId} (#{name}) / #{uuid})
      end

      def ssh_config_entry
        hostname = @machine.config.vm.hostname
        name = @machine.name
        uuid = @machine.id || self.uuid

        # Get the SSH config from Vagrant
        sshconfig = `vagrant ssh-config --host #{hostname}`
        # Trim Whitespace from end
        sshconfig = sshconfig.gsub(/^$\n/, '')
        sshconfig = sshconfig.chomp

        %(#{signature(name, uuid)}\n#{sshconfig}\n#{signature(name, uuid)})
      end

      def ssh_config_entry_exist?
        hostname = @machine.config.vm.hostname
        name = @machine.name
        uuid = @machine.id

        content = File.read(ssh_user_config_path)
        entry_pattern = ssh_config_entry_pattern(hostname, name, uuid)

        content.match(/#{entry_pattern}/)
      end

      def append_to_ssh_config(content)
        return if content.length == 0

        unless File.writable_real?(ssh_user_config_path)
          logging(:info, 'This operation requires administrative access. You may ' +
                   'skip it by manually adding equivalent entries to the config file.')
          return
        end

        logging(:info, "Writing the following config to (#{ssh_user_config_path})")
        logging(:info, content, false)
        append_line_feed_to_end_of_file_if_not_exist(ssh_user_config_path)
        hostsFile = File.open(ssh_user_config_path, 'a') do |f|
          f.write(content)
        end
      end

      def remove_from_ssh_config
        unless File.writable_real?(ssh_user_config_path)
          logging(:info, 'This operation requires administrative access. You may ' +
                   'skip it by manually adding equivalent entries to the config file.')
          return
        end

        uuid = @machine.id || @machine.config.mutagen_utilize.id
        hashedId = Digest::MD5.hexdigest(uuid)

        content = File.read(ssh_user_config_path)
        new_content = content.gsub(/^(# VAGRANT: #{hashedId}).*?(^# VAGRANT: #{hashedId}).*$/m, '')
        File.open(ssh_user_config_path, 'w') do |f|
          f.puts(new_content)
        end
      end

      def append_line_feed_to_end_of_file_if_not_exist(path)
        # Set "true" as default because when it doesn't know if file is ending with line feed or not, it should not add the line feed.
        is_file_end_with_line_feed = true
        File.open(path, 'a+') do |f|
          if f.seek(-1, IO::SEEK_END) == 0
            c = f.getc
            is_file_end_with_line_feed = false if c != "\r" && c != "\n"
          end
        end
        return if is_file_end_with_line_feed

        File.open(path, 'a') do |f|
          f.puts('')
        end
      end

      DISCARD_STDOUT = Vagrant::Util::Platform.windows? ? '>nul'  : '>/dev/null'
      DISCARD_STDERR = Vagrant::Util::Platform.windows? ? '2>nul' : '2>/dev/null'
      MUTAGEN_METHODS = {
        "mutagen_project_started?":  "mutagen project list #{DISCARD_STDOUT} #{DISCARD_STDERR}", # mutagen project list returns 1 on error when no project is started
        "start_mutagen_project":     "mutagen project start",
        "terminate_mutagen_project": "mutagen project terminate",
        "list_mutagen_project":      "mutagen project list"
      }
      MUTAGEN_METHODS.each_pair do |method_name, command|
        define_method method_name do
          system(command)
        end
      end
    end
  end
end
