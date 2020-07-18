require 'vagrant-mutagen-utilize/version'
require 'vagrant-mutagen-utilize/plugin'

module Vagrant
  module Mutagen
    module Utilize
      def self.source_root
        @source_root ||= Pathname.new(File.expand_path('..', __dir__))
      end
    end
  end
end
