defmodule Issues.CLI do
 
  import Issues.TableFormatter, only: [ print_table_for_columns: 2 ]

  @default_count 4
  
  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating a
  table of the last _n_ issues in a github project
  """


  @doc"""
  Runs the CLI program with the command line args given by the user in a list.
  Returns a tuple of `{ user, project, count }` or `:help` if the user gave
  bad input or they had :help as an input.
  """
  @spec main(list(String.t)) :: list | String.t
  def main(argv) do
    argv
    |> parse_args
    |> process
  end


  @doc """
  `argv` can be -h or --help, which returns :help.
  Otherwise it is a github user name, project name, and (optionally)
  the number of entries to format.
  Return a tuple of `{ user, project, count }`, or `:help` if help was given.
  """
  @spec parse_args(list(String.t)) :: {String.t, String.t, String.t} | atom
  def parse_args(argv) do
    OptionParser.parse(argv, switches: [ help: :boolean],
                             aliases:  [ h: :help      ])
    |> elem(1)
    |> args_to_internal_representation()
  end


  @doc"""
  Handles conditional cases for different valid command line args instead of 
  doing them in a conditional statement inside parse_args/1.
  Calls different clauses depending on the input of the args.
  """
  @spec args_to_internal_representation(list(String.t)) :: {String.t, String.t, String.t} | atom
  @spec args_to_internal_representation(any) :: atom
  def args_to_internal_representation([user, project, count]) do
    { user, project, String.to_integer(count) }
  end

  def args_to_internal_representation([user, project]) do
    { user, project, @default_count }
  end
  
  def args_to_internal_representation(_) do # bad arg or --help
    :help
  end


  @doc"""
  Processes the command line args given to it by run/1.
  This function handles the data and is responsible for returning the final 
  output.
  """
  @spec process(atom) :: String.t
  @spec process({String.t, String.t, String.t}) :: list | String.t
  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response()
    |> sort_into_descending_order()
    |> last(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end


  @doc"""
  Takes the first \"count\" Github issues from the list and returns them 
  in a new sublist.
  """
  @spec last(list, integer) :: list
  def last(list, count) do
    list
    |> Enum.take(count)
    |> Enum.reverse
  end


  @doc"""
  Sorts the list of Github repo issues in descending issue and returns them.
  """
  @spec sort_into_descending_order(list) :: list
  def sort_into_descending_order(list_of_issues) do
    list_of_issues
    |> Enum.sort(fn i1, i2 ->
         i1["created_at"] >= i2["created_at"]
       end)
  end


  @doc"""
  Takes the :ok or :error atom and the list of the HTTP request returned from
  GithubIssues.fetch/2 and returns the body of the request when the response
  is of type 200 (for success) or returns a string containing an error message
  if we get a bad response code.
  """
  @spec decode_response({atom, list}) :: list | String.t
  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    IO.puts "Error fetching from Github: #{error["message"]}"
    System.halt(2)
  end

end
