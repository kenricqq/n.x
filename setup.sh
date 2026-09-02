curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
nix shell nixpkgs#{helix,yazi} --extra-experimental-features 'nix-command flakes' && echo EDITOR=hx

nix --extra-experimental-features 'nix-command flakes' build .#homeConfigurations.meridian.activationPackage
./result/activate

home-manager switch --flake .#meridian

# install tailscale
sudo pacman -S sunshine tailscale

sudo systemctl enable --now tailscaled
sudo tailscale up

systemctl --user --now enable sunshine

tailscale ip -4
