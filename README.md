# reversibility_checker

## Install

```rb
group :development do
  gem "reversibility_checker"
end
```

## Usage

```bash
$ rails db:migrate:check_reversibility
```

This task check diffs between a current schema and a schema which migrated and rollbacked. If there are diffs, it will print the diffs and exit with exit status `1`.
