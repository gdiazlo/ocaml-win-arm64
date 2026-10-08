external sum10 : int -> int -> int -> int -> int -> int -> int -> int -> int -> int -> int
  = "arm64_sum10_bytecode" "arm64_sum10" [@@noalloc]
external floats10 : float -> float -> float -> float -> float -> float -> float -> float -> float -> float -> float
  = "arm64_floats10_bytecode" "arm64_floats10" [@@unboxed] [@@noalloc]
external callback_gc : (int -> int) -> int -> int = "arm64_callback_gc"
external callback_raises : (unit -> unit) -> bool = "arm64_callback_raises"
external raise_from_c : unit -> unit = "arm64_raise_from_c"

let () =
  assert (sum10 1 2 3 4 5 6 7 8 9 10 = 55);
  assert (floats10 1. 2. 3. 4. 5. 6. 7. 8. 9. 10. = 55.);
  let offset = ref 2 in
  assert (callback_gc (fun i -> Gc.full_major (); i + !offset) 40 = 42);
  assert (callback_raises (fun () -> failwith "caught in C"));
  assert (try raise_from_c (); false with Failure s -> s = "raised from C");
  Printf.printf "PASS C FFI: 10 integer/float arguments, callbacks + GC, callback exception, C raise\n%!"
