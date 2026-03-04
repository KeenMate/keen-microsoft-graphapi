%{
  versions: [
    %{
      api_version: :v1,
      output_dir: "lib/microsoft_graph/schema",
      namespace: "MicrosoftGraph.Schema"
    },
    %{
      api_version: :beta,
      output_dir: "lib/microsoft_graph/schema/beta",
      namespace: "MicrosoftGraph.Schema.Beta"
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
