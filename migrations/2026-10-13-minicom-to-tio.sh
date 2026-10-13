#!/usr/bin/env bash
# minicom profiles were replaced by tio/config; drop the links to deleted files
for f in ~/.minirc.dfl ~/.minirc.pico ~/.minirc.modem; do
  [[ -L $f && ! -e $f ]] && rm -f "$f" && echo "  removed: $f"
done
true
