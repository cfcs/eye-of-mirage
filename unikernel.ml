(* Copyright (C) 2016, Thomas Leonard
   See the README file for details. *)

open Rresult
open Lwt.Infix

let src = Logs.Src.create "eye-of-mirage" ~doc:"Eye of Mirage main module"
module Log = (val Logs.src_log src : Logs.LOG)

module FB : module type of Framebuffer.Make(Framebuffer_qubes)
(*Framebuffer__S.Framebuffer_S with
    type init_handle = Qubes.GUI.t *) = Framebuffer.Make(Framebuffer_qubes)
module Img = Framebuffer_image.Make(FB)

module Main
    (*(FB: Framebuffer__S.Framebuffer_S)*)
    (Time: Mirage_time_lwt.S)
=
struct

  let rec loop () =
    Time.sleep_ns 1000_000_000_L >>= fun () ->
    Log.info (fun m -> m "Iterated loop");
    loop ()

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
    let image= ImageLib.PNG.ReadPNG.parsefile x in
    Lwt.try_bind
      (fun () -> FB.init ~width:image.Image.width ~height:image.Image.height
                 gui)
      (fun fb -> Lwt.return fb)
      (fun _ -> failwith "FB init failed")  >>= fun fb ->
    Lwt.try_bind (fun () -> Img.draw_image fb image)
      (fun () -> FB.redraw fb >>= fun () -> Lwt.return fb)
      (fun _ -> failwith "paint image fail")

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
    start_qubes ()


    >>= fun (main_loop,
             (*(module FB : Framebuffer__S.Framebuffer_S with
               type init_handle = Qubes.GUI.t),*)
             fb_init) ->

(*    Lwt.try_bind (fun () -> paint_embedded "image.png" fb_init)
        (fun () -> main_loop) (fun _ -> failwith "fuck painting")*)
    paint_embedded "image.png" fb_init >>= fun fb ->
    FB.letters fb ~x:30 ~y:30 "a" >>= fun () ->
    let red = FB.compile_rgb ~r:'\xff' fb in
    let green = FB.compile_rgb ~g:'\xff' fb in
    let cyan = FB.compile_rgb ~g:'\xff' ~b:'\xff' fb in
    let blue = FB.compile_rgb ~b:'\xff' fb in
    let line = FB.compile_line [cyan;red;red;red;green;green;green;blue] fb in
    FB.pixel fb ~x:10 ~y:10 red >>= fun()->
    FB.rect_lineiter fb ~x:15 ~y:10 ~y_end:11 (fun _ -> line) >>= fun () ->
    FB.letters fb ~x:50 ~y: 50 "hello" >>= fun () ->
    main_loop
end
