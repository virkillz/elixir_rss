defmodule ElixirRss.Parsers.RSS2 do
  @moduledoc false

  import SweetXml
  import ElixirRss.Helpers.Xml

  @schema [
    title: ~x'/rss/channel/title/text()'s |> transform_by(&strip/1),
    description: ~x'/rss/channel/description/text()'s |> transform_by(&strip/1),
    url: ~x'/rss/channel/link/text()'s |> transform_by(&strip/1),
    updated: ~x'/rss/channel/pubDate/text()'s |> transform_by(&parse_date/1),
    rss_updated: ~x'/rss/channel/lastBuildDate/text()'s |> transform_by(&parse_date/1),
    entries: [
      ~x'/rss/channel/item'l,
      id: ~x'./guid/text()'s |> transform_by(&strip/1),
      title: ~x'./title/text()'s |> transform_by(&strip/1),
      url: ~x'./link/text()'s |> transform_by(&strip/1),
      rss_url: ~x'./atom:link/@href's |> transform_by(&strip/1),
      url_orig: ~x'./feedburner:origLink/text()'s |> transform_by(&strip/1),
      content: ~x'./description/text()'s |> transform_by(&strip/1),
      image_thumbnail: ~x'./media:thumbnail/@url's,
      image_content: ~x'./media:*/@url's,
      image_bnmedia: ~x'./bnmedia:post-thumbnail/bnmedia:url/text()'s,
      encoded_content: ~x'./content:encoded/text()'s |> transform_by(&strip/1),
      updated: ~x'./pubDate/text()'s |> transform_by(&parse_date/1)
    ]
  ]

  def valid?(doc) do
    doc |> xpath(~x"/rss"e) != nil
  end

  def parse(doc, url) do
    feed = SweetXml.xmap(doc, @schema)

    # Need to get the real feed url, so the relative uris can be composed correctly
    url = get_feed_url(feed, url)
    base_url = get_base_url(url)
    updated = get_feed_date(feed)

    parsed_feed = %{
      id: get_feed_id(feed) || "",
      title: get_feed_title(feed) || url,
      description: get_feed_description(feed) || "",
      url: url,
      site_url: url,
      updated: updated,
      entries: feed.entries |> Enum.map(&get_entry(&1, base_url, updated))
    }

    {:ok, parsed_feed}
  end

  # --

  defp get_feed_id(feed) do
    cond do
      "" != feed.url -> feed.url
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
      "" != feed.description -> feed.description
      true -> nil
    end
  end

  defp get_feed_url(feed, url) do
    cond do
      "" != feed.url -> feed.url |> expand_relative_url(get_base_url(url))
      true -> url
    end
  end

  defp get_feed_date(feed) do
    cond do
      feed.updated -> feed.updated
      feed.rss_updated -> feed.rss_updated
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
      image: get_entry_image(entry),
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
      "" != entry.url_orig -> entry.url_orig |> expand_relative_url(base_url)
      "" != entry.url -> entry.url |> expand_relative_url(base_url)
      "" != entry.rss_url -> entry.rss_url |> expand_relative_url(base_url)
      true -> ""
    end
  end

  defp get_entry_content(entry) do
    cond do
      "" != entry.encoded_content -> entry.encoded_content
      "" != entry.content -> entry.content
      true -> ""
    end
  end

  defp get_entry_image(entry) do
    cond do
      "" != entry.image_thumbnail -> entry.image_thumbnail
      "" != entry.image_content -> entry.image_content
      "" != entry.image_bnmedia -> entry.image_bnmedia
      true -> ""
    end
  end

  defp get_entry_date(entry, feed_date) do
    cond do
      entry.updated -> entry.updated
      true -> feed_date
    end
  end
end
