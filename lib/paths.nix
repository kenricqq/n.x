{ home, name }:

rec {
  inherit home;

  nixrt = "${home}/${name}";
  hm = "${nixrt}/hm";
  os = "${nixrt}/os";
  dots = "${nixrt}/dots";
  darwin = "${os}/darwin";
  scripts = "${nixrt}/scripts";
  snippets = "${hm}/snippets";
}
