open Eio.Std

let () =
  Eio_main.run @@ fun env ->
  let clock = Eio.Stdenv.clock env in
  Eio.Time.with_timeout_exn clock 15. @@ fun () ->
  let promise, resolve = Promise.create () in
  Fiber.both
    (fun () -> Eio.Time.sleep clock 0.01; Promise.resolve resolve 42)
    (fun () -> assert (Promise.await promise = 42));
  print_endline "PASS Eio Windows: fibers, promises, timer";
  let ( / ) = Eio.Path.( / ) in
  let path = Eio.Stdenv.cwd env / "eio-arm64-test.txt" in
  let data = "Eio on native Windows ARM64: λ, café\n" in
  Eio.Path.save ~create:(`Or_truncate 0o600) path data;
  assert (Eio.Path.load path = data);
  Eio.Path.unlink path;
  print_endline "PASS Eio Windows: file write/read/remove";
  let result = Eio.Domain_manager.run (Eio.Stdenv.domain_mgr env) (fun () ->
    Gc.full_major ();
    List.fold_left (+) 0 (List.init 1_000 Fun.id)) in
  assert (result = 499_500);
  print_endline "PASS Eio Windows: domain manager";
  Switch.run @@ fun sw ->
  let net = Eio.Stdenv.net env in
  let listener = Eio.Net.listen net ~sw ~backlog:1 (`Tcp (Eio.Net.Ipaddr.V4.loopback, 0)) in
  let address = Eio.Net.listening_addr listener in
  let receive flow =
    let b = Cstruct.create 4 in
    Eio.Flow.read_exact flow b;
    Cstruct.to_string b
  in
  Fiber.both
    (fun () ->
      let flow, _ = Eio.Net.accept listener ~sw in
      assert (receive flow = "ping");
      Eio.Flow.copy_string "pong" flow)
    (fun () ->
      let flow = Eio.Net.connect net ~sw address in
      Eio.Flow.copy_string "ping" flow;
      assert (receive flow = "pong"));
  print_endline "PASS Eio Windows: asynchronous localhost TCP"
