

# Aim: functions in this script download data from the urban observatory


#' Download data
#'
#' @param period 
#' @param dataset 
#' @param base_url 
#' @param download_directory 
#'
#' @return
#' @export
#'
#' @examples
#' # Example file:
#' u = "https://archive.dev.urbanobservatory.ac.uk/file/month_file/2022-4-Walking.csv.zip"
#' f = basename(u)
#' download.file(u, f)
#' month = "2022-04"
#' dir.create("data")
#' download_urban_data(month)
#' # "https://archive.dev.urbanobservatory.ac.uk/file/month_file/2021-1-People%20Count.csv.zip"
download_urban_data = function(
    period,
    dataset = "Walking",
    base_url = "https://archive.dev.urbanobservatory.ac.uk/file/month_file/",
    download_directory = "data"
    ) {
  period_formatted = gsub(pattern = "-0", replacement = "-", x = period)
  u = paste0(
    base_url,
    period_formatted,
    "-",
    dataset,
    ".csv.zip"
  )
  f = file.path(download_directory, basename(u))
  if(!file.exists(f)) {
    # Test:
    # u = "https://archive.dev.urbanobservatory.ac.uk/file/month_file/2021-4-People%20Count.csv.zip"
    url_is_ok = crul::ok(u)
    if(url_is_ok) {
      download.file(u, f)
    } else {
      message("URL missing: ", u)
    }
  }
}
