# ElixirRss

ElixirRss is a simple feed parser originally meant to parse the feed from crypto news. The existing Feed parser in elixir is either unnecessarily fast (rust dependant), or doesn't parse image information from RSS. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_rss` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_rss, "~> 0.1.0"}
  ]
end
```

## Usage

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
  - `id` unique identifier (SHA256)
  - `title` entry title
  - `url` entry permalink
  - `content` entry content
  - `image` url of the thumbnail image
  - `updated` entry publication or modification timestamp



Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/elixir_rss>.

