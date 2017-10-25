# WiP - Eye of Mirage

This aims to be a portable image viewer based on MirageOS,
using [mirage-framebuffer](https://github.com/cfcs/mirage-framebuffer) solely
using pure image rendering code - (no image libraries written in C).

The goal is to be able to use the same unikernel code to
- be able to display an image, or a a directory containing images, on
  Linux/FreeBSD/MacOSX.
- implement a QRExec-based [Qubes](https://qubes-os.org) AppVM that will display
  images transferred to it from other VMs.

## Current limitations / feature list

This is very much a work-in-progress, so there's a lot of things that do not
work. Off the top of my head:

- [ ] It only displays one image, and there is no way to change.
- [ ] Pixel color blending is not implemented; all you get is shades of red.
- [ ] Transparency is not implemented.
- [ ] Only PNG images are supported.
- [ ] The only target supported so far is Qubes (hardcoded).
  - [ ] On which receiving images via QRexec is not implemented.
  - [ ] On which images are rendered upside-down.

## Dependencies

This is a bit of a mess since it relies on a bunch of patches that have not been upstreamed yet, working on that.

```
opam pin add imagelib --dev -k git \
               'https://github.com/cfcs/imagelib#mirage_friendly'

opam pin add mirage --dev -k git 'https://github.com/cfcs/mirage#fix_qubes'

opam pin add mirage-xen --dev -k git \
               'https://github.com/cfcs/mirage-platform#virt_to_mfn'
opam pin add mirage-qubes --dev -k git \
               'https://github.com/cfcs/mirage-qubes#guid_mvar'

opam pin add mirage-framebuffer --dev -k git \
               'https://github.com/cfcs/mirage-framebuffer#master'
opam pin add mirage-framebuffer-qubes --dev -k git \
               'https://github.com/cfcs/mirage-framebuffer#master'

opam install lwt ocaml-crunch mirage-clock-freestanding mirage-logs \
             mirage-runtime mirage-types-lwt ocamlbuild vchan cstruct
```

## Setup for Qubes

1) Compile image to an OCaml module
```
mkdir images/
cp image-to-display images/image.png
ocaml-crunch -m plain -o myfiles.ml images/
```

2) Follow the instructions at https://github.com/talex5/qubes-test-mirage

## Building and running

```bash
make clean
mirage configure -t xen && make
../qubes-test-mirage/test-mirage eye_of_mirage.xen mirage-test
```
