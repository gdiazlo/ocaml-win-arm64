let () =
  Dynlink.loadfile Sys.argv.(1);
  Gc.full_major ();
  for _ = 1 to 20 do
    let result = Effect.Deep.match_with (fun () -> !Shared.run ()) ()
      { retc = Fun.id; exnc = raise;
        effc = fun (type a) (eff : a Effect.t) -> match eff with
          | Shared.Ask -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
              Gc.full_major (); Effect.Deep.continue k 42)
          | _ -> None }
    in
    assert (result = 42)
  done;
  print_endline "PASS native Dynlink: host globals, plugin roots + moving GC, callbacks across C/DLL boundary, exceptions, domains, effects"
