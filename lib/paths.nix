# `repo` is the checkout path relative to home; it defaults to the machine name.
{
  home,
  name,
  repo ? name,
}:

rec {
  inherit home;

  nixrt = "${home}/${repo}";
  hm = "${nixrt}/hm";
  os = "${nixrt}/os";
  dots = "${nixrt}/dots";
  darwin = "${os}/darwin";
  scripts = "${nixrt}/scripts";
  snippets = "${hm}/snippets";
}
