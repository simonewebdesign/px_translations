defmodule TranslationsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @path "../../px_data_capture/priv/gettext"


  test "generates Italian" do
    fun = fn ->
      assert Translations.generate(["it_IT"], @path) == :ok
    end

    assert Regex.match?(~r/Italiano/, capture_io(fun))
  end


  test "generates all languages when no option provided" do
    fun = fn ->
      assert Translations.generate([], @path) == :ok
    end

    stdout = capture_io(fun)

    assert Regex.match?(~r/Italiano/, stdout)
    assert Regex.match?(~r/日本語/, stdout)
    assert Regex.match?(~r/Español/, stdout)
  end

end
