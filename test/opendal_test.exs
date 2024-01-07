defmodule OpenDALTest do
  use ExUnit.Case

  @moduletag :tmp_dir

  [
    %OpenDAL.Config{
      service: :dashmap,
      options: %{"root" => "/"}
    },
    %OpenDAL.Config{
      service: :memory,
      options: %{"root" => "/"}
    },
    %OpenDAL.Config{
      service: :fs,
      options: %{"root" => "{{tmp_dir}}/"}
    },
    %OpenDAL.Config{
      service: :redis,
      options: %{}
    },
    %OpenDAL.Config{
      service: :azblob,
      options: %{
        "root" => "/",
        "container" => "test",
        "endpoint" => "http://127.0.0.1:10000/devstoreaccount1",
        "account_name" => "devstoreaccount1",
        "account_key" =>
          "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
      }
    },
    %OpenDAL.Config{
      service: :s3,
      options: %{
        "root" => "/",
        "bucket" => "test",
        "endpoint" => "http://127.0.0.1:9000",
        "region" => "eu-west1",
        "access_key_id" => "minio-root-user",
        "secret_access_key" => "minio-root-password"
      }
    },
    %OpenDAL.Config{
      service: :postgresql,
      options: %{
        "root" => "/",
        "connection_string" => "postgresql://my_user:password123@127.0.0.1:5432/my_database",
        "table" => "my_table",
        "key_field" => "key",
        "value_field" => "value"
      }
    }
  ]
  |> Enum.map(fn config ->
    test "#{config.service}", %{tmp_dir: tmp_dir} do
      config = unquote(Macro.escape(config))

      options =
        config.options
        |> Map.new(fn {key, value} -> {key, String.replace(value, "{{tmp_dir}}", tmp_dir)} end)

      config = %{config | options: options}

      into_file_path = "#{tmp_dir}/tmp_out.txt"
      from_file_path = "mix.exs"

      {:ok, conn} = OpenDAL.init(config)

      assert :ok = OpenDAL.write_from(conn, "testing.txt", from_file_path)
      assert :ok = OpenDAL.read_into(conn, "testing.txt", into_file_path)

      assert File.read!(into_file_path) =~ "app: :opendal"
    end
  end)
end
