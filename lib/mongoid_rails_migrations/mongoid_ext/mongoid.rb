# encoding: utf-8

module Mongoid #:nodoc
  class << self
    # Specify whether or not to use timestamps for migration versions
    cattr_accessor(:timestamped_migrations , :instance_writer => true) {|timestamped_migrations| timestamped_migrations = true }
  end
end