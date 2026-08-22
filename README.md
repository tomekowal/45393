# Renovate: `rangeStrategy: widen` misreads hex `~>` when the major is 0

Minimal reproducible example for a defect in Renovate's `hex` versioning module.

## Summary

For a two-part `~>` requirement with major version `0`, Renovate believes the
upper bound is the next **minor** version. Hex puts it at the next **major**
version. Renovate therefore widens a requirement that is already satisfied:

```diff
-      {:excoveralls, "~> 0.17", only: :test, runtime: false},
+      {:excoveralls, "~> 0.17 or ~> 0.18", only: :test, runtime: false},
```

`~> 0.17` already permits `0.18.5`, so the correct result is no change at all.

## The `~>` rule

From the [Elixir `Version` docs](https://hexdocs.pm/elixir/Version.html#module-requirements),
`~>` allows the **right-most** part to increase:

| requirement | meaning |
| --- | --- |
| `~> 2.1.2` | `>= 2.1.2 and < 2.2.0` |
| `~> 2.1` | `>= 2.1.0 and < 3.0.0` |
| `~> 0.17` | `>= 0.17.0 and < 1.0.0` |
| `~> 0.13.0` | `>= 0.13.0 and < 0.14.0` |

There is no special case for major `0`. This is the same rule Bundler uses for
Ruby's pessimistic operator.

## What this repo contains

`mix.exs` holds four real hex packages. Two show the defect, two are controls
that Renovate already handles correctly.

| dep | requirement | locked | latest | hex permits latest? | Renovate proposes |
| --- | --- | --- | --- | --- | --- |
| `excoveralls` | `~> 0.17` | 0.17.1 | 0.18.5 | **yes** | ❌ `~> 0.17 or ~> 0.18` |
| `req` | `~> 0.6` | 0.6.3 | 0.7.3 | **yes** | ❌ `~> 0.6 or ~> 0.7` |
| `sobelow` | `~> 0.13.0` | 0.13.0 | 0.15.0 | no | ✅ `~> 0.13.0 or ~> 0.15.0` |
| `credo` | `~> 1.6` | 1.6.7 | 1.7.19 | **yes** | ✅ no update |

The `credo` row is the important contrast: it is the same shape as the
`excoveralls` row, only with major `1` instead of major `0`, and Renovate gets
it right. The defect is limited to **two-part `~>` with major `0`**.

None of `excoveralls`, `req` and `sobelow` has ever published a 1.0.

## Hex itself agrees

The requirements in `mix.exs` are unchanged, only `mix deps.update` is run:

```console
$ mix deps.update excoveralls req sobelow credo
Upgraded:
  credo 1.6.7 => 1.7.19
  excoveralls 0.17.1 => 0.18.5 (minor)
  req 0.6.3 => 0.7.3 (minor)
```

`excoveralls` moved to `0.18.5` under `~> 0.17`, and `req` moved to `0.7.3`
under `~> 0.6`. `sobelow` stayed at `0.13.0`, because its three-part `~> 0.13.0`
really does stop below `0.14.0`.

## Live evidence

Renovate ran on this repo through the GitHub Action and opened these pull
requests:

| PR | dep | change | correct? |
| --- | --- | --- | --- |
| [#1](https://github.com/tomekowal/renovate-hex-widen-repro/pull/1) | `excoveralls` | `~> 0.17` &rarr; `~> 0.17 or ~> 0.18` | ❌ no change was necessary |
| [#2](https://github.com/tomekowal/renovate-hex-widen-repro/pull/2) | `req` | `~> 0.6` &rarr; `~> 0.6 or ~> 0.7` | ❌ no change was necessary |
| [#3](https://github.com/tomekowal/renovate-hex-widen-repro/pull/3) | `sobelow` | `~> 0.13.0` &rarr; `~> 0.13.0 or ~> 0.15.0` | ✅ correct |

`credo` correctly received no pull request.

## How to reproduce

Against a Renovate checkout:

```console
$ git clone https://github.com/tomekowal/renovate-hex-widen-repro
$ cd renovate-hex-widen-repro
$ LOG_LEVEL=debug RENOVATE_PLATFORM=local node /path/to/renovate/lib/renovate.ts
```

Observed, in the `packageFiles` debug output:

```json
{ "depName": "excoveralls", "currentValue": "~> 0.17", "lockedVersion": "0.17.1",
  "updates": [ { "newVersion": "0.18.5", "newValue": "~> 0.17 or ~> 0.18",
                 "updateType": "minor" } ] }

{ "depName": "req", "currentValue": "~> 0.6", "lockedVersion": "0.6.3",
  "updates": [ { "newVersion": "0.7.3", "newValue": "~> 0.6 or ~> 0.7",
                 "updateType": "minor" } ] }
```

Expected: `"updates": []` for both, exactly as `credo` already gives.

The defect is reachable through `matches()` as well, so it is not limited to
`widen`:

```
matches("0.18.5", "~> 0.17")  => false    (hex says true)
matches("0.7.3",  "~> 0.6")   => false    (hex says true)
matches("1.3.0",  "~> 1.2")   => true     (correct)
```

`replace`, `bump` and `auto` are affected too: each moves `~> 0.17` to
`~> 0.18`, which narrows the requirement instead of leaving it alone.

## Running Renovate on this repo

`.github/workflows/renovate.yml` runs the self-hosted
[`renovatebot/github-action`](https://github.com/renovatebot/github-action) on
`workflow_dispatch`. It needs no paid product; the default `GITHUB_TOKEN` is
sufficient to open the pull requests. Put a PAT in the `RENOVATE_TOKEN` secret
if richer changelogs are wanted.

`renovate.json` sets `enabledManagers: ["mix"]` to keep the run focused on the
defect.

## Side note: the default erlang constraint blocks the `mix.lock` update

`renovate.json` sets `constraints.erlang` to `^27.0.0`. Without it, the run
fails to update `mix.lock`:

```
INFO: Installing tool elixir@1.20.3...
ERROR! Unsupported Erlang/OTP version, expected Erlang/OTP 27+
FATAL: Install tool elixir failed in 1.9s.
```

`lib/modules/manager/mix/artifacts.ts` defaults `constraints.erlang` to `^26`,
while current Elixir needs OTP 27 or later. Renovate still opens the pull
request, but with a lock file error attached. This is separate from the `~>`
defect above.
