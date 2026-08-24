# 45393

Reproduction for [Renovate Discussion 45393](https://github.com/renovatebot/renovate/discussions/45393).

## Current behavior

`renovate.json` sets `rangeStrategy` to `widen`. `mix.exs` requires
`{:ecto_psql_extras, "~> 0.7"}`. The newest `ecto_psql_extras` on hex is `0.8.8`.

Renovate opens a pull request that widens the requirement:

```diff
-    [{:ecto_psql_extras, "~> 0.7"}]
+    [{:ecto_psql_extras, "~> 0.7 or ~> 0.8"}]
```

## Expected behavior

No pull request at all, because the requirement already permits `0.8.8`.

In hex, `~>` permits the **right-most** part to increase. From the
[Elixir `Version` docs](https://hexdocs.pm/elixir/Version.html#module-requirements):

| requirement | meaning |
| --- | --- |
| `~> 2.1.2` | `>= 2.1.2 and < 2.2.0` |
| `~> 2.1` | `>= 2.1.0 and < 3.0.0` |
| `~> 0.7` | `>= 0.7.0 and < 1.0.0` |

There is no special case for major `0`. Hex itself resolves `~> 0.7` to
`0.8.8`:

```console
$ mix deps.get
Resolving Hex dependencies...
Resolution completed in 0.608s
New:
  ecto_psql_extras 0.8.8
```

Renovate already gets the equivalent case right when the major is `1`: for
`{:credo, "~> 1.6"}` with `1.7.19` released, it correctly opens no pull request.
Only a two-part `~>` with major `0` is affected.

## Link to the Renovate issue or Discussion

<https://github.com/renovatebot/renovate/discussions/45393>
