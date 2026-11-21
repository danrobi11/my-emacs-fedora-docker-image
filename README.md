# emacs-fedora-docker

Docker image of GNU Emacs built from **master** on Fedora Rawhide.

Matches the configuration used in [emacs-fedora-dynamic](https://github.com/danrobi11/emacs-fedora-dynamic):

- Terminal only (`--without-x` etc.)
- No modules, no native compilation

## How to

```bash
podman pull ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest

podman run -it --rm --name emacs \
  --security-opt label=disable \
  --userns=keep-id \
  -e HOME=/var/home/danrobi \
  -v /var/home/danrobi:/var/home/danrobi \
  -v /var/home/danrobi:/home/danrobi \
  -v /:/run/host:rslave \
  -w /var/home/danrobi \
  ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest emacs -nw
```
