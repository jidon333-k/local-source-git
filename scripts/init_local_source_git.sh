#!/usr/bin/env bash
set -euo pipefail

project_root="."
git_dir_input=""
initial_branch="local-main"

usage() {
	cat <<'EOF'
Usage:
  init_local_source_git.sh [--project-root PATH] [--git-dir PATH] [--initial-branch NAME]

Defaults:
  --project-root    .
  --git-dir         ../LocalGit/<project-name>-source-only
  --initial-branch  local-main

Both --project-root and --git-dir may be relative. The git-dir path is interpreted
relative to the project root and is written back to <project-root>/.git as a
relative gitdir pointer so both WSL and Windows tools can read it.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--project-root)
			project_root="$2"
			shift 2
			;;
		--git-dir)
			git_dir_input="$2"
			shift 2
			;;
		--initial-branch)
			initial_branch="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			usage >&2
			exit 1
			;;
	esac
done

project_root="$(cd "$project_root" && pwd -P)"
project_name="$(basename "$project_root")"

if [[ -z "$git_dir_input" ]]; then
	git_dir_input="../LocalGit/${project_name}-source-only"
fi

git_dir_abs="$(cd "$project_root" && mkdir -p "$(dirname "$git_dir_input")" && cd "$(dirname "$git_dir_input")" && pwd -P)/$(basename "$git_dir_input")"
git_dir_rel="$(realpath --relative-to="$project_root" "$git_dir_abs")"

if git -C "$project_root" rev-parse --git-dir >/dev/null 2>&1; then
	current_git_dir_raw="$(git -C "$project_root" rev-parse --git-dir)"
	current_git_dir_abs="$(cd "$project_root" && cd "$current_git_dir_raw" && pwd -P)"
	if [[ "$current_git_dir_abs" != "$git_dir_abs" ]]; then
		echo "Project root already points to a different git dir:" >&2
		echo "  current: $current_git_dir_abs" >&2
		echo "  wanted : $git_dir_abs" >&2
		exit 1
	fi
else
	mkdir -p "$git_dir_abs"
	git init --separate-git-dir "$git_dir_abs" "$project_root" >/dev/null
fi

printf 'gitdir: %s\n' "$git_dir_rel" > "$project_root/.git"

git -C "$project_root" config --local status.showUntrackedFiles no
git -C "$project_root" config --local core.fileMode false
git -C "$project_root" config --local core.autocrlf false

if ! git -C "$project_root" config --local --get user.name >/dev/null 2>&1 && ! git -C "$project_root" config --global --get user.name >/dev/null 2>&1; then
	git -C "$project_root" config --local user.name "Local Source Git"
fi

if ! git -C "$project_root" config --local --get user.email >/dev/null 2>&1 && ! git -C "$project_root" config --global --get user.email >/dev/null 2>&1; then
	git -C "$project_root" config --local user.email "local-source-git@example.invalid"
fi

git -C "$project_root" symbolic-ref HEAD "refs/heads/$initial_branch"

exclude_file="$git_dir_abs/info/exclude"
mkdir -p "$(dirname "$exclude_file")"
cat > "$exclude_file" <<'EOF'
/_Package/
/output/
/Saved/
/Intermediate/
/Binaries/
**/Saved/
**/Intermediate/
**/Binaries/
EOF

cat <<EOF
Initialized local source git
  project root : $project_root
  git dir      : $git_dir_abs
  .git pointer : $git_dir_rel
  branch       : $initial_branch

Suggested next steps:
  git add Tsl/Source
  git add Tsl/Plugins/*/Source
  git add Engine/Source
  git add Engine/Plugins/*/Source
EOF
