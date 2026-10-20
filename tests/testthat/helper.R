fixture <- function(name) test_path("fixtures", name)

TEST_URL <- readLines(fixture("fafb_url.txt"), warn = FALSE)

# Modelled on a published neuPrint scene: layers omit keys nglscenes has
# defaults for (`selectedAlpha`, `segments`, `blend`, `annotations`, ...)
PUBLISHED <- list(
  dimensions = list(x = list(8e-9, "m"), y = list(8e-9, "m"),
                    z = list(8e-9, "m")),
  position = list(17213.5, 19737.5, 20577.5),
  layout = "xy-3d",
  layers = list(
    list(type = "image",
         source = "precomputed://gs://neuroglancer-janelia-flyem-hemibrain/emdata/clahe_yz/jpeg",
         name = "emdata"),
    list(type = "segmentation",
         source = "precomputed://gs://neuroglancer-janelia-flyem-hemibrain/v1.2/segmentation",
         segmentColors = list("1734350788" = "#FF0000"),
         name = "segmentation"),
    list(type = "annotation",
         source = "precomputed://gs://neuroglancer-janelia-flyem-hemibrain/v1.2/synapses",
         name = "synapses")
  )
)

SEUNGLAB_LAYER <- list(
  type = "segmentation_with_graph",
  source = "graphene://https://prod.flywire-daf.com/segmentation/1.0/flywire_public",
  name = "flywire"
)

SPELUNKER_LAYER <- list(
  type = "segmentation",
  source = list(
    url = "graphene://middleauth+https://prod.flywire-daf.com/segmentation/1.0/flywire_public",
    subsources = list(bounds = FALSE)
  ),
  name = "flywire"
)

state_of <- function(...) list(layout = "3d", layers = list(...))

# Compare two states as (canonical) JSON: key order doesn't matter
expect_same_state <- function(object, expected) {
  canon <- function(x) nglscenes:::to_json(as.list(x))
  expect_identical(canon(object), canon(expected))
}

url_state <- function(url) nglscenes:::as_state(url)
