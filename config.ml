(* Copyright (C) 2017, Thomas Leonard <thomas.leonard@unikernel.com>
   See the README file for details. *)

(** Configuration for the "mirage" tool. *)

open Mirage

type package_config = PackageConfigs
let package_lol = Type PackageConfigs

type fb_backend = FramebufferBackend
let fb_backend = Type FramebufferBackend

let config_framebuffer =
  impl @@ object inherit Mirage.base_configurable
    method module_name = "Framebuffer.Make"
    method name = "my framebuffer, hello!"
    method ty = fb_backend @-> package_lol
    method! packages : package list value =
    (Key.match_ Key.(value target) @@ begin function
      | `Xen -> [package ~min:"0.4" "mirage-qubes";
                     package "mirage-framebuffer-qubes"]
      | `Unix | `MacOSX ->
         [package "mirage-unix"; package "mirage-framebuffer-tsdl"]
      | `Qubes | `Ukvm | `Virtio -> []
      end)
    |> Mirage.Key.map (List.cons (package "mirage-framebuffer"))
  end

let config_framebuffer_tsdl =
  let x = impl @@ object
      inherit Mirage.base_configurable
      method module_name = "Framebuffer_tsdl"
      method name = "tSDL framebuffer backend"
      method ty = fb_backend
      method! connect keys modname _args =
         {| Lwt.return () |}
    end
  in x

let config_framebuffer_qubes =
  let x = impl @@ object
  inherit Mirage.base_configurable
  method module_name = "Framebuffer_qubes"

  method name = "qubes framebuffer backend"
  method ty = fb_backend
  method! deps = [abstract default_qubesdb]
  method! configure keys =
    match Key.(get (Info.context keys) target) with
    | `Xen -> Ok ()
    | _ -> Error (`Msg "Qubes Framebuffer is only valid for target 'xen'")
  end
  in x

let main =
  foreign
    ~deps:[abstract config_framebuffer]
    ~packages:[
      package "vchan";
      package "cstruct";
      package "mirage-logs";
      package "imagelib";
      package "mirage-qubes";
      package "mirage-framebuffer-imagelib";
    ] "Unikernel.Main" ((*package_lol @->*) time @-> job)

let () =
  register "eye-of-mirage" [
    main
    (*$ (config_framebuffer
       $ (Mirage.match_impl Key.(value target) ~default:config_framebuffer_qubes
          [`Xen, config_framebuffer_qubes; (* stay away from Qubes target *)
           `Unix, config_framebuffer_tsdl ;
           `MacOSX, config_framebuffer_tsdl ; (*TODO haven't actually checked*)
          ])) *)
    $ default_time
    ] ~argv:no_argv
