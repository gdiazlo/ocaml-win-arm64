let () =
  Dynlink.loadfile Sys.argv.(1);
  assert (!Pack_host.registered = 42);
  print_endline "PASS native Dynlink of a packed module in a .cmxs"
