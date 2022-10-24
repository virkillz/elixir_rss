defmodule ElixirRss do
  @moduledoc """
  ElixirRss is a simple feed parser originally meant to parse the feed from crypto news.

  ## Examples

  ```elixir
  > {:ok, feed} = ElixirRss.fetch_and_parse "https://cointelegraph.com/rss"
  ...

  > {:ok, feed} = ElixirRss.parse "<rss version=\"2.0\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\" ..."
  ...

  > feed.title
  "Cointelegraph.com News"

  > feed.entries |> Enum.map(&(&1.title))
  ["Kazakhstan among top 3 Bitcoin mining destinations after US and China", "3Commas issues security alert as FTX deletes API keys following hack", ...]
  ```


  ## Results

  #### Feed
    - `id` feed identifier (usually the site url)
    - `title` feed title
    - `description` feed description
    - `url` feed url
    - `site_url` feed main site url
    - `updated` feed last modification timestamp
    - `entries` entry list

  #### Entry
    - `id` unique identifier (sha256)
    - `title` entry title
    - `url` entry permalink
    - `content` entry content
    - `image` url of the thumbnail
    - `updated` entry publication or modification timestamp
  """
  require Logger

  alias ElixirRss.Helpers.{Fetch, Sanitizer}
  alias ElixirRss.Parsers.{Atom, RSS1, RSS2}

  @doc """
  Parses a `xml` string.

  ## Examples

      iex> ElixirRss.parse "<rss version="2.0"><channel><title>9GAG RSS feed</title><description>Free 9GAG RSS feed</description>..."
      {:ok, %{id: "http://9gagrss.com/", title: "9GAG RSS feed", description: "Free 9GAG RSS feed"...}}

      iex> ElixirRss.parse "foo"
      {:error, :invalid_xml}

      iex> ElixirRss.parse("<!DOCTYPE html><html lang="en"><head><meta charset...")
      {:error, :unknown_feed_format}
  """
  def parse(xml, url \\ "") do
    with {:ok, doc} <- read_xml_doc(xml),
         {:ok, parser} <- select_parser(doc),
         {:ok, feed} <- parser.parse(doc, url) do
      entries =
        feed.entries
        |> Enum.filter(fn e -> e.title && e.content end)
        |> Enum.sort(&(DateTime.compare(&1[:updated], &2[:updated]) != :gt))
        |> Enum.map(&sanitize_entry(&1))

      {:ok, %{feed | entries: entries}}
    end
  end

  @doc """
  Similar to `parse/2` but raises `ArgumentError` if unable to parse the `xml`.

  ## Examples

      iex> ElixirRss.parse! "<rss version="2.0"><channel><title>9GAG RSS feed</title><description>Free 9GAG RSS feed</description>..."
      {:ok, %{id: "http://9gagrss.com/", title: "9GAG RSS feed", description: "Free 9GAG RSS feed"...}}

      iex> ElixirRss.parse! "foo"
      ** (ArgumentError) Not a valid XML
  """
  def parse!(xml, url \\ "") do
    with {:ok, feed} <- parse(xml, url) do
      feed
    else
      _ -> raise ArgumentError, "Not a valid XML"
    end
  end

  @doc """
  Fetches the given `url` and parses the response using `parse/2`.

  ## Examples

      iex> ElixirRss.fetch_and_parse "http://9gagrss.com/feed/"
      %{id: "http://9gagrss.com/", title: "9GAG RSS feed", description: "Free 9GAG RSS feed"...}

      iex> ElixirRss.fetch_and_parse "http://invalid-url"
      {:error, :fetch_error}
  """
  def fetch_and_parse(url) do
    with {:ok, xml} <- Fetch.get(url),
         {:ok, feed} <- parse(xml, url) do
      {:ok, %{feed | url: url}}
    end
  end

  # --

  defp read_xml_doc(xml) do
    try do
      {:ok, SweetXml.parse(xml, quiet: true, namespace_conformant: true)}
    rescue
      FunctionClauseError -> {:error, :invalid_xml}
    catch
      :exit, _ -> {:error, :invalid_xml}
    end
  end

  defp select_parser(doc) do
    cond do
      Atom.valid?(doc) -> {:ok, Atom}
      RSS1.valid?(doc) -> {:ok, RSS1}
      RSS2.valid?(doc) -> {:ok, RSS2}
      true -> {:error, :unknown_feed_format}
    end
  end

  defp sanitize_entry(entry) do
    content =
      (entry.content || "")
      |> Sanitizer.basic_html()

    %{entry | content: content}
  end
end
