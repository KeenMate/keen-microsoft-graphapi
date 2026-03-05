%{
  versions: [
    %{
      api_version: :v1,
      output_dir: "lib/graph_api/schema",
      namespace: "GraphApi.Schema"
    },
    %{
      api_version: :beta,
      output_dir: "lib/graph_api/schema/beta",
      namespace: "GraphApi.Schema.Beta"
    }
  ],
  entities: [
    "user",
    "group",
    "message",
    "event",
    "driveItem",
    "drive",
    "calendar",
    "mailFolder",
    "organization",
    "directoryRole",
    "application",
    "servicePrincipal"
  ]
}
