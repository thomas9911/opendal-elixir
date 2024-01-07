defmodule OpenDAL.Native do
  use Rustler, otp_app: :opendal, crate: "opendal_native"

  def init(_config), do: nif_error()

  # When your NIF is loaded, it will override this function.
  def read(_config, _path), do: nif_error()
  def read_into(_config, _path, _tmp_file_path, _send_to), do: nif_error()
  def write_from(_config, _path, _tmp_file_path, _send_to), do: nif_error()

  defp nif_error, do: :erlang.nif_error(:nif_not_loaded)
end
