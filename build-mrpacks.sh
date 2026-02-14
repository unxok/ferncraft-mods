#!/usr/bin/env bash
set -euo pipefail

INPUT="modrinth.index.json"

CLIENT_JSON="modrinth.index.json"
SERVER_JSON="modrinth.index.json"

CLIENT_MRPACK="client-mods.mrpack"
SERVER_MRPACK="server-mods.mrpack"

echo "Creating base JSON files..."

jq '{ dependencies: .dependencies, files: [], formatVersion: .formatVersion, game: .game, name: .name, versionId: .versionId }' "$INPUT" > "$CLIENT_JSON"
jq '{ dependencies: .dependencies, files: [] }' "$INPUT" > "$SERVER_JSON"

echo "Filtering files..."

jq -c '.files[]' "$INPUT" | while read -r file; do
  client_env=$(echo "$file" | jq -r '.env.client')
  server_env=$(echo "$file" | jq -r '.env.server')

  if [[ "$client_env" == "required" ]]; then
    jq ".files += [$file]" "$CLIENT_JSON" > tmp.json && mv tmp.json "$CLIENT_JSON"
  fi

  if [[ "$server_env" == "required" ]]; then
    jq ".files += [$file]" "$SERVER_JSON" > tmp.json && mv tmp.json "$SERVER_JSON"
  fi
done

echo "Zipping directly into .mrpack files..."

zip -j "$CLIENT_MRPACK" "$CLIENT_JSON"
zip -j "$SERVER_MRPACK" "$SERVER_JSON"

echo "Cleaning up temp files..."
rm "$CLIENT_JSON" "$SERVER_JSON"

echo "Done! Created:"
echo " - $CLIENT_MRPACK"
echo " - $SERVER_MRPACK"
