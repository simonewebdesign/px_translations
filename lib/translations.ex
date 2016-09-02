defmodule Translations do
  require EEx

  @root_dir File.cwd!
  @template Path.join(@root_dir, "lib/template.eex")

  @moduledoc """
  Usage: translations [PATH] [OPTIONS]

  Options:
      -l, --languages es,it,ja         Which language will be included
      -h, --help                       Show the available options

  The purpose of this executable is to generate Translation.elm.

  Translation.elm is needed by px_*_ui components in order to show translated content.
  This executable writes to stdin, here's an example usage:

      ./translation.rb --languages es,it,ja > src/Translation.elm

  The first argument is the path to the gettext folder (i.e. the one containing *.po files).
  It's an optional argument, if you don't provide it (like in the example above)
  we assume it's the current folder.

  You can provide languages via the --languages option.
  If you don't, all the available languages will be included.

  The English language is also included by default, so you don't have to
  provide it in the options.
  """
  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can contain:
       -h or --help
       -l or --languages
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv,
      switches: [ help: :boolean,
                  languages: :string ],
      aliases:  [ h: :help,
                  l: :languages ])
    case parse do
      { [ help: true ], _, _ } -> :help

      { [ languages: languages ], [ path ], _ } ->
          %{ languages: String.split(languages, ","),
             path: path
           }

      { [ languages: languages ], _, _ } ->
        %{ languages: String.split(languages, ",") }

      { _, [ path ], _ } ->
        %{ path: path }

      { _, _, _ } -> :help
    end
  end

  @doc """
  Displays a help message.
  """
  def process(:help) do
    IO.puts @moduledoc
    System.halt(0)
  end

  def process(%{languages: languages, path: path}) do
    path = if path == "", do: ".", else: path
    generate(languages, path)
  end

  def process(%{languages: languages}) do
    path = "."
    generate(languages, path)
  end

  def process(%{path: path}) do
    path = if path == "", do: ".", else: path
    generate([], path)
  end

  @doc """
  Generates Translation.elm according to the chosen languages and the path to
  gettext folder.
  """
  def generate(languages, path) do
    available_languages =
      [ {"it_IT", {"Italian", "Italiano"}},
        {"ja_JP", {"Japanese", "日本語"}},
        {"es_ES", {"Spanish", "Español"}}]

    selected_languages =
      if Enum.empty? languages do
        available_languages
      else
        Enum.filter(available_languages, fn
          {locale, _} -> Enum.member? languages, locale
        end)
      end

    {:ok, english_po_file} = Gettext.PO.parse_file "#{path}/default.pot"


    keys = Enum.reduce(english_po_file.translations, [], fn(item, acc) ->
      acc ++ [List.first(item.msgid)]
    end)


    translations = Enum.reduce(selected_languages, [], fn
      {locale, {language, _}}, translations_acc ->
        {:ok, po} = Gettext.PO.parse_file "#{path}/#{locale}/LC_MESSAGES/default.po"

        translations = Enum.reduce(po.translations, [], fn(translation, acc) ->
          [{ List.first(translation.msgid), { language, List.first(translation.msgstr) } }] ++ acc
        end)

        translations_acc ++ translations
    end)


    translations = Enum.reduce(keys, [], fn(key, acc) ->
      translations = for {^key, t} <- translations, do: t

      acc ++ [{key, translations}]
    end)

    IO.puts EEx.eval_file @template, [languages: selected_languages, translations: translations]
  end
end
