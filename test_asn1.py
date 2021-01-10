#!/usr/bin/env python3

import asn1tools
import os
import sys

from asn1tools.codecs.ber import encode_object_identifier
from asn1tools.codecs.ber import encode_real
from asn1tools.codecs.ber import decode_real

# definition = asn1tools.compile_files('test.asn')
# encoded = definition.encode('Question', {'id': 1.5})

# encoded = encode_object_identifier('2.999.3')
encoded = encode_real(3.14)

decoded = decode_real(encoded)
print(decoded)

print(''.join('{:02x}'.format(x) for x in encoded))

# fp = os.fdopen(sys.stdout.fileno(), 'wb')
# fp.write(encoded)
# fp.flush()