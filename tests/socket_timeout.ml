let () =
  assert Sys.win32;
  let listener = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  let client = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Unix.bind listener (Unix.ADDR_INET (Unix.inet_addr_loopback, 0));
  Unix.listen listener 1;
  Unix.connect client (Unix.getsockname listener);
  let peer, _ = Unix.accept listener in
  Fun.protect ~finally:(fun () ->
    List.iter Unix.close [peer; client; listener]) (fun () ->
      Unix.setsockopt_float peer Unix.SO_RCVTIMEO 0.2;
      Unix.setsockopt_float peer Unix.SO_SNDTIMEO 1.5;
      assert (abs_float (Unix.getsockopt_float peer Unix.SO_RCVTIMEO -. 0.2) < 0.001);
      assert (abs_float (Unix.getsockopt_float peer Unix.SO_SNDTIMEO -. 1.5) < 0.001);
      List.iter (fun invalid ->
        assert (try Unix.setsockopt_float peer Unix.SO_RCVTIMEO invalid; false
                with Unix.Unix_error (Unix.EINVAL, _, _) -> true))
        [-1.; Float.nan; Float.infinity];
      let started = Unix.gettimeofday () in
      let timed_out =
        try ignore (Unix.recv peer (Bytes.create 1) 0 1 []); false
        with Unix.Unix_error ((Unix.ETIMEDOUT | Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) -> true
      in
      let elapsed = Unix.gettimeofday () -. started in
      assert timed_out;
      assert (elapsed >= 0.1 && elapsed < 5.);
      Printf.printf "PASS Winsock timeouts: float roundtrip, invalid inputs, recv expired after %.3fs\n%!" elapsed)
