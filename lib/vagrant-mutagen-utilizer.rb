# frozen_string_literal: true

require 'vagrant_mutagen_utilizer/version'
require 'vagrant_mutagen_utilizer/plugin'

module Vagrant
  module Mutagen
    # Utilize
    module Utilizer
      def self.source_root
        @source_root ||= Pathname.new(File.expand_path('..', __dir__))
      end
    end
  end
end
