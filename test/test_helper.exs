config = ExUnit.configuration()

skip_setup = :setup in config[:exclude]

if not skip_setup do
  {_, 0} = System.shell("bash ./test_setup.sh", into: IO.stream())
end

ExUnit.after_suite(fn _ ->
  if not skip_setup do
    {_, 0} = System.shell("bash ./test_teardown.sh", into: IO.stream())
  end
end)

ExUnit.start()
