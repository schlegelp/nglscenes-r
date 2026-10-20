# Get a CAVE token

Looks up the token used to fetch scenes from CAVE state servers (e.g.
for FlyWire). In order, this checks:

## Usage

``` r
ngs_cave_token(domain = "prod.flywire-daf.com")
```

## Arguments

- domain:

  Domain(s) to look for a domain-specific secret file for.

## Value

The token (a string).

## Details

1.  the `CAVE_TOKEN` and `CHUNKEDGRAPH_SECRET` environment variables

2.  the `cloudvolume` secrets in `~/.cloudvolume/secrets/`:
    `{domain}-cave-secret.json` for each `domain`, then
    `cave-secret.json` and `chunkedgraph-secret.json`

This is compatible with tokens set up via Python's `cloudvolume` /
`caveclient` or `fafbseg::flywire_set_token()`.

## Examples

``` r
if (FALSE) { # \dontrun{
ngs_cave_token()
} # }
```
