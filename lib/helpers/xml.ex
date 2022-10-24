defmodule ElixirRss.Helpers.Xml do
  @moduledoc false

  @date_patterns [
    "{ISO:Extended}",
    "{ISO:Extended:Z}",
    "{ISO:Basic}",
    "{ISO:Basic:Z}",
    "{RFC1123}",
    "{RFC1123z}",
    "{RFC3339}",
    "{RFC3339z}",
    "{ANSIC}",
    "{UNIX}",
    "{RFC822}",
    "{RFC822z}"
  ]

  def parse_date(str, patterns \\ @date_patterns)

  def parse_date(str, [pattern | patterns]) do
    case Timex.parse(str, pattern) do
      {:ok, date} -> Timex.Timezone.convert(date, "GMT")
      _ -> parse_date(str, patterns)
    end
  end

  def parse_date(_, _), do: nil

  def strip(text) when is_binary(text) do
    text |> String.replace("\r", " ") |> String.replace("\n", " ") |> String.trim()
  end

  def strip(_), do: ""

  def get_base_url(url) do
    %{URI.parse(url) | path: nil, query: nil} |> URI.to_string()
  end

  def expand_relative_url(url, base_url) when is_binary(url) do
    if String.starts_with?(url, ["http://", "https://"]) do
      url
    else
      base_url <> url
    end
  end

  def expand_relative_url(_, _), do: ""
end
