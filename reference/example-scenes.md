# Example scenes

Ready-made scenes for public datasets:

## Usage

``` r
ngs_hemibrain_scene()

ngs_manc_scene()
```

## Value

A scene.

## Details

- `ngs_hemibrain_scene()`: the hemibrain (Scheffer et al., 2020) with EM
  data, segmentation and synapses, using the same settings as neuPrint

- `ngs_manc_scene()`: the male adult nerve cord (MANC; Takemura et al.,
  2024). This fetches the scene from a state server, so it requires an
  internet connection.

## Examples

``` r
ngs_hemibrain_scene()
#> <ngs_scene> 3 layers: 1 image, 1 segmentation, 1 annotation
#> Base URL: https://neuroglancer-demo.appspot.com/
#> 1: <image layer> "hemibrain:v1.2.1-grayscalejpeg" precomputed:/...clahe_yz/jpeg
#> 2: <segmentation layer> "hemibrain:v1.2.1" precompute...gmentation (0 segments)
#> 3: <annotation layer> "hemibrain:v1.2.1-synapses" precomputed:/...v1.2/synapses
if (FALSE) { # \dontrun{
ngs_manc_scene()
} # }
```
