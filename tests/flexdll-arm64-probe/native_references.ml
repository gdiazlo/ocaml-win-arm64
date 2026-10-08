external host_function : int -> int = "host_function"
let host_reference = ref 42
let run x = host_function x + !host_reference
