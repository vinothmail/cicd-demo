#!/bin/bash
# Basic quality checks for a static HTML page
FILE="${1:-index.html}"
errors=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; errors=$((errors + 1)); }

# Count how many times a pattern appears in the file
count() { grep -oiE "$1" "$FILE" | wc -l; }

# 1. File exists and is not empty
if [ -s "$FILE" ]; then
  pass "$FILE exists and is not empty"
else
  fail "$FILE is missing or empty"
  exit 1
fi

# 2. Doctype
#if grep -qi '<!DOCTYPE html>' "$FILE"; then
 # pass "DOCTYPE present"
#else
 # fail "DOCTYPE missing"
#fi

# 3. Each key tag is opened once and closed once
for tag in html head body title; do
  open=$(count "<$tag[ >]")
  close=$(count "</$tag>")
  if [ "$open" -eq 1 ] && [ "$close" -eq 1 ]; then
    pass "<$tag> opened and closed once"
  else
    fail "<$tag> problem: opened $open time(s), closed $close time(s)"
  fi
done

# 4. At least one heading
if [ "$(count '<h1[ >]')" -ge 1 ]; then
  pass "<h1> heading present"
else
  fail "no <h1> heading found"
fi

# 5. Result
if [ "$errors" -gt 0 ]; then
  echo "$errors check(s) failed"
  exit 1
fi
echo "All checks passed"
