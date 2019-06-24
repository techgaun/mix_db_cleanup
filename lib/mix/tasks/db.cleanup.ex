defmodule Mix.Tasks.Db.Cleanup do
  use Mix.Task
  import Mix.Ecto

  @shortdoc "Performs database cleanup by deleting older rows in a specified table"

  @moduledoc """
  The db.cleanup task deletes old rows from a table.
  By default, it deletes data from events that are older than 7 days.

  ## Examples

      mix db.cleanup
      mix db.cleanup -t devices -n 30

  ## Command Line Options
    * `--repo` / `-r` - the repo to use (defaults to current app's repo)
    * `--table` / `-t` - the table to cleanup
    * `--num` / `-n` - day count. data before (current date - n) will be deleted
    * `--count` / `-c` - number of first rows to delete (overrides day based deletion)
  """

  @doc false
  def run(args) do
    repos = parse_repo(args)

    {opts, _, _} =
      OptionParser.parse(
        args,
        switches: [table: :string, num: :integer, force: :boolean, count: :integer],
        aliases: [t: :table, n: :num, f: :force, c: :count]
      )

    if Mix.env() == :prod do
      case opts[:force] do
        true ->
          nil

        _ ->
          Mix.shell().info("You need to specify --force / -f for prod environment")
          System.halt(1)
      end
    end

    table = opts[:table] || "events"

    n =
      case opts[:num] |> is_nil do
        true -> 7
        false -> opts[:num]
      end

    Enum.each(repos, fn repo ->
      ensure_repo(repo, args)
      {:ok, _, _} = Ecto.Migrator.with_repo(
        repo,
        fn ->
          count = opts[:count]

          query =
            case count |> is_nil do
              true ->
                Mix.shell().info(
                  "Deleting rows from #{inspect(table)} older than #{inspect(n)} days..."
                )

                by_date_query(table, n)

              _ ->
                Mix.shell().info("Deleting first #{inspect(count)} data from #{inspect(table)}...")
                n_data_query(table, count)
            end

          delete_data(repo, query)
        end
      )
    end)
  end

  defp by_date_query(table, n) do
    n = n * 86_400

    n_date =
      DateTime.utc_now()
      |> DateTime.to_unix(:second)
      |> Kernel.-(n)
      |> DateTime.from_unix!()

    "DELETE FROM #{table} WHERE inserted_at < '#{n_date}'"
  end

  defp n_data_query(table, n) do
    "DELETE FROM #{table} where id in (select id from #{table} order by inserted_at limit #{n})"
  end

  defp delete_data(repo, query) do
    query = Ecto.Adapters.SQL.query(repo, query, [])

    case query do
      {:ok, result} -> Mix.shell().info("Deleted #{result.num_rows} rows")
      _ -> Mix.shell().info("An error occurred when trying to delete data")
    end
  end
end
