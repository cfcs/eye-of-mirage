(* Copyright (C) 2016, Thomas Leonard
   See the README file for details. *)

open Rresult
open Lwt.Infix

let src = Logs.Src.create "eye-of-mirage" ~doc:"Eye of Mirage main module"
module Log = (val Logs.src_log src : Logs.LOG)

module FB : Framebuffer__S.Framebuffer_S with
    type init_handle = Qubes.GUI.t = Framebuffer.Make(Framebuffer_qubes)

module Main
    (*(FB: Framebuffer__S.Framebuffer_S)*)
    (Time: Mirage_time_lwt.S)
=
struct

  let rec loop () =
    Time.sleep_ns 1000_000_000_L >>= fun () ->
    Log.info (fun m -> m "Iterated loop");
    loop ()

  let paint_image (fb:FB.t) ({width;height;max_val;pixels}:Image.image) gui : unit Lwt.t =
    let red r   = FB.compile_rgb ~r:(Char.chr r) fb
    and green g = FB.compile_rgb ~g:(Char.chr g) fb
    and blue b  = FB.compile_rgb ~b:(Char.chr b) fb in
    let open Framebuffer.Utils in
    begin match pixels with
    | RGB  (r,g,b)
    | RGBA (r,g,b,_) -> (* TODO alpha not handled *)
      let colors = List.combine [r;g;b] [red;green;blue] |> Array.of_list in
      lwt_for (Array.length colors)
        (fun c ->
           let pixmap, color =
             let _pixmap, _color = colors.(c) in
             match _pixmap with
             | Image.Pixmap.Pix8 pixmap -> Bigarray.Array2.get pixmap, _color
             | Image.Pixmap.Pix16 pixmap -> Bigarray.Array2.get pixmap,
                                            (fun p -> _color (p/256))
           in
           lwt_for height
             (fun (y:int) ->
                let multiplier = y * width in
                (lwt_for width
                 ((fun (x:int) ->
                    FB.pixel fb ~x ~y (color (pixmap x y) : FB.color)
                 ) : 'a -> unit Lwt.t) : unit Lwt.t)
             )
        )
    end

  let paint_embedded name gui =
    let Some raw = Myfiles.read name in
    let x : ImageUtil.chunk_reader =
      let pos = ref (0) in
      function
      | `Close -> Ok ""
      | `Bytes b ->
        let end_pos = !pos + b in
        if end_pos > String.length raw then raise End_of_file
        else begin
          let ret = String.sub raw !pos b in pos := end_pos ;
          Ok ret
        end in
    let image = ImageLib.PNG.ReadPNG.parsefile x |> R.get_ok in
    FB.init ~width:image.width ~height:image.height gui >>= fun fb ->
    paint_image fb image gui >>= fun () ->
    FB.redraw fb

  let start_qubes () =
    Qubes.RExec.connect ~domid:0 () >>= fun qrexec ->
    Qubes.GUI.connect ~domid:0 () >>= fun gui ->

    let agent_listener = Qubes.RExec.listen qrexec Command.handler in
    Lwt.async (Qubes.GUI.listen gui) ;
    Lwt.async (fun () ->
        OS.Lifecycle.await_shutdown_request () >>= fun (`Poweroff | `Reboot) ->
        Qubes.RExec.disconnect qrexec
      );

    Lwt.return (agent_listener,
                (*(module FB : Framebuffer__S.Framebuffer_S
                  with type init_handle = Qubes.GUI.t),*)
                gui)

  let start _time x =
    Log.info (fun f -> f "Starting");
    start_qubes () >>= fun (main_loop,
                            (*(module FB : Framebuffer__S.Framebuffer_S with type init_handle = Qubes.GUI.t),*)
                            fb_init) ->

    paint_embedded "image.png" fb_init >>= fun () ->
    main_loop
end
