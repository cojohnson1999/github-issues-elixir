defmodule Issues.GithubIssues do
  
  require Logger

  @user_agent [ {"User-agent", "Elixir dave@pragprog.com"} ]

  # use a module attribute to fetch the value at compile time
  @github_url Application.get_env(:issues, :github_url)


  @doc"""
  Fetches the data of the Github repository of the user and project entered.
  Returns a tuple of :ok and the body of the request if it finds the repo, and 
  it returns :error and the failed body of the request otherwise.
  """
  @spec fetch(String.t, String.t) :: {atom, list}
  def fetch(user, project) do
    Logger.info("Fetching #{user}'s project #{project}")

    issues_url(user, project)
    |> HTTPoison.get(@user_agent)
    |> handle_response
  end


  @doc"""
  Builds the URL to send an HTTP request to using the user and project 
  sent as parameters to fetch/2.
  """
  @spec issues_url(String.t, String.t) :: String.t
  def issues_url(user, project) do
    "#{@github_url}/repos/#{user}/#{project}/issues"
  end


  @doc"""
  Returns a tuple containing :ok or :error depending on the status of the 
  HTTP request, along with the parsed body of the HTTP response.
  """
  @spec handle_response({atom, map}) :: {atom, list}
  def handle_response({ _, %{status_code: status_code, body: body}}) do 
    Logger.info("Got response: status code=#{status_code}")
    Logger.debug(fn -> inspect(body) end)
    {
      status_code |> check_for_error(),
      body        |> Poison.Parser.parse!()
    }
  end


  @doc"""
  Checks for a good response from Github (HTTP response of 200) and returns 
  :ok, or it returns :error on any other value (HTTP response specifically) 
  that gets returned due to error.
  """
  @spec check_for_error(integer) :: atom
  @spec check_for_error(any) :: atom
  defp check_for_error(200), do: :ok
  defp check_for_error(_), do: :error

end
