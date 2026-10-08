external callback_gc : (int -> int) -> int -> int = "arm64_callback_gc"
external raise_from_c : unit -> unit = "arm64_raise_from_c"
let plugin_root = ref (String.make 20000 'p')
let run () =
  Gc.minor ();
  assert (!Shared.root = "host root");
  assert (String.length !plugin_root = 20000);
  assert (Shared.callback ((+) 1) 41 = 42);
  assert (callback_gc (fun x -> Gc.full_major (); x + 1) 41 = 42);
  assert (try raise_from_c (); false with Failure s -> s = "raised from C");
  assert (try raise (Shared.Plugin_failure "plugin exception"); false
          with Shared.Plugin_failure s -> s = "plugin exception");
  let answer = Effect.perform Shared.Ask in
  let domain = Domain.spawn (fun () -> Gc.full_major (); answer) in
  Domain.join domain
let () = Shared.register run
