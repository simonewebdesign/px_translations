defmodule TranslationsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @path "../px_data_capture/priv/gettext"


  test "generates Italian" do
    fun = fn ->
      assert Translations.generate(%{path: @path, languages: ["it_IT"]}) == :ok
    end

    assert Regex.match?(~r/Italiano/, capture_io(fun))
  end


  test "generates all languages when no languages provided" do
    fun = fn ->
      assert Translations.generate(%{path: @path, languages: []}) == :ok
    end

    stdout = capture_io(fun)

    assert Regex.match?(~r/Italiano/, stdout)
    assert Regex.match?(~r/日本語/, stdout)
    assert Regex.match?(~r/Español/, stdout)
  end

end
