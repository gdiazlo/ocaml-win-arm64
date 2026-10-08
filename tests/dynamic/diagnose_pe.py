# Loader diagnostic only: never distribute these intentionally altered images.
import struct
from pathlib import Path
source = Path('hello-unix.exe').read_bytes()
pe = struct.unpack_from('<I', source, 0x3c)[0]
opt = pe + 24
for name, index in [('imports',1), ('exception',3), ('relocs',5), ('debug',6), ('tls',9), ('loadconfig',10)]:
    data = bytearray(source)
    struct.pack_into('<II', data, opt + 112 + index*8, 0, 0)
    Path('diag-'+name+'.exe').write_bytes(data)
