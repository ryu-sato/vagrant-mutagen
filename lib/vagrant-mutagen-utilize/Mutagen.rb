module VagrantPlugins
  module Mutagen
    class Mutagen
      DISCARD_STDOUT = Vagrant::Util::Platform.windows? ? '>nul'  : '>/dev/null'
      DISCARD_STDERR = Vagrant::Util::Platform.windows? ? '2>nul' : '2>/dev/null'

      def initialize(machine, ui)
        @machine = machine
        @ui = ui
      end

      def addConfigEntries
        @ui.info "[vagrant-mutagen-utilize] Checking for SSH config entries"
        # Prepare some needed variables
        uuid = @machine.id
        name = @machine.name
        hostname = @machine.config.vm.hostname
        # New Config for ~/.ssh/config
        newconfig = ''

        # Read contents of SSH config file
        configContents = File.read(ssh_user_config_path)
        # Check for existing entry for hostname in config
        entryPattern = configEntryPattern(hostname, name, uuid)
        if configContents.match(/#{entryPattern}/)
          @ui.info "[vagrant-mutagen-utilize]   updating SSH Config entry for: #{hostname}"
          removeConfigEntries
        else
          @ui.info "[vagrant-mutagen-utilize]   adding entry to SSH config for: #{hostname}"
        end

        # Get SSH config from Vagrant
        newconfig = createConfigEntry(hostname, name, uuid)
        # Append vagrant ssh config to end of file
        addToSSHConfig(newconfig)
      end

      def addToSSHConfig(content)
        return if content.length == 0
        unless File.writable_real?(ssh_user_config_path)
          @ui.info "[vagrant-mutagen-utilize] This operation requires administrative access. You may " +
                     "skip it by manually adding equivalent entries to the config file."
          return
        end

        @ui.info "[vagrant-mutagen-utilize] Writing the following config to (#ssh_user_config_path)"
        @ui.info content
        addLineFeedToFileEndIfNotExist(ssh_user_config_path)
        hostsFile = File.open(ssh_user_config_path, "a") do |f|
          f.write(content)
        end
      end

      def addLineFeedToFileEndIfNotExist(path)
        # Set "true" as default because when it doesn't know if file is ending with line feed or not, it should not add the line feed.
        is_file_end_with_line_feed = true
        File.open(path, "a+") do |f|
          if f.seek(-1, IO::SEEK_END) == 0
            c = f.getc
            if c != "\r" && c != "\n"
              is_file_end_with_line_feed = false
            end
          end
        end
        return if is_file_end_with_line_feed

        File.open(path, "a") do |f|
          f.puts("")
        end
      end

      # Create a regular expression that will match the vagrant-mutagen-utilize signature
      def configEntryPattern(hostname, name, uuid = self.uuid)
        hashedId = Digest::MD5.hexdigest(uuid)
        Regexp.new("^# VAGRANT: #{hashedId}.*$\nHost #{hostname}.*$")
      end

      def createConfigEntry(hostname, name, uuid = self.uuid)
        # Get the SSH config from Vagrant
        sshconfig = `vagrant ssh-config --host #{hostname}`
        # Trim Whitespace from end
        sshconfig = sshconfig.gsub /^$\n/, ''
        sshconfig = sshconfig.chomp
        # Return the entry
        %Q(#{signature(name, uuid)}\n#{sshconfig}\n#{signature(name, uuid)})
      end

      def cacheConfigEntries
        @machine.config.mutagen_utilize.id = @machine.id
      end

      def removeConfigEntries
        if !@machine.id and !@machine.config.mutagen_utilize.id
          @ui.info "[vagrant-mutagen-utilize] No machine id, nothing removed from #ssh_user_config_path"
          return
        end

        @ui.info "[vagrant-mutagen-utilize] Removing SSH config entry"
        configContents = File.read(ssh_user_config_path)
        uuid = @machine.id || @machine.config.mutagen_utilize.id
        hashedId = Digest::MD5.hexdigest(uuid)
        if configContents.match(/#{hashedId}/)
          removeFromConfig
        end
      end

      def removeFromConfig
        unless File.writable_real?(ssh_user_config_path)
          @ui.info "[vagrant-mutagen-utilize] This operation requires administrative access. You may " +
                    "skip it by manually adding equivalent entries to the config file."
          return
        end

        uuid = @machine.id || @machine.config.mutagen_utilize.id
        hashedId = Digest::MD5.hexdigest(uuid)

        content = File.read(ssh_user_config_path)
        new_content = content.gsub(/^(# VAGRANT: #{hashedId}).*?(^# VAGRANT: #{hashedId}).*$/m, '')
        File.open(ssh_user_config_path, "w") do |f|
          f.puts(new_content)
        end
      end

      def signature(name, uuid = self.uuid)
        hashedId = Digest::MD5.hexdigest(uuid)
        %Q(# VAGRANT: #{hashedId} (#{name}) / #{uuid})
      end

      def plugin_orchestrate?
        @machine.config.mutagen_utilize.orchestrate == true
      end

      def ssh_user_config_path
        @machine.config.mutagen_utilize.ssh_user_config_path
      end

      def startOrchestration()
        daemonCommand = "mutagen daemon start"
        projectStartedCommand = "mutagen project list #{DISCARD_STDOUT} #{DISCARD_STDERR}"
        projectStartCommand = "mutagen project start"
        projectStatusCommand = "mutagen project list"
        if !system(daemonCommand)
          @ui.error "[vagrant-mutagen-utilize] Failed to start mutagen daemon"
        end
        if !system(projectStartedCommand) # mutagen project list returns 1 on error when no project is started
          @ui.info "[vagrant-mutagen-utilize] Starting mutagen project orchestration (config: /mutagen.yml)"
          if !system(projectStartCommand)
            @ui.error "[vagrant-mutagen-utilize] Failed to start mutagen project (see error above)"
          end
        end
        system(projectStatusCommand) # show project status to indicate if there are conflicts
      end

      def terminateOrchestration()
        projectStartedCommand = "mutagen project list #{DISCARD_STDOUT} #{DISCARD_STDERR}"
        projectTerminateCommand = "mutagen project terminate"
        projectStatusCommand = "mutagen project list #{DISCARD_STDERR}"
        if system(projectStartedCommand) # mutagen project list returns 1 on error when no project is started
          @ui.info "[vagrant-mutagen-utilize] Stopping mutagen project orchestration"
          if !system(projectTerminateCommand)
            @ui.error "[vagrant-mutagen-utilize] Failed to stop mutagen project (see error above)"
          end
        end
        system(projectStatusCommand)
      end

    end
  end
end
