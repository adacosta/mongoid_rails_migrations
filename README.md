# Data migrations for Mongoid. [![Build Status](https://github.com/adacosta/mongoid_rails_migrations/actions/workflows/test.yaml/badge.svg?branch=master)](https://github.com/adacosta/mongoid_rails_migrations/actions/workflows/test.yaml)

Gemfile:
```ruby
gem "mongoid_rails_migrations"
```

Create migration
```
$ rails generate mongoid:migration <your_migration_name_here>
```

Run migrations:
```
$ rails db:migrate
$ rails db:migrate:down VERSION=
$ rails db:migrate:up VERSION=
$ rails db:rollback
$ rails db:rollback_to VERSION=
$ rails db:migrate:redo
$ rails db:migrate:reset
$ rails db:migrate:status
$ rails db:reseed (handled by mongoid)
$ rails db:version
```

If you want to use output migration use the hook `after_migrate`
```
Mongoid::Migration.after_migrate = ->(output, name, direction, crash) {
  upload_to_s3(name, output, direction) if crash == false
}
```

To override the default migrations path (`db/migrate`), add the following line to your `application.rb` file:
```
Mongoid::Migrator.migrations_path = ['foo/bar/db/migrate', 'path/to/db/migrate']
```

## Multi databases support

Default behavior is to store migrations in the `default` client database but for projects that require horizontal scalabilty, this gem supports migrations [sharding](https://en.wikipedia.org/wiki/Shard_\(database_architecture\)).

To generate a migration that can be run on shards, suffix the migration generator command with `--shards` like:

```
$ rails generate mongoid:migration <your_migration_name_here> --shards
```

The migration will be created and stored in `db/migrate/shards` folder.

With the following configuration:

```yaml
production:
  clients:
    default:
      database: my_production_db
      hosts:
        - 4.2.4.2:27017
    shard1:
      database: my_shard1_production_db
      hosts:
        - 5.3.5.3:27017
    shard2:
      database: my_shard2_production_db
      hosts:
        - 6.4.6.4:27017
```

In order to manage a sharded migration, run tasks with the `MONGOID_CLIENT_NAME` environment variable:

```
$ rails db:migrate MONGOID_CLIENT_NAME=shard2
```

The shards migrations will be executed and entries will be added in the `my_shard2_production_db` database.

All the rake tasks support the `MONGOID_CLIENT_NAME` environment variable.

To make shards migrations the default migration type, add the following line in your config:

```ruby
# config/application.rb

Mongoid.configure.shards_migration_as_default = true
```

Global migrations can still be created with the `--no-shards` option.

# Compatibility

* `1.5.x` targets Mongoid >= `5.0` and Rails >= `4.2`
* `1.4.x` targets Mongoid >= `4.0` and Rails >= `4.2`
* `1.0.0` targers Mongoid >= `3.0` and Rails >= `3.2`
* `0.0.14` targets Mongoid >= `2.0` and Rails >= `3.0` (but < `3.2`)

# Changelog

## Unreleased

[Compare master with 1.6.0](https://github.com/adacosta/mongoid_rails_migrations/compare/v1.6.0...master)

## 1.6.0
_12/09/2024_
* Remove unnecessary purge, setup, reset, etc. rake tasks because they are already defined by Mongoid (#60)
* Minor tests improvements
* Rejects Mongoid 9.0 for the moment because it broke client override isolation: https://jira.mongodb.org/browse/MONGOID-5815
* Setup Github Actions to replace Travis CI (because It could not be fixed without the maintainer, see #55)
* Remove some legacy comments and unreachable code

## 1.5.0
_26/03/2021_
* Add support of multi databases
* Shards migrations can now be stored in a `shards` subfolder inside the migration folder
* All Rake tasks now support a custom client with the `MONGOID_CLIENT_NAME` environment variable

## 1.4.0
_08/01/2021_
* The hook `after_migrate` can be use when migration crash (#56)

## 1.3.0
_17/12/2020_
* Rake Tasks updated to use `migrations_path` instead of hardcoded path (#52)
* Added `after_migrate` hook(#54)

## 1.2.1
_17/01/2019_
* Fix on `db:migrate:status` task to behave like the `ActiveRecord` version (#47)

## 1.2.0
_23/10/2018_
* Added a `rollback_to` task to rollback to a particular version (#17)
* Added a `db:migrate:status` task to list pending migrations (#46)

## 1.1.1
_18/08/2015_
* Added support for Rails5
* First version in Changelog

# Tests

```
$ bundle exec rake
```

# Credits to

* rails
* mongoid
* contributions from the community (git log)

Much of this gem simply modifies existing code from both projects.
With that out of the way, on to the license.

# License (MIT)

Copyright © 2013: Alan Da Costa

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

The software is provided 'as is', without warranty of any kind, express or implied, including but not limited to the warranties of
merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any
claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the
software or the use or other dealings in the software.
