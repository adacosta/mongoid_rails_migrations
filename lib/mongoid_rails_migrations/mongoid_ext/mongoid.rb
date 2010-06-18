# encoding: utf-8

module Mongoid #:nodoc
  class Config  #:nodoc
    # Specify whether or not to use timestamps for migration versions
    attr_accessor :timestamped_migrations
    
    def reset
      @timestamped_migrations = true
    end
  end
end