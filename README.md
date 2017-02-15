# MixDbCleanup

> Mix Task to perform cleanup of Database using ecto 2.x

## Installation

Add `mix_db_cleanup` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:mix_db_cleanup, github: "techgaun/mix_db_cleanup"}]
end
```

## Usage

The `db.cleanup` mix task can be used to cleanup the database table. The intended use was originally for cleaning up older data in `devices_data` in one of our rapidly growing table but can be used for any table. The mix task is known to work with ecto 1.x only.

```shell
$ mix help db.cleanup

                                 mix db.cleanup

The db.cleanup task deletes old rows from a table. By default, it deletes
data from events that are older than 7 days.

Examples

┃ mix db.cleanup
┃ mix db.cleanup -t devices -n 30

Command Line Options

  • --repo / -r - the repo to use (defaults to current app repo)
  • --table / -t - the table to cleanup
  • --num / -n - day count. data before (current date - n) will be deleted
  • --count / -c - number of first rows to delete (overrides day based deletion)
```
