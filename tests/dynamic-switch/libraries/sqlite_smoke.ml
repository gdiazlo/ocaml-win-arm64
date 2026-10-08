let ok rc = Sqlite3.Rc.check rc

let () =
  let db = Sqlite3.db_open ":memory:" in
  ok (Sqlite3.exec db "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT, n INTEGER, data BLOB)");
  let ins = Sqlite3.prepare db "INSERT INTO test(name,n,data) VALUES(?,?,?)" in
  let label = "Windows ARM64: λ, café" in
  ok (Sqlite3.bind_text ins 1 label);
  ok (Sqlite3.bind_int64 ins 2 0x1234_5678_9abcL);
  ok (Sqlite3.bind_blob ins 3 "\000\001\255blob");
  assert (Sqlite3.step ins = Sqlite3.Rc.DONE);
  ok (Sqlite3.finalize ins);
  let sel = Sqlite3.prepare db "SELECT name,n,data FROM test WHERE id=1" in
  assert (Sqlite3.step sel = Sqlite3.Rc.ROW);
  assert (Sqlite3.column_text sel 0 = label);
  assert (Sqlite3.column_int64 sel 1 = 0x1234_5678_9abcL);
  assert (Sqlite3.column_blob sel 2 = "\000\001\255blob");
  assert (Sqlite3.step sel = Sqlite3.Rc.DONE);
  ok (Sqlite3.finalize sel);
  ok (Sqlite3.exec db "BEGIN; INSERT INTO test(name) VALUES('rollback'); ROLLBACK;");
  let count = Sqlite3.prepare db "SELECT COUNT(*) FROM test" in
  assert (Sqlite3.step count = Sqlite3.Rc.ROW);
  assert (Sqlite3.column_int count 0 = 1);
  ok (Sqlite3.finalize count);
  Gc.full_major ();
  assert (Sqlite3.db_close db);
  Printf.printf "PASS SQLite %s: SQL, prepared statements, UTF-8, int64, blobs, transaction\n%!"
    (Sqlite3.sqlite_version_info ())
