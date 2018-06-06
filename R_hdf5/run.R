library(dplyr, warn.conflicts = FALSE)
library(readr, warn.conflicts = FALSE)
library(hdf5r)

## Load data -----------------------------------------------
file <- H5File$new("/input/data.h5", "r")
expression <- file[["expression"]][,]
rownames(expression) <- h5attr(file[["expression"]], "rownames")
if(file$exists("start_cells")) {
  start_cells <- file[["start_cells"]][]
} else {
  start_cells <- NULL
}
file$close()

params <- jsonlite::read_json("/input/params.json", simplifyVector = TRUE)

## Trajectory inference -----------------------------------
# do PCA
pca <- prcomp(expression)

# extract the component and use it as pseudotimes
pseudotime <- pca$x[, params$component]

# flip pseudotimes using start_cells
if (!is.null(start_cells)) {
  if(mean(pseudotime[start_cells]) > 0.5) {
    pseudotime <- 1-pseudotime
  }
}

## Save output ---------------------------------------------
tibble::enframe(pseudotime, "cell_id", "pseudotime") %>% 
  write_csv("/output/pseudotime.csv")