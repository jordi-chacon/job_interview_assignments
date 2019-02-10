~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
  default_release: :default,
  default_environment: Mix.env()

environment :prod do
  set(include_erts: true)
  set(include_src: false)

  set(
    cookie: :"23J3>Y:uOGyX4GBV9L}Mfo>3=imf&7,PK!h6L=b[?4ZBtZd=Wry<5yP(14T&&`p!"
  )

  set(vm_args: "rel/vm.args")
end

release :cool_node do
  set(version: current_version(:cool_node))

  set(
    applications: [
      :runtime_tools
    ]
  )
end
