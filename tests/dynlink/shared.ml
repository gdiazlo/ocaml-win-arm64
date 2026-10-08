type _ Effect.t += Ask : int Effect.t
exception Plugin_failure of string
let root = ref "host root"
let run : (unit -> int) ref = ref (fun () -> failwith "plugin not registered")
let callback f x = Gc.full_major (); f x
let register f = run := f
