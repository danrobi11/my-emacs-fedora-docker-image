# emacs-fedora-docker

Docker image of GNU Emacs built from **master** on Fedora 45.

Matches the configuration used in [emacs-fedora-dynamic](https://github.com/danrobi11/emacs-fedora-dynamic):

- Terminal only (`--without-x` etc.)
- No modules, no native compilation

## How to:
```
podman pull ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest
```
## Distrobox create container
```
podman rm -f emacs
distrobox create --name emacs --image ghcr.io/danrobi11/my-emacs-fedora-docker-image:latest
distrobox enter emacs
emacs -nw
