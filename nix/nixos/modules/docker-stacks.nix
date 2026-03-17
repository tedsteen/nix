{ config, lib, ... }:
with lib;

{
  options.services.dockerStack = {
    commands = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      description = "Generated compose commands keyed by stack name.";
    };

    stacks = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          path = mkOption {
            type = types.path;
            description = "Path to the stack directory.";
          };

          env = mkOption {
            type = types.attrsOf types.singleLineStr;
            default = { };
            description = "Environment variables written to the stack's env file.";
          };
        };
      }));
      default = { };
      description = "Compose stacks to configure, keyed by stack name.";
    };
  };

  config =
    let
      stackRoot = "/etc/docker-stacks";
      composeCommand = name:
        "docker compose --env-file ${escapeShellArg "${stackRoot}/${name}.env"} --project-name ${escapeShellArg name} -f ${escapeShellArg "${stackRoot}/${name}/docker-compose.yaml"}";
    in
    {
      services.dockerStack.commands = mapAttrs (name: _: composeCommand name) config.services.dockerStack.stacks;

      environment.etc = listToAttrs (concatLists (mapAttrsToList (name: { path, env, ... }: [
        (nameValuePair "docker-stacks/${name}" { source = path; })
        (nameValuePair "docker-stacks/${name}.env" {
          text = generators.toKeyValue {
            mkKeyValue = flip generators.mkKeyValueDefault "=" {
              mkValueString = value: "'${replaceStrings [ "'" ] [ "\\'" ] value}'";
            };
          } env;
        })
      ]) config.services.dockerStack.stacks));

      programs.zsh.shellAliases = listToAttrs (concatLists (mapAttrsToList (name: _:
        let command = composeCommand name; stackAlias = "dcs-${name}"; in
        [
          # Keep the main stack commands as aliases so zsh can reuse docker
          # compose completion for subcommands and arguments.
          (nameValuePair stackAlias command)
          (nameValuePair "${stackAlias}-deploy" "${command} up --pull always --build --remove-orphans -d")
        ]
      ) config.services.dockerStack.stacks));
    };
}
