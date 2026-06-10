"""Application entrypoint.

Run directly (``python app/main.py``) or via the Docker image, which calls the
same module. Production deployments should front this with a WSGI server.
"""

from __future__ import annotations

import os
import sys

# Allow ``python app/main.py`` (script dir is app/) to import the ``app`` package
# by ensuring the repository root is on sys.path.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import app  # noqa: E402

if __name__ == "__main__":
    port = int(os.getenv("FLASK_PORT", "5000"))
    debug = os.getenv("FLASK_ENV", "production").lower() == "development"
    app.run(host="0.0.0.0", port=port, debug=debug)
