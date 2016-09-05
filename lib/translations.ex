defmodule Translations do
  require EEx

  @root_dir File.cwd!
  @template Path.join(@root_dir, "lib/template.eex")

  @moduledoc """
  Usage: translations <PATH> [OPTIONS]

  Options:
      -l, --languages es,it,ja         Which language will be included
      -h, --help                       Show the available options

  The purpose of this executable is to generate Translation.elm.

  Translation.elm is needed by px_*_ui components in order to show translated content.
  This executable writes to stdin, here's an example usage:

      ./translations path/to/gettext --languages es_ES,it_IT,ja_JP > src/Translation.elm

  The first argument is the path to the gettext folder.
  You can provide languages via the --languages option.
  If you don't, all the available languages will be included.

  The English language is also included by default, so you don't have to
  provide it in the options.
  """
  def main(argv) do
    argv
    |> parse_args
    |> generate
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
        %{ path: path, languages: String.split(languages, ",") }

      { _, [ path ], _ } ->
        %{ path: path, languages: [] }

      { _, _, _ } -> :help
    end
  end

  @doc """
  Displays a help message.
  """
  def generate(:help) do
    IO.puts @moduledoc
    System.halt(0)
  end

  @doc """
  Generates Translation.elm according to the chosen languages and the path to
  gettext folder.
  """
  def generate(%{path: path, languages: languages}) do
    selected_languages =
      if Enum.empty? languages do
        available_languages
      else
        Enum.filter(available_languages, fn
          {locale, _} -> Enum.member? languages, locale
        end)
      end

    translations = Enum.reduce(selected_languages, [], fn
      {locale, {language, _}}, acc ->
        translations =
          parse_translations_file("#{path}/#{locale}/LC_MESSAGES/default.po")
          |> Enum.reduce([], fn(translation, acc) ->
            [ { List.first(translation.msgid), { language, List.first(translation.msgstr) } } ] ++ acc
          end)

        acc ++ translations
    end)

    translations =
      parse_translations_file("#{path}/default.pot")
      |> collect_keys
      |> Enum.reduce([], fn(key, acc) ->
           translations = for {^key, t} <- translations, do: t

           acc ++ [{key, translations}]
         end)

    IO.puts EEx.eval_file @template, [languages: selected_languages, translations: translations]
  end


  defp parse_translations_file(path) do
    case Gettext.PO.parse_file path do
      {:ok, parsed} ->
        parsed.translations

      {:error, line, reason} ->
        raise ~s([#{reason}] Error while parsing the file: "#{path}:#{line}")

      {:error, reason} ->
        raise ~s([#{reason}] Error while opening the file. Maybe the path "#{path}" is incorrect?)
    end
  end


  defp collect_keys(translations) do
    Enum.reduce(translations, [], fn(translation, acc) ->
      acc ++ [ List.first(translation.msgid) ]
    end)
  end


  defp available_languages do
    [ {"it_IT", {"Italian", "Italiano"}},
        {"ja_JP", {"Japanese", "日本語"}},
        {"es_ES", {"Spanish", "Español"}}]
  end
end
