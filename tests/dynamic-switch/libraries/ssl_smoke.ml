let read_exact sock length =
  let b = Bytes.create length in
  let rec loop off =
    if off < length then begin
      let n = Ssl.read sock b off (length - off) in
      if n = 0 then failwith "TLS: premature EOF";
      loop (off + n)
    end
  in
  loop 0;
  Bytes.to_string b

let write_all sock s =
  let rec loop off =
    if off < String.length s then begin
      let n = Ssl.write_substring sock s off (String.length s - off) in
      if n = 0 then failwith "TLS: zero-length write";
      loop (off + n)
    end
  in
  loop 0

let timeout fd =
  Unix.setsockopt_float fd Unix.SO_RCVTIMEO 10.;
  Unix.setsockopt_float fd Unix.SO_SNDTIMEO 10.

let () =
  if Array.length Sys.argv <> 3 then failwith "usage: ssl_smoke.exe certificate.pem key.pem";
  Ssl.init ~thread_safe:true ();
  let server_ctx = Ssl.create_context Ssl.TLSv1_3 Ssl.Server_context in
  Ssl.use_certificate server_ctx Sys.argv.(1) Sys.argv.(2);
  let client_ctx = Ssl.create_context Ssl.TLSv1_3 Ssl.Client_context in
  Ssl.load_verify_locations client_ctx Sys.argv.(1) "";
  Ssl.set_verify client_ctx [Ssl.Verify_peer] None;
  let listener = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.bind listener (Unix.ADDR_INET (Unix.inet_addr_loopback, 0));
  Unix.listen listener 1;
  let address = Unix.getsockname listener in
  let error = ref None in
  let server = Thread.create (fun () ->
    try
      let fd, _ = Unix.accept listener in
      Fun.protect ~finally:(fun () -> Unix.close fd) @@ fun () ->
      timeout fd;
      let sock = Ssl.embed_socket fd server_ctx in
      Ssl.accept sock;
      assert (Ssl.version sock = Ssl.TLSv1_3);
      let request = read_exact sock 4 in
      assert (request = "ping");
      Gc.full_major ();
      write_all sock "pong";
      ignore (Ssl.close_notify sock)
    with exn -> error := Some exn
  ) () in
  let fd = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  timeout fd;
  Unix.connect fd address;
  let sock = Ssl.embed_socket fd client_ctx in
  Ssl.set_client_SNI_hostname sock "localhost";
  Ssl.set_host sock "localhost";
  Ssl.connect sock;
  Ssl.verify sock;
  assert (Ssl.get_verify_result sock = 0);
  write_all sock "ping";
  assert (read_exact sock 4 = "pong");
  let cipher = Ssl.get_cipher_name (Ssl.get_cipher sock) in
  ignore (Ssl.close_notify sock);
  Unix.close fd;
  Thread.join server;
  Unix.close listener;
  Option.iter raise !error;
  Printf.printf "PASS SSL: verified localhost TLS 1.3 handshake and bidirectional I/O (%s)\n%!" cipher
