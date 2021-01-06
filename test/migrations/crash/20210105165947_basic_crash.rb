class BasicCrash < Mongoid::Migration
  def self.up
    raise "Crash migration"
  end

  def self.down
    raise "Crash reverting"
  end
end