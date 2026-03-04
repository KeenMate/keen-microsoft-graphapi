if Code.ensure_loaded?(SweetXml) do
defmodule Mix.Tasks.Graph.Gen.Schema do
  @moduledoc """
  Generates Elixir schema modules from Microsoft Graph API $metadata XML.

  ## Usage

      mix graph.gen.schema                    # fetches live metadata from Microsoft
      mix graph.gen.schema --file path        # uses local XML for all versions
      mix graph.gen.schema --version v1       # generates only v1 schemas
      mix graph.gen.schema --version beta     # generates only beta schemas

  Configuration is read from `graph_schema.exs` in the project root.
  """
  @shortdoc "Generates schema modules from Microsoft Graph $metadata"

  use Mix.Task

  alias MicrosoftGraph.Schema.Generator.{MetadataParser, TypeResolver, CodeGenerator}

  @metadata_urls %{
    v1: "https://graph.microsoft.com/v1.0/$metadata",
    beta: "https://graph.microsoft.com/beta/$metadata"
  }

  @config_file "graph_schema.exs"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [file: :string, version: :string])

    config = load_config()
    version_filter = parse_version_filter(opts)
    versions = filter_versions(config.versions, version_filter)

    if versions == [] do
      Mix.raise("No matching versions found for --version #{opts[:version]}")
    end

    all_format_paths =
      Enum.flat_map(versions, fn version_config ->
        generate_version(version_config, config.entities, opts)
      end)

    if all_format_paths != [] do
      Mix.shell().info("Running mix format...")
      Mix.Task.run("format", all_format_paths)
    end

    Mix.shell().info("Done!")
  end

  defp generate_version(version_config, entities, opts) do
    api_version = version_config.api_version
    output_dir = version_config.output_dir
    namespace = version_config.namespace

    Mix.shell().info("\n=== Generating #{api_version} schemas (#{namespace}) ===")

    xml = load_metadata(opts, api_version)

    Mix.shell().info("Parsing metadata XML...")
    metadata = MetadataParser.parse(xml)

    Mix.shell().info("Resolving types for #{length(entities)} entities...")
    resolved = TypeResolver.resolve(metadata, entities)

    enum_names = Enum.map(resolved.enum_types, & &1.name)
    context = %{enum_names: enum_names, namespace: namespace}

    File.mkdir_p!(output_dir)
    files_written = generate_and_write_files(resolved, context, output_dir)

    Mix.shell().info("Generated #{files_written} files into #{output_dir}/")

    [Path.join(output_dir, "*.ex")]
  end

  defp load_config do
    unless File.exists?(@config_file) do
      Mix.raise("Missing #{@config_file} in project root")
    end

    {config, _} = Code.eval_file(@config_file)
    config
  end

  defp parse_version_filter(opts) do
    case Keyword.get(opts, :version) do
      nil -> nil
      "v1" -> :v1
      "beta" -> :beta
      other -> Mix.raise("Unknown version: #{other}. Expected v1 or beta.")
    end
  end

  defp filter_versions(versions, nil), do: versions

  defp filter_versions(versions, version_atom) do
    Enum.filter(versions, &(&1.api_version == version_atom))
  end

  defp load_metadata(opts, api_version) do
    case Keyword.get(opts, :file) do
      nil ->
        url = Map.fetch!(@metadata_urls, api_version)
        Mix.shell().info("Fetching metadata from #{url}...")
        fetch_metadata(url)

      path ->
        Mix.shell().info("Reading metadata from #{path}...")
        File.read!(path)
    end
  end

  defp fetch_metadata(url) do
    Application.ensure_all_started(:req)

    case Req.get(url, receive_timeout: 120_000) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        body

      {:ok, %{status: status}} ->
        Mix.raise("Failed to fetch metadata: HTTP #{status}")

      {:error, reason} ->
        Mix.raise("Failed to fetch metadata: #{inspect(reason)}")
    end
  end

  defp generate_and_write_files(resolved, context, output_dir) do
    entity_files =
      Enum.map(resolved.entities, fn entity ->
        CodeGenerator.generate_entity(entity, context)
      end)

    complex_files =
      Enum.map(resolved.complex_types, fn ct ->
        CodeGenerator.generate_complex_type(ct, context)
      end)

    enum_files =
      Enum.map(resolved.enum_types, fn et ->
        CodeGenerator.generate_enum(et, context)
      end)

    all_files = entity_files ++ complex_files ++ enum_files

    Enum.each(all_files, fn {filename, code} ->
      path = Path.join(output_dir, filename)
      File.write!(path, code)
      Mix.shell().info("  #{path}")
    end)

    length(all_files)
  end
end
end
