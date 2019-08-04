# WiP - Eye of Mirage

This aims to be a portable image viewer based on MirageOS,
using [mirage-framebuffer](https://github.com/cfcs/mirage-framebuffer) solely
using pure image rendering code - (no image libraries written in C).

The goal is to be able to use the same unikernel code to
- be able to display an image, or a a directory containing images, on
  Linux/FreeBSD/MacOSX.
- implement a QRExec-based [Qubes](https://qubes-os.org) AppVM that will display
  images transferred to it from other VMs.

## Latest screenshot

PNG rendering of [rainbow.png](https://github.com/cfcs/mirage-framebuffer/blob/master/test_tsdl/rainbow.png?raw=true), with text and calibration pixel (different set of pixels) overlays on Qubes (yellow window) and SDL/Linux (blue window).

![Qubes and SDL targets](https://user-images.githubusercontent.com/9653993/32151946-0ab141c2-bd21-11e7-8b54-9905f1a22a0f.png)

## Current limitations / feature list

This is very much a work-in-progress, so there's a lot of things that do not
work. Off the top of my head:

- [x] ~~It only displays one image, and there is no way to change.~~
- [x] ~~Pixel color blending is not implemented; all you get is shades of red.~~
- [ ] Transparency is not implemented.
- [x] ~~Only PNG images are supported.~~
   - support for PNG, BMP, and GIF.
- [ ] No scaling of the image is done.
  - [ ] Configurable zoom
- [x] ~~The only target supported so far is Qubes (hardcoded).~~ **-t unix now supported**
  - [ ] On which receiving images via QRexec is not implemented.
  - [x] ~~On which images are rendered upside-down.~~
- [ ] with `-t unix` it should be able to open a file or directory passed on the command-line instead of having to compile them in
- [ ] instead of `ocaml-crunch` for compiled-in things it should probably use the ppx_literal or whatever that ppx is called.

## Dependencies

```
opam pin add -n mirage-framebuffer --dev -k git \
               'https://github.com/cfcs/mirage-framebuffer#master'

# Qubes target:
opam pin add -n mirage-qubes.0.7.0 --dev -k git \
               'https://github.com/mirage/mirage-qubes.git'
opam pin add -n mirage-framebuffer-qubes --dev -k git \
               'https://github.com/cfcs/mirage-framebuffer#master'

# Unix target:
opam pin add -n mirage-framebuffer-tsdl --dev -k git \
               'https://github.com/cfcs/mirage-framebuffer#master'

# shared dependencies:

opam pin add -n mirage-framebuffer-imagelib --dev -k git \
               'https://github.com/cfcs/mirage-framebuffer#master'


# installing dependencies:

opam install lwt crunch mirage-logs \
             mirage-runtime mirage-types-lwt ocamlbuild cstruct \
             'imagelib>=20171028' mirage


# installing for qubes:
opam install mirage-framebuffer-qubes mirage-clock-freestanding

# installing for unix:
opam install mirage-framebuffer-tsdl mirage-clock-unix

```

## Setup

1) Compile image to an OCaml module
```
mkdir images/
cp image-to-display images/image.png
ocaml-crunch -m plain -o myfiles.ml images/
```

## Setup for QubesOS

2) Follow the instructions at https://github.com/talex5/qubes-test-mirage

3) ```bash
   make clean
   mirage configure -t xen && make
   ../qubes-test-mirage/test-mirage eye_of_mirage.xen mirage-test
   ```

## Setup for Unix

2) ```bash
   make clean
   mirage configure -t unix && make && ./main.native
   ```