#!/usr/bin/env bash
set -euo pipefail

MODULE="${1:-}"
if [ -z "$MODULE" ]; then
  echo "Usage: $0 <module-path-or-artifact-id>" >&2
  exit 1
fi

if [ -x "./mvnw" ]; then
  ./mvnw -pl "$MODULE" -am test -DskipITs
elif command -v mvn >/dev/null 2>&1; then
  mvn -pl "$MODULE" -am test -DskipITs
else
  echo "Error: neither ./mvnw nor mvn was found." >&2
  exit 1
fi
