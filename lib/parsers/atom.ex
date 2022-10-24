defmodule ElixirRss.Parsers.Atom do
  @moduledoc false

  import SweetXml
  import ElixirRss.Helpers.Xml

  @schema [
    id:
      ~x'/feed/id/text()'s
      |> add_namespace("", "http://www.w3.org/2005/Atom")
      |> transform_by(&strip/1),
    title:
      ~x'/feed/title/text()'s
      |> add_namespace("", "http://www.w3.org/2005/Atom")
      |> transform_by(&strip/1),
    subtitle:
      ~x'/feed/subtitle/text()'s
      |> add_namespace("", "http://www.w3.org/2005/Atom")
      |> transform_by(&strip/1),
    url: ~x'/feed/link[@rel="self"]/@href's |> add_namespace("", "http://www.w3.org/2005/Atom"),
    url_alts:
      ~x'/feed/link[not(@rel="self") and (@rel="alternate" or @rel="")]/@href'ls
      |> add_namespace("", "http://www.w3.org/2005/Atom"),
    updated:
      ~x'/feed/updated/text()'s
      |> add_namespace("", "http://www.w3.org/2005/Atom")
      |> transform_by(&parse_date/1),
    entries: [
      ~x'/feed/entry'l |> add_namespace("", "http://www.w3.org/2005/Atom"),
      id:
        ~x'./id/text()'s
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&strip/1),
      title:
        ~x'./title/text()'s
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&strip/1),
      url:
        ~x'./link[@rel="alternate" or @rel=""]/@href's
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&strip/1),
      content:
        ~x'./content/text()'s
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&strip/1),
      summary:
        ~x'./summary/text()'s
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&strip/1),
      content_node: ~x'./content/node()'l |> add_namespace("", "http://www.w3.org/2005/Atom"),
      summary_node: ~x'./summary/node()'l |> add_namespace("", "http://www.w3.org/2005/Atom"),
      updated:
        ~x'./updated/text()'s
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&parse_date/1),
      published:
        ~x'./published/text()'s
        |> add_namespace("", "http://www.w3.org/2005/Atom")
        |> transform_by(&parse_date/1)
    ]
  ]

  def valid?(doc) do
    doc |> xpath(~x"/feed"e) != nil
  end

  def parse(doc, url) do
    feed = xmap(doc, @schema)

    # Need to get the real feed url, so the relative uris can be composed correctly
    url = get_feed_url(feed, url)
    base_url = get_base_url(url)
    updated = get_feed_date(feed)

    parsed_feed = %{
      id: get_feed_id(feed) || "",
      title: get_feed_title(feed) || url,
      description: get_feed_description(feed) || "",
      url: url,
      site_url: get_feed_site_url(feed, base_url),
      updated: updated,
      entries: feed.entries |> Enum.map(&get_entry(&1, base_url, updated))
    }

    {:ok, parsed_feed}
  end

  # --

  defp get_feed_id(feed) do
    cond do
      "" != feed.id -> feed.id
      true -> nil
    end
  end

  defp get_feed_title(feed) do
    cond do
      "" != feed.title -> feed.title
      true -> nil
    end
  end

  defp get_feed_description(feed) do
    cond do
      "" != feed.subtitle -> feed.subtitle |> strip
      true -> nil
    end
  end

  defp get_feed_url(feed, url) do
    cond do
      "" != feed.url ->
        feed.url |> expand_relative_url(get_base_url(url))

      length(feed.url_alts) > 0 ->
        feed.url_alts |> Enum.at(0) |> expand_relative_url(get_base_url(url))

      true ->
        url
    end
  end

  defp get_feed_site_url(feed, base_url) do
    cond do
      length(feed.url_alts) > 0 -> feed.url_alts |> Enum.at(0) |> expand_relative_url(base_url)
      true -> base_url
    end
  end

  defp get_feed_date(feed) do
    cond do
      feed.updated -> feed.updated
      true -> Timex.now()
    end
  end

  defp get_entry(entry, base_url, feed_date) do
    title = get_entry_title(entry)
    url = get_entry_url(entry, base_url)
    content = get_entry_content(entry)

    id = get_entry_id(entry) || title <> url <> content

    %{
      id: :crypto.hash(:sha256, id) |> Base.encode16(),
      title: (title != "" && title) || url,
      url: url,
      content: content,
      updated: get_entry_date(entry, feed_date)
    }
  end

  defp get_entry_id(entry) do
    cond do
      "" != entry.id -> entry.id
      true -> nil
    end
  end

  defp get_entry_title(entry) do
    cond do
      "" != entry.title -> entry.title
      true -> ""
    end
  end

  defp get_entry_url(entry, base_url) do
    cond do
      "" != entry.url -> entry.url |> expand_relative_url(base_url)
      true -> ""
    end
  end

  defp get_entry_content(entry) do
    cond do
      "" != entry.content ->
        entry.content

      "" != entry.summary ->
        entry.summary

      [] != entry.content_node ->
        entry.content_node |> :xmerl.export_simple_content(:xmerl_xml) |> to_string |> strip

      [] != entry.summary_node ->
        entry.summary_node |> :xmerl.export_simple_content(:xmerl_xml) |> to_string |> strip

      true ->
        ""
    end
  end

  defp get_entry_date(entry, feed_date) do
    cond do
      entry.updated -> entry.updated
      entry.published -> entry.published
      true -> feed_date
    end
  end
end
