#' Example scenes
#'
#' Ready-made scenes for public datasets:
#'
#' - `ngs_hemibrain_scene()`: the hemibrain (Scheffer et al., 2020) with EM
#'   data, segmentation and synapses, using the same settings as neuPrint
#' - `ngs_manc_scene()`: the male adult nerve cord (MANC; Takemura et al.,
#'   2024). This fetches the scene from a state server, so it requires an
#'   internet connection.
#'
#' @return A scene.
#' @name example-scenes
#' @examples
#' ngs_hemibrain_scene()
#' \dontrun{
#' ngs_manc_scene()
#' }
NULL

#' @rdname example-scenes
#' @export
ngs_hemibrain_scene <- function() {
  shader <- paste(
    '#uicontrol vec3 preColor color(default="yellow")',
    '#uicontrol vec3 postColor color(default="gray")',
    '#uicontrol float preConfidence slider(min=0, max=1, default=0)',
    '#uicontrol float postConfidence slider(min=0, max=1, default=0)',
    '#uicontrol float sliceViewOpacity slider(min=0, max=1, default=0.5)',
    '#uicontrol float projectionViewOpacity slider(min=0, max=1, default=0.3)',
    '',
    'void main() {',
    '  float opacity = PROJECTION_VIEW ? projectionViewOpacity : sliceViewOpacity;',
    '  setColor(vec4(defaultColor(), opacity));',
    '  setEndpointMarkerColor(',
    '    vec4(preColor, opacity),',
    '    vec4(postColor, opacity));',
    '  setEndpointMarkerBorderColor(',
    '    vec4(0, 0, 0, opacity),',
    '    vec4(0, 0, 0,     opacity)',
    '  );',
    '',
    '  setEndpointMarkerSize(5.0, 5.0);',
    '  setLineWidth(2.0);',
    '  if (prop_pre_synaptic_confidence()< preConfidence ||',
    '  prop_post_synaptic_confidence()< postConfidence) discard;',
    '}',
    '',
    sep = "\n"
  )

  ngs_scene(
    ngs_image_layer(
      "precomputed://gs://neuroglancer-janelia-flyem-hemibrain/emdata/clahe_yz/jpeg",
      name = "hemibrain:v1.2.1-grayscalejpeg"
    ),
    ngs_segmentation_layer(
      "precomputed://gs://neuroglancer-janelia-flyem-hemibrain/v1.2/segmentation",
      name = "hemibrain:v1.2.1"
    ),
    ngs_annotation_layer(
      "precomputed://gs://neuroglancer-janelia-flyem-hemibrain/v1.2/synapses",
      name = "hemibrain:v1.2.1-synapses",
      shader = shader,
      linkedSegmentationLayer = list(pre_synaptic_cell = "hemibrain:v1.2.1",
                                     post_synaptic_cell = "hemibrain:v1.2.1"),
      filterBySegmentation = c("post_synaptic_cell", "pre_synaptic_cell")
    ),
    dimensions = list(x = list(8e-9, "m"), y = list(8e-9, "m"),
                      z = list(8e-9, "m")),
    position = c(3761, 19530, 13253),
    crossSectionScale = 1,
    projectionOrientation = c(0.10976426303386688, -0.32929277420043945,
                              -0.32929277420043945, 0.8781141042709351),
    projectionScale = 983.7572106361007
  )
}

#' @rdname example-scenes
#' @export
ngs_manc_scene <- function() {
  ngs_from_url(paste0("https://neuroglancer-demo.appspot.com/#!gs://",
                      "flyem-user-links/short/2024-10-22.084840.490679.json"))
}
