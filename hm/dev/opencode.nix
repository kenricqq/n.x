{ ... }:

{
  programs = {
    opencode = {
      enable = true;
      enableMcpIntegration = true;
      # think of this as global AGENTS.md
      # rules = ./ai/AGENTS.md;
      # rules = symlinked...
      settings = {
        autoshare = false;
        autoupdate = true;
        permission = {
          "edit" = {
            # "*" = "deny";
            "packages/web/src/content/docs/*.mdx" = "allow";
          };
          "bash" = {
            "*" = "ask";
            "git *" = "allow";
            "jj *" = "allow";
            "bun *" = "allow";
            "rm *" = "deny";
            "npm *" = "deny";
          };
          # "skill" = {
          #   "*" = "allow";
          #   "pr-review" = "allow";
          #   "internal-*" = "deny";
          #   "experimental-*" = "ask";
          # };
          "webfetch" = "allow";
        };
        # built-in agents
        agent = {
          plan = {
            permission = {
              skill = {
                "internal-*" = "allow";
              };
            };
            tools = {
              skill = false;
            };
          };
        };
      };
      tools = {
        # database-query = ''
        #   import { tool } from "@opencode-ai/plugin"

        #   export default tool({
        #     description: "Query the project database",
        #     args: {
        #       query: tool.schema.string().describe("SQL query to execute"),
        #     },
        #     async execute(args) {
        #       // Your database logic here
        #       return "Executed query: " + args.query
        #     },
        #   })
        # '';

        # Or reference an existing file
        # api-client = ./tools/api-client.ts;
      };
    };
  };
}
