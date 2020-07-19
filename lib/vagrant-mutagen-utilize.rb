# frozen_string_literal: true

require 'vagrant_mutagen_utilize/version'
require 'vagrant_mutagen_utilize/plugin'

module Vagrant
  module Mutagen
    # Utilize
    module Utilize
      def self.source_root
        @source_root ||= Pathname.new(File.expand_path('..', __dir__))
      end
    end
  end
end
