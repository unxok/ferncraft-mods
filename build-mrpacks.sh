#!/usr/bin/env bash
set -euo pipefail

INPUT="modrinth.index.json"

CLIENT_JSON_TMP="client-modrinth.index.json"
SERVER_JSON_TMP="server-modrinth.index.json"

CLIENT_MRPACK="Ferncraft.mrpack"
SERVER_MRPACK="Ferncraft-SERVER.mrpack"

echo "Creating base JSON files..."

jq '{ dependencies: .dependencies, files: [], formatVersion: .formatVersion, game: .game, name: .name, versionId: .versionId }' "$INPUT" > "$CLIENT_JSON_TMP"
jq '{ dependencies: .dependencies, files: [], formatVersion: .formatVersion, game: .game, name: .name, versionId: .versionId }' "$INPUT" > "$SERVER_JSON_TMP"

echo "Filtering files..."

jq -c '.files[]' "$INPUT" | while read -r file; do
  client_env=$(echo "$file" | jq -r '.env.client')
  server_env=$(echo "$file" | jq -r '.env.server')

  if [[ "$client_env" == "required" ]]; then
    jq ".files += [$file]" "$CLIENT_JSON_TMP" > tmp.json && mv tmp.json "$CLIENT_JSON_TMP"
  fi

  if [[ "$server_env" == "required" ]]; then
    jq ".files += [$file]" "$SERVER_JSON_TMP" > tmp.json && mv tmp.json "$SERVER_JSON_TMP"
  fi
done

echo "Zipping directly into .mrpack files..."

zip -j "$CLIENT_MRPACK" "$CLIENT_JSON_TMP"
zip -j "$SERVER_MRPACK" "$SERVER_JSON_TMP"

zipnote -w "$CLIENT_MRPACK" <<EOF
@ $CLIENT_JSON_TMP
@=modrinth.index.json
EOF

zipnote -w "$SERVER_MRPACK" <<EOF
@ $SERVER_JSON_TMP
@=modrinth.index.json
EOF

echo "Cleaning up temp files..."
rm "$CLIENT_JSON_TMP" "$SERVER_JSON_TMP"

echo "Done! Created:"
echo " - $CLIENT_MRPACK"
echo " - $SERVER_MRPACK"
