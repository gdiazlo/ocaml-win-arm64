#directory "+unix";;
#load "unix.cma";;
let () =
  let path = "tests/arm64-λ-東京.txt" in
  let renamed = "tests/arm64-λ-東京-renamed.txt" in
  Fun.protect ~finally:(fun () ->
    List.iter (fun p -> try Sys.remove p with Sys_error _ -> ()) [path; renamed])
    (fun () ->
      let out = open_out_bin path in
      output_string out "Windows ARM64 Unicode\n";
      close_out out;
      assert ((Unix.stat path).Unix.st_size = 22);
      Unix.rename path renamed;
      assert (not (Sys.file_exists path));
      assert (Array.mem "arm64-λ-東京-renamed.txt" (Sys.readdir "tests"));
      let input = open_in_bin renamed in
      assert (input_line input = "Windows ARM64 Unicode");
      close_in input;
      print_endline "PASS Windows UTF-8 filenames and the static Unix toplevel")
;;
