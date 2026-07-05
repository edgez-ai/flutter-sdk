#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO_DIR="$ROOT_DIR/protos"
OUT_DIR="$ROOT_DIR/lib/src/proto"

mkdir -p "$OUT_DIR"

if ! command -v protoc >/dev/null 2>&1; then
  echo "protoc is required to generate Dart protobuf stubs." >&2
  exit 1
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "dart is required to run the Dart protobuf generator." >&2
  exit 1
fi

DART_PLUGIN="$ROOT_DIR/.dart_tool/protoc-gen-dart"
mkdir -p "$(dirname "$DART_PLUGIN")"
cat > "$DART_PLUGIN" <<EOF
#!/usr/bin/env bash
cd "$ROOT_DIR"
exec dart run protoc_plugin "\$@"
EOF
chmod +x "$DART_PLUGIN"

protoc \
  --plugin="protoc-gen-dart=$DART_PLUGIN" \
  --dart_out="$OUT_DIR" \
  -I"$PROTO_DIR" \
  "$PROTO_DIR/edgez_mesh.proto"
