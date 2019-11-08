/// A multi-platform Hello World library.
library hw_mp;

export 'src/hw.dart' // Stub implementation
    if (dart.library.io) 'src/hw_io.dart' // Native|dart:io implementation
    if (dart.library.html) 'src/hw_html.dart'; // JS|dart:html implementation
