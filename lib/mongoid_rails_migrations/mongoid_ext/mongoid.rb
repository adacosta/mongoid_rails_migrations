# encoding: utf-8
module Mongoid
  # Specify whether or not to use timestamps for migration versions
  Config.option :timestamped_migrations, default: true
  # Specify whether or not to use shards migrations as default type
  Config.option :shards_migration_as_default, default: false
end
