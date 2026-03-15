{ config, lib, ... }:
with lib;

{
  options.services.dockerStack = {
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
            description = "Environment variables written to the stack's host-side compose env file.";
          };
        };
      }));
      default = { };
      description = "Compose stacks to configure, keyed by stack name.";
    };
  };

  config =
    let
      stacks = config.services.dockerStack.stacks;
      aliasPrefix = "dcs-";
      stackRoot = "/etc/docker-stacks";
      composeEnvFile = name: "/etc/docker-stacks/${name}.env";
      composeCommand = name:
        "docker compose --env-file ${escapeShellArg (composeEnvFile name)} --project-name ${escapeShellArg name} -f ${escapeShellArg "${stackRoot}/${name}/docker-compose.yaml"}";

      mkEnvFile = generators.toKeyValue {
        mkKeyValue = flip generators.mkKeyValueDefault "=" {
          mkValueString = value: "'${replaceStrings [ "'" ] [ "\\'" ] value}'";
        };
      };

      mkEtcEntries = name: stack: [
        (nameValuePair "docker-stacks/${name}" { source = stack.path; })
        (nameValuePair "docker-stacks/${name}.env" { text = mkEnvFile stack.env; })
      ];

      mkAliasEntries =
        name: _stack:
        let
          command = composeCommand name;
          stackAlias = "${aliasPrefix}${name}";
        in
        [
          # Keep the main stack commands as aliases so zsh can reuse docker
          # compose completion for subcommands and arguments.
          (nameValuePair stackAlias command)
          (nameValuePair "${stackAlias}-deploy" "${command} up --pull always --build --remove-orphans -d")
        ];
    in
    {
      environment.etc = listToAttrs (concatLists (mapAttrsToList mkEtcEntries stacks));
      programs.zsh.shellAliases = listToAttrs (concatLists (mapAttrsToList mkAliasEntries stacks));
    };
}
