let check label condition =
  if not condition then failwith label;
  Printf.printf "PASS %s\n%!" label

let test_gc () =
  for _ = 1 to 30 do
    let xs = List.init 20_000 (fun i -> string_of_int i) in
    assert (List.length xs = 20_000);
    Gc.minor ()
  done;
  Gc.full_major ();
  check "allocation and GC" true

let test_domains () =
  let counter = Atomic.make 0 in
  let worker () =
    for _ = 1 to 25_000 do Atomic.incr counter done;
    List.fold_left (+) 0 (List.init 1_000 Fun.id)
  in
  let ds = Array.init 4 (fun _ -> Domain.spawn worker) in
  Array.iter (fun d -> assert (Domain.join d = 499_500)) ds;
  check "domains and atomics" (Atomic.get counter = 100_000)

let test_effects () =
  let open Effect in
  let open Effect.Deep in
  let module E = struct type _ Effect.t += Ask : int Effect.t end in
  let answer =
    match_with (fun () -> 1 + perform E.Ask) ()
      { retc = Fun.id;
        exnc = raise;
        effc = fun (type a) (eff : a Effect.t) ->
          match eff with
          | E.Ask -> Some (fun (k : (a, _) continuation) ->
              Gc.full_major ();
              continue k 41)
          | _ -> None }
  in
  check "effects and stack switching" (answer = 42)

let test_threads () =
  let m = Mutex.create () in
  let n = ref 0 in
  let f () =
    for _ = 1 to 10_000 do
      Mutex.lock m;
      incr n;
      Mutex.unlock m
    done
  in
  let ts = Array.init 3 (fun _ -> Thread.create f ()) in
  Array.iter Thread.join ts;
  check "system threads and mutexes" (!n = 30_000)

let () =
  Printf.printf "OCaml %s; OS=%s; word size=%d\n%!"
    Sys.ocaml_version Sys.os_type Sys.word_size;
  check "version and Windows ABI"
    (Sys.ocaml_version = "5.5.1" && Sys.os_type = "Win32" && Sys.word_size = 64);
  check "arithmetic" (Int64.add 0x1_0000_0000L 42L = 0x1_0000_002aL);
  check "float C calls" (abs_float (sin 0.5 -. 0.479425538604203) < 1e-14);
  check "exceptions" (try raise Not_found with Not_found -> true);
  check "marshal" (Marshal.from_string (Marshal.to_string [1;2;3] []) 0 = [1;2;3]);
  check "Unix" (Unix.getpid () > 0 && String.length (Unix.gethostname ()) > 0);
  test_gc ();
  test_domains ();
  test_effects ();
  test_threads ();
  print_endline "ALL COMPILER SMOKE TESTS PASSED"
