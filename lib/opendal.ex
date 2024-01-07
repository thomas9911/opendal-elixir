defmodule OpenDAL do
  @moduledoc """
  Documentation for `OpenDAL`.
  """

  @default_timeout 5000

  defdelegate init(config), to: OpenDAL.Native

  def read_into(config, path, tmp_file_path, timeout \\ @default_timeout) do
    wait_helper(fn -> OpenDAL.Native.read_into(config, path, tmp_file_path, self()) end, timeout)
  end

  def write_from(config, path, tmp_file_path, timeout \\ @default_timeout) do
    wait_helper(fn -> OpenDAL.Native.write_from(config, path, tmp_file_path, self()) end, timeout)
  end

  defp wait_helper(function, timeout) do
    case function.() do
      {:ok, _} ->
        receive do
          {:ok, {}} ->
            :ok

          x ->
            x
        after
          timeout -> {:error, :timeout}
        end

      other ->
        other
    end
  end
end
