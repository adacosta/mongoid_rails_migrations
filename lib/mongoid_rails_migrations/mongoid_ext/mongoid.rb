# encoding: utf-8
require 'mongoid'

module Mongoid #:nodoc
  class << self

    ##
    # :singleton-method:
    # Specify whether or not to use timestamps for migration versions
    cattr_accessor(:timestamped_migrations , :instance_writer => true) {|sym| sym = true }
    # @@timestamped_migrations = true
  end
end