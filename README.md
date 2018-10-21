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

This task checks diffs between a current schema and a schema which migrated and rollbacked. If there are diffs, it will print the diffs and exit with exit status `1`.

```bash
$ rails db:migrate:check_reversibility CURRENT_VERSION=20181020120000
```

`CURRENT_VERSION` environment variable specifies a current schema version before migration. If it isn't passed, a current schema version will be the one of local database.

## Example

if you create a following migration file,

```rb
class ChangeEmailLimitAtUsers < ActiveRecord::Migration[5.2]
  def up
    change_column :users, :email, :string, limit: 50
  end

  def down
    change_column :users, :email, :string
  end
end
```

when you run `db:migrate:check_reversibility` task, this task will run `db:migrate` and `db:rollback` and print diffs between a current schema and a rollbacked schema.

```bash
$ rails db:migrate:check_reversibility
== +20181020041241 ============================================================
 # This file is auto-generated from the current state of the database. Instead
 # of editing this file, please use the migrations feature of Active Record to
 # incrementally modify your database, and then regenerate this schema definition.
 #
 # Note that this schema.rb definition is the authoritative source for your
 # database schema. If you need to create the application database on another
 # system, you should be using db:schema:load, not running all the migrations
 # from scratch. The latter is a flawed and unsustainable approach (the more migrations
 # you'll amass, the slower it'll run and the greater likelihood for issues).
 #
 # It's strongly recommended that you check this file into your version control system.

 ActiveRecord::Schema.define(version: 2018_10_17_064352) do

   create_table "users", force: :cascade do |t|
     t.string "name"
-    t.string "email"
+    t.string "email", limit: 50
     t.datetime "created_at", null: false
     t.datetime "updated_at", null: false
   end

 end
== -20181019134724 ============================================================
```
