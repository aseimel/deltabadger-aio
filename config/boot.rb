ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'logger'         # Ruby 3.2+ extracted logger from stdlib; load before Rails
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
