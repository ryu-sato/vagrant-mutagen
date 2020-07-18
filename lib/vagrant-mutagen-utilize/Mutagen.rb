module VagrantPlugins
  module Mutagen
    class Mutagen
      DISCARD_STDOUT = Vagrant::Util::Platform.windows? ? '>nul'  : '>/dev/null'
      DISCARD_STDERR = Vagrant::Util::Platform.windows? ? '2>nul' : '2>/dev/null'

      def initialize(machine, ui)
        @machine = machine
        @ui = ui
      end

      def append_ssh_config_entry
        @ui.info '[vagrant-mutagen-utilize] Checking for SSH config entries'

        hostname = @machine.config.vm.hostname
        name = @machine.name
        uuid = @machine.id

        if config_entry_exist?(hostname, name, uuid)
          @ui.info "[vagrant-mutagen-utilize]   updating SSH Config entry for: #{hostname}"
          remove_from_ssh_config
        else
          @ui.info "[vagrant-mutagen-utilize]   adding entry to SSH config for: #{hostname}"
        end
        append_to_ssh_config(ssh_config_entry(hostname, name, uuid))
      end

      def append_to_ssh_config(content)
        return if content.length == 0

        unless File.writable_real?(ssh_user_config_path)
          @ui.info '[vagrant-mutagen-utilize] This operation requires administrative access. You may ' +
                   'skip it by manually adding equivalent entries to the config file.'
          return
        end

        @ui.info "[vagrant-mutagen-utilize] Writing the following config to (#{ssh_user_config_path})"
        @ui.info content
        append_line_feed_to_end_of_file_if_not_exist(ssh_user_config_path)
        hostsFile = File.open(ssh_user_config_path, 'a') do |f|
          f.write(content)
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

      def config_entry_exist?(hostname, name, uuid)
        content = File.read(ssh_user_config_path)
        entry_pattern = ssh_config_entry_pattern(hostname, name, uuid)

        content.match(/#{entry_pattern}/)
      end

      def ssh_config_entry(hostname, name, uuid = self.uuid)
        # Get the SSH config from Vagrant
        sshconfig = `vagrant ssh-config --host #{hostname}`
        # Trim Whitespace from end
        sshconfig = sshconfig.gsub(/^$\n/, '')
        sshconfig = sshconfig.chomp

        %(#{signature(name, uuid)}\n#{sshconfig}\n#{signature(name, uuid)})
      end

      def cacheConfigEntries
        @machine.config.mutagen_utilize.id = @machine.id
      end

      def remove_ssh_config_entry
        if !@machine.id && !@machine.config.mutagen_utilize.id
          @ui.info '[vagrant-mutagen-utilize] No machine id, nothing removed from #ssh_user_config_path'
          return
        end
        return unless config_entry_exist?(@machine.config.vm.hostname, @machine.name, @machine.id)

        @ui.info '[vagrant-mutagen-utilize] Removing SSH config entry'
        remove_from_ssh_config
      end

      def remove_from_ssh_config
        unless File.writable_real?(ssh_user_config_path)
          @ui.info '[vagrant-mutagen-utilize] This operation requires administrative access. You may ' +
                   'skip it by manually adding equivalent entries to the config file.'
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

      # Create a regular expression that will match the vagrant-mutagen-utilize signature
      def ssh_config_entry_pattern(hostname, _name, uuid = self.uuid)
        hashedId = Digest::MD5.hexdigest(uuid)
        Regexp.new("^# VAGRANT: #{hashedId}.*$\nHost #{hostname}.*$")
      end

      def signature(name, uuid = self.uuid)
        hashedId = Digest::MD5.hexdigest(uuid)
        %(# VAGRANT: #{hashedId} (#{name}) / #{uuid})
      end

      def plugin_orchestrate?
        @machine.config.mutagen_utilize.orchestrate == true
      end

      def ssh_user_config_path
        @machine.config.mutagen_utilize.ssh_user_config_path
      end

      def start_orchestration
        daemonCommand = 'mutagen daemon start'
        projectStartedCommand = "mutagen project list #{DISCARD_STDOUT} #{DISCARD_STDERR}"
        projectStartCommand = 'mutagen project start'
        projectStatusCommand = 'mutagen project list'
        @ui.error '[vagrant-mutagen-utilize] Failed to start mutagen daemon' unless system(daemonCommand)
        unless system(projectStartedCommand) # mutagen project list returns 1 on error when no project is started
          @ui.info '[vagrant-mutagen-utilize] Starting mutagen project orchestration (config: /mutagen.yml)'
          unless system(projectStartCommand)
            @ui.error '[vagrant-mutagen-utilize] Failed to start mutagen project (see error above)'
          end
        end
        system(projectStatusCommand) # show project status to indicate if there are conflicts
      end

      def terminate_orchestration
        projectStartedCommand = "mutagen project list #{DISCARD_STDOUT} #{DISCARD_STDERR}"
        projectTerminateCommand = 'mutagen project terminate'
        projectStatusCommand = "mutagen project list #{DISCARD_STDERR}"
        if system(projectStartedCommand) # mutagen project list returns 1 on error when no project is started
          @ui.info '[vagrant-mutagen-utilize] Stopping mutagen project orchestration'
          unless system(projectTerminateCommand)
            @ui.error '[vagrant-mutagen-utilize] Failed to stop mutagen project (see error above)'
          end
        end
        system(projectStatusCommand)
      end
    end
  end
end
