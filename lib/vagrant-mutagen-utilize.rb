require 'vagrant-mutagen-utilize/version'
require 'vagrant-mutagen-utilize/plugin'

module VagrantPlugins
  module Mutagen
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('..', __dir__))
    end
  end
end
