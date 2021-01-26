class <%= migration_class_name %> < Mongoid::Migration
<%= "  client :#{client_name}\n\n" if client_name %>  def self.up
  end

  def self.down
  end
end