#!/usr/bin/env bash
# code-migrate.sh audit|pack|restore - move ~/Code to another machine without
# carrying the build output.
#
#   code-migrate.sh audit                 what is at risk of being lost
#   code-migrate.sh pack <dest>           write the payload to <dest>
#   code-migrate.sh restore <src> [dest]  rebuild ~/Code from a payload
#
# The payload is git bundles plus loose files, not a copy of the tree: a repo
# that is fully pushed is re-cloned on the far side instead of being carried.
#
# What decides that a file is disposable is git, never the directory name.
# Yocto and kernel trees track real sources under paths called build/, target/
# and output/, so a name-based exclude silently drops committed code.
set -euo pipefail

CODE="${CODE_DIR:-$HOME/Code}"

# Files git ignores that still have to travel. Per-project Claude instructions
# and settings live in the tree but are excluded (often by a global ignore), so
# nothing else would carry them. Matched by name with find rather than by git
# pathspec: in a pathspec "*" also matches "/", so ".claude/**" happily swept in
# a buildroot dl/ cache and turned a 34M payload into 7.1G.

# Repo state, computed once per repo and shared by every subcommand.
# Sets: r_remote r_local r_stash r_untracked r_branch
scan_repo() {
  local d="$1"
  r_remote="$(git -C "$d" remote get-url origin 2> /dev/null || true)"
  # Only branches: local tags never appear under refs/remotes, so counting
  # them here would mark every repo with an upstream tag as at risk.
  r_local="$(git -C "$d" log --branches --not --remotes --oneline 2> /dev/null | wc -l)"
  r_stash="$(git -C "$d" stash list 2> /dev/null | wc -l)"
  r_untracked="$(git -C "$d" ls-files --others --exclude-standard 2> /dev/null | wc -l)"
  r_branch="$(git -C "$d" symbolic-ref --short HEAD 2> /dev/null || echo HEAD)"
}

# "Has a remote" is not the same as "can be cloned again": a remote can be
# deleted, behind a VPN, or need credentials this machine no longer has. Only
# an actual ls-remote settles it, so the answer is cached per URL.
REACH_CACHE="${TMPDIR:-/tmp}/code-migrate-reach.$$"
remote_reachable() {
  local url="$1" hit
  hit="$(grep -Fx -m1 "ok $url" "$REACH_CACHE" 2> /dev/null || true)"
  [[ -n $hit ]] && return 0
  hit="$(grep -Fx -m1 "no $url" "$REACH_CACHE" 2> /dev/null || true)"
  [[ -n $hit ]] && return 1
  if GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -oBatchMode=yes -oConnectTimeout=10' \
    timeout "${REACH_TIMEOUT:-45}" git ls-remote --heads "$url" > /dev/null 2>&1; then
    echo "ok $url" >> "$REACH_CACHE"
    return 0
  fi
  echo "no $url" >> "$REACH_CACHE"
  return 1
}

# A repo needs carrying only when git cannot get the work back from a remote.
needs_bundle() {
  [[ -z $r_remote || $r_local -gt 0 || $r_stash -gt 0 ]]
}

slug() { echo "${1#"$CODE"/}" | tr '/' '_'; }

each_repo() {
  find "$CODE" -maxdepth 3 -name .git -prune -printf '%h\n' 2> /dev/null | sort
}

cmd_audit() {
  local risk=0
  printf '%-34s %-8s %6s %6s %6s\n' REPO REMOTE LOCAL STASH UNTRACKED
  while read -r d; do
    scan_repo "$d"
    if needs_bundle || [[ $r_untracked -gt 0 ]]; then
      printf '%-34s %-8s %6s %6s %6s\n' "$(slug "$d")" \
        "$([[ -n $r_remote ]] && echo yes || echo NONE)" \
        "$r_local" "$r_stash" "$r_untracked"
      risk=$((risk + 1))
    fi
  done < <(each_repo)

  echo
  echo "Directories that are not git repos at all:"
  find "$CODE" -mindepth 1 -maxdepth 1 -type d \
    -not -exec test -e '{}/.git' \; -print 2> /dev/null |
    while read -r d; do echo "  $(basename "$d")  $(du -sh "$d" 2> /dev/null | cut -f1)"; done

  echo
  echo "$risk repos hold work that exists nowhere else."
}

cmd_pack() {
  local dest="${1:?usage: code-migrate.sh pack <dest>}"
  mkdir -p "$dest/bundles" "$dest/loose"
  : > "$dest/manifest.tsv"

  while read -r d; do
    scan_repo "$d"
    local s
    s="$(slug "$d")"
    # The slug flattens "/" to "_", which cannot be reversed: a repo named
    # drone_sleeve would come back as drone/sleeve. Carry the path verbatim.
    printf '%s\t%s\t%s\t%s\n' "$s" "${d#"$CODE"/}" "${r_remote:-NONE}" "$r_branch" \
      >> "$dest/manifest.tsv"

    # A remote that cannot be reached cannot be cloned on the far side, so the
    # repo has to travel whole even though its work is nominally pushed.
    local unreachable=no
    if [[ -n $r_remote ]] && ! remote_reachable "$r_remote"; then
      unreachable=yes
      local gitmb
      gitmb="$(du -sm "$d/.git" 2> /dev/null | cut -f1)"
      if [[ ${gitmb:-0} -gt ${MAX_BUNDLE_MB:-2048} ]]; then
        [[ -f "$dest/NEEDS-MANUAL.tsv" ]] ||
          echo "# too big to carry; clone these by hand once the remote is reachable" \
            > "$dest/NEEDS-MANUAL.tsv"
        printf '%s\t%s\t%s MB\n' "$s" "$r_remote" "$gitmb" >> "$dest/NEEDS-MANUAL.tsv"
        echo "  SKIP $s: remote unreachable and .git is ${gitmb} MB (over MAX_BUNDLE_MB)"
        continue
      fi
      echo "  $s: remote unreachable, carrying full history (${gitmb} MB)"
    fi

    if needs_bundle || [[ $unreachable == yes ]]; then
      # With a remote, carry only the commits the remote does not already have;
      # the missing bases are prerequisites a fresh clone supplies. Without one,
      # the bundle has to stand alone.
      # Exclude only what origin already has. "--not --remotes" would also
      # exclude objects that live on a second remote (uboot-imx-comms tracks
      # nxp as well), and restore clones origin alone, so those prerequisites
      # would be missing and the bundle would refuse to apply.
      local refs=(--branches --tags)
      [[ -n $r_remote && $unreachable == no ]] && refs+=(--not --remotes=origin)
      git -C "$d" bundle create "$dest/bundles/$s.bundle" "${refs[@]}" 2> /dev/null ||
        echo "  no bundle for $s (nothing to carry)"
      # Stashes live outside --branches and a bundle drops them. Only the top
      # stash is a real ref (refs/stash); the rest exist solely in its reflog,
      # so every stash is written as a patch against the commit it was cut from.
      local i=0
      while [[ $i -lt $r_stash ]]; do
        {
          echo "# stash@{$i}: $(git -C "$d" log -1 --format=%s "stash@{$i}" 2> /dev/null)"
          echo "# base: $(git -C "$d" rev-parse "stash@{$i}^" 2> /dev/null)"
          git -C "$d" stash show -p "stash@{$i}" 2> /dev/null
        } > "$dest/loose/$s.stash$i.patch"
        i=$((i + 1))
      done
    fi

    # Extra remotes are part of how the repo works; restore re-adds them.
    git -C "$d" remote 2> /dev/null | grep -qv '^origin$' && {
      git -C "$d" remote -v 2> /dev/null | awk '$3 == "(fetch)" && $1 != "origin" {print $1 "\t" $2}' \
        > "$dest/loose/$s.remotes.tsv"
    }

    # Ignored-but-wanted files: git will not report these as untracked, so they
    # need asking for by name.
    # The list goes through a file, not a variable: it is NUL-separated to
    # survive odd filenames, and command substitution silently drops NUL bytes,
    # which would collapse every multi-file repo into one bad entry.
    local ignlist="$dest/.ignored.$$"
    (cd "$d" && find . \( -name .git -o -name node_modules \) -prune -o \
      -type f \( -name CLAUDE.md -o -path '*/.claude/*' \) -print0) \
      > "$ignlist" 2> /dev/null || true
    if [[ -s $ignlist ]]; then
      tar -C "$d" --null -T "$ignlist" -cf "$dest/loose/$s.ignored.tar" 2> /dev/null || true
    fi
    rm -f "$ignlist"

    # Files git is not tracking and not ignoring exist only on this disk.
    if [[ $r_untracked -gt 0 ]]; then
      git -C "$d" ls-files --others --exclude-standard -z 2> /dev/null |
        tar -C "$d" --null -T - -cf "$dest/loose/$s.tar" 2> /dev/null || true
    fi
  done < <(each_repo)

  # Whole directories with no git at all, minus anything a build produced.
  # A directory can still hold nested repos (private/ does); those are already
  # bundled above, so tarring them here would duplicate gigabytes.
  find "$CODE" -mindepth 1 -maxdepth 1 -type d \
    -not -exec test -e '{}/.git' \; -print 2> /dev/null |
    while read -r d; do
      local base
      base="$(basename "$d")"
      local skip=()
      while read -r nested; do
        skip+=(--exclude="${nested#"$CODE"/}")
      done < <(find "$d" -maxdepth 3 -name .git -prune -printf '%h\n' 2> /dev/null)
      tar -C "$CODE" --exclude-caches "${skip[@]}" \
        --exclude='node_modules' --exclude='.venv' --exclude='__pycache__' \
        -cf "$dest/loose/nogit_$base.tar" "$base" 2> /dev/null || true
    done

  echo
  echo "Payload: $(du -sh "$dest" | cut -f1) in $dest"
  echo "Copy that directory to the other machine, then: code-migrate.sh restore <it>"
}

cmd_restore() {
  local src="${1:?usage: code-migrate.sh restore <src> [dest]}"
  local dest="${2:-$CODE}"
  mkdir -p "$dest"

  while IFS=$'\t' read -r s relpath remote branch; do
    local out="$dest/$relpath"
    if [[ -e $out ]]; then
      echo "skip $s (exists)"
      continue
    fi
    if [[ $remote != NONE ]] && git clone --no-checkout "$remote" "$out" 2> /dev/null; then
      echo "clone $s"
    else
      # No remote, or it did not answer. A standalone bundle still restores the
      # repo in full, so init and let the fetch below supply the history.
      [[ $remote != NONE ]] && echo "clone failed for $s, restoring from bundle"
      git init -q "$out"
      [[ $remote != NONE ]] && git -C "$out" remote add origin "$remote"
    fi
    if [[ -f "$src/loose/$s.remotes.tsv" ]]; then
      while IFS=$'\t' read -r rname rurl; do
        [[ -n $rname ]] || continue
        git -C "$out" remote add "$rname" "$rurl" 2> /dev/null &&
          echo "  added remote $rname"
      done < "$src/loose/$s.remotes.tsv"
    fi
    if [[ -f "$src/bundles/$s.bundle" ]]; then
      # git refuses to fetch into whichever branch HEAD names, so park HEAD on a
      # ref no bundle will carry. Nothing creates it, so there is nothing to
      # clean up once a real branch is checked out below.
      git -C "$out" symbolic-ref HEAD refs/heads/__migrate_parking
      git -C "$out" fetch -q "$src/bundles/$s.bundle" \
        '+refs/heads/*:refs/heads/*' '+refs/tags/*:refs/tags/*' 2>&1 ||
        echo "  bundle did not apply for $s"
    fi
    # Leaving HEAD parked would hand back a repo on a branch that does not
    # exist, so fall back through the remote default to any branch at all.
    git -C "$out" checkout -q "$branch" 2> /dev/null ||
      git -C "$out" checkout -q "$(git -C "$out" symbolic-ref --short refs/remotes/origin/HEAD 2> /dev/null | sed 's|^origin/||')" 2> /dev/null ||
      git -C "$out" checkout -q "$(git -C "$out" for-each-ref --count=1 --format='%(refname:short)' refs/heads)" 2> /dev/null ||
      echo "  no branch to check out for $s"
    [[ -f "$src/loose/$s.tar" ]] && tar -C "$out" -xf "$src/loose/$s.tar"
    [[ -f "$src/loose/$s.ignored.tar" ]] && tar -C "$out" -xf "$src/loose/$s.ignored.tar"
    # Stash patches are left beside the repo to apply by hand: replaying them
    # blind onto a fresh checkout would conflict silently.
    for sp in "$src/loose/$s.stash"*.patch; do
      [[ -f $sp ]] || continue
      cp "$sp" "$out/$(basename "$sp")"
      echo "  stash saved as $(basename "$sp"), apply with: git apply $(basename "$sp")"
    done
  done < "$src/manifest.tsv"

  for t in "$src"/loose/nogit_*.tar; do
    [[ -f $t ]] || continue
    tar -C "$dest" -xf "$t"
  done
  echo "Restored into $dest"
}

case "${1:-audit}" in
  audit) cmd_audit ;;
  pack)
    shift
    cmd_pack "$@"
    ;;
  restore)
    shift
    cmd_restore "$@"
    ;;
  *)
    echo "Usage: code-migrate.sh audit|pack <dest>|restore <src> [dest]"
    exit 1
    ;;
esac
