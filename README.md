# 45393

Reproduction for [Renovate Discussion 45393](https://github.com/renovatebot/renovate/discussions/45393).

## Current behavior

`renovate.json` sets `rangeStrategy` to `widen`. `mix.exs` requires
`{:excoveralls, "~> 0.17"}`. The newest `excoveralls` on hex is `0.18.5`.

Renovate opens a pull request that widens the requirement:

```diff
-      {:excoveralls, "~> 0.17", only: :test, runtime: false},
+      {:excoveralls, "~> 0.17 or ~> 0.18", only: :test, runtime: false},
```

## Expected behavior

No pull request at all, because the requirement already permits `0.18.5`.

In hex, `~>` permits the **right-most** part to increase. From the
[Elixir `Version` docs](https://hexdocs.pm/elixir/Version.html#module-requirements):

| requirement | meaning |
| --- | --- |
| `~> 2.1.2` | `>= 2.1.2 and < 2.2.0` |
| `~> 2.1` | `>= 2.1.0 and < 3.0.0` |
| `~> 0.17` | `>= 0.17.0 and < 1.0.0` |

There is no special case for major `0`. Hex itself resolves `~> 0.17` to
`0.18.5`:

```console
$ mix deps.update excoveralls
Upgraded:
  excoveralls 0.17.1 => 0.18.5 (minor)
```

Renovate already gets the equivalent case right when the major is `1`: for
`{:credo, "~> 1.6"}` with `1.7.19` released, it correctly opens no pull request.
Only a two-part `~>` with major `0` is affected.

## Link to the Renovate issue or Discussion

<https://github.com/renovatebot/renovate/discussions/45393>
