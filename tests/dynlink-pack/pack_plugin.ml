let () =
  assert (P.B.answer = 42);
  Gc.full_major ();
  Pack_host.registered := P.B.answer
