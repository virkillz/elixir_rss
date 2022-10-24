defmodule ElixirRss.Helpers.Sanitizers.HTML do
  @moduledoc false

  import HtmlSanitizeEx.Scrubber.Meta
  # alias HtmlSanitizeEx.Scrubber.Meta

  @valid_schemes ["http", "https"]

  # Removes any CDATA tags before the traverser/scrubber runs.
  remove_cdata_sections_before_scrub()

  strip_comments()

  allow_tag_with_uri_attributes("a", ["href"], @valid_schemes)
  allow_tag_with_these_attributes("a", ["name", "title"])

  allow_tag_with_these_attributes("b", [])
  allow_tag_with_these_attributes("blockquote", [])
  allow_tag_with_these_attributes("br", [])
  allow_tag_with_these_attributes("code", [])
  allow_tag_with_these_attributes("del", [])
  allow_tag_with_these_attributes("em", [])
  allow_tag_with_these_attributes("h1", [])
  allow_tag_with_these_attributes("h2", [])
  allow_tag_with_these_attributes("h3", [])
  allow_tag_with_these_attributes("h4", [])
  allow_tag_with_these_attributes("h5", [])
  allow_tag_with_these_attributes("hr", [])
  allow_tag_with_these_attributes("i", [])

  allow_tag_with_uri_attributes("img", ["src"], @valid_schemes)
  allow_tag_with_these_attributes("img", [])

  allow_tag_with_these_attributes("li", [])
  allow_tag_with_these_attributes("ol", [])
  allow_tag_with_these_attributes("p", [])
  allow_tag_with_these_attributes("pre", [])
  allow_tag_with_these_attributes("span", [])
  allow_tag_with_these_attributes("strong", [])
  allow_tag_with_these_attributes("table", [])
  allow_tag_with_these_attributes("tbody", [])
  allow_tag_with_these_attributes("td", [])
  allow_tag_with_these_attributes("th", [])
  allow_tag_with_these_attributes("thead", [])
  allow_tag_with_these_attributes("tr", [])
  allow_tag_with_these_attributes("u", [])
  allow_tag_with_these_attributes("ul", [])

  allow_tag_with_uri_attributes("video", ["src"], @valid_schemes)

  allow_tag_with_these_attributes("video", [
    "lang",
    "title",
    "translate",
    "poster",
    "preload",
    "muted",
    "controls",
    "width",
    "height"
  ])

  allow_tag_with_uri_attributes("source", ["src"], @valid_schemes)
  allow_tag_with_these_attributes("source", ["lang", "title", "translate", "type", "media"])

  allow_tag_with_these_attributes("iframe", [
    "frameborder",
    "webkitAllowFullScreen",
    "mozallowfullscreen",
    "allowFullScreen",
    "width",
    "height"
  ])

  def scrub_attribute("iframe", {"src", uri}) do
    valid_schema =
      if String.match?(uri, @protocol_separator) do
        case Regex.run(@scheme_capture, uri) do
          [_, scheme, _] ->
            Enum.any?(@valid_schemes, fn x -> x == scheme end)

          nil ->
            false
        end
      else
        true
      end

    if valid_schema && String.match?(uri, ~r/http.?:\/\/(www\.)?youtu(be\.com|\.be)\/embed/mi),
      do: {"src", uri}
  end

  strip_everything_not_covered()
end
