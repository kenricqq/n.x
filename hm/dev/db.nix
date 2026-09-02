{ pkgs, ... }:

{
  programs = {
    lazysql = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    atlas # manage db schema as code

    pgcli

    # ladybugdb
    duckdb # embeddable analytics db
    tigerbeetle # high performance transactional db
    # sqlfluff
    sqlite
    # postgresql_18
    # pgcli # for postgres
    sqlc
    litecli # for sqlite
    # turso-cli
  ];
}
