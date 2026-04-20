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
# Local source-only git: ignore everything by default, then allow only UE source trees.

/*

!/Tsl/
!/Engine/

/_Package/
/output/
/Saved/
/Intermediate/
/Binaries/

# Tsl root: allow Source and plugin traversal only
/Tsl/*
!/Tsl/Source/
!/Tsl/Plugins/

/Tsl/Binaries/
/Tsl/Intermediate/
/Tsl/Saved/

# Tsl source: allow only common source file extensions
/Tsl/Source/**
!/Tsl/Source/**/
!/Tsl/Source/**/*.h
!/Tsl/Source/**/*.hh
!/Tsl/Source/**/*.hpp
!/Tsl/Source/**/*.hxx
!/Tsl/Source/**/*.inl
!/Tsl/Source/**/*.inc
!/Tsl/Source/**/*.ipp
!/Tsl/Source/**/*.c
!/Tsl/Source/**/*.cc
!/Tsl/Source/**/*.cpp
!/Tsl/Source/**/*.cxx
!/Tsl/Source/**/*.m
!/Tsl/Source/**/*.mm
!/Tsl/Source/**/*.ixx
!/Tsl/Source/**/*.cppm
!/Tsl/Source/**/*.cs
!/Tsl/Source/**/*.rc
!/Tsl/Source/**/*.def

# Tsl plugins: allow only Source trees and source file extensions
/Tsl/Plugins/**
!/Tsl/Plugins/**/
!/Tsl/Plugins/**/Source/
!/Tsl/Plugins/**/Source/**/
!/Tsl/Plugins/**/Source/**/*.h
!/Tsl/Plugins/**/Source/**/*.hh
!/Tsl/Plugins/**/Source/**/*.hpp
!/Tsl/Plugins/**/Source/**/*.hxx
!/Tsl/Plugins/**/Source/**/*.inl
!/Tsl/Plugins/**/Source/**/*.inc
!/Tsl/Plugins/**/Source/**/*.ipp
!/Tsl/Plugins/**/Source/**/*.c
!/Tsl/Plugins/**/Source/**/*.cc
!/Tsl/Plugins/**/Source/**/*.cpp
!/Tsl/Plugins/**/Source/**/*.cxx
!/Tsl/Plugins/**/Source/**/*.m
!/Tsl/Plugins/**/Source/**/*.mm
!/Tsl/Plugins/**/Source/**/*.ixx
!/Tsl/Plugins/**/Source/**/*.cppm
!/Tsl/Plugins/**/Source/**/*.cs
!/Tsl/Plugins/**/Source/**/*.rc
!/Tsl/Plugins/**/Source/**/*.def

/Tsl/Plugins/**/Binaries/
/Tsl/Plugins/**/Intermediate/
/Tsl/Plugins/**/Saved/

# Engine root: allow Source and plugin traversal only
/Engine/*
!/Engine/Source/
!/Engine/Plugins/

/Engine/Binaries/
/Engine/Intermediate/
/Engine/Saved/

# Engine source: allow only common source file extensions
/Engine/Source/**
!/Engine/Source/**/
!/Engine/Source/**/*.h
!/Engine/Source/**/*.hh
!/Engine/Source/**/*.hpp
!/Engine/Source/**/*.hxx
!/Engine/Source/**/*.inl
!/Engine/Source/**/*.inc
!/Engine/Source/**/*.ipp
!/Engine/Source/**/*.c
!/Engine/Source/**/*.cc
!/Engine/Source/**/*.cpp
!/Engine/Source/**/*.cxx
!/Engine/Source/**/*.m
!/Engine/Source/**/*.mm
!/Engine/Source/**/*.ixx
!/Engine/Source/**/*.cppm
!/Engine/Source/**/*.cs
!/Engine/Source/**/*.rc
!/Engine/Source/**/*.def

# Engine plugins: allow only Source trees and source file extensions
/Engine/Plugins/**
!/Engine/Plugins/**/
!/Engine/Plugins/**/Source/
!/Engine/Plugins/**/Source/**/
!/Engine/Plugins/**/Source/**/*.h
!/Engine/Plugins/**/Source/**/*.hh
!/Engine/Plugins/**/Source/**/*.hpp
!/Engine/Plugins/**/Source/**/*.hxx
!/Engine/Plugins/**/Source/**/*.inl
!/Engine/Plugins/**/Source/**/*.inc
!/Engine/Plugins/**/Source/**/*.ipp
!/Engine/Plugins/**/Source/**/*.c
!/Engine/Plugins/**/Source/**/*.cc
!/Engine/Plugins/**/Source/**/*.cpp
!/Engine/Plugins/**/Source/**/*.cxx
!/Engine/Plugins/**/Source/**/*.m
!/Engine/Plugins/**/Source/**/*.mm
!/Engine/Plugins/**/Source/**/*.ixx
!/Engine/Plugins/**/Source/**/*.cppm
!/Engine/Plugins/**/Source/**/*.cs
!/Engine/Plugins/**/Source/**/*.rc
!/Engine/Plugins/**/Source/**/*.def

/Engine/Plugins/**/Binaries/
/Engine/Plugins/**/Intermediate/
/Engine/Plugins/**/Saved/
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

The default exclude rules keep this repo source-only.
EOF
