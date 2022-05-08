##############################################
# WD GEOGRAPHY * 12 - Download data from HDR #
##############################################

# load packages
pkgs <- c('data.table', 'fst', 'readxl')
lapply(pkgs, require, char = TRUE)

# set constants
ext_path <- file.path(Sys.getenv('PUB_PATH'), 'ext_data', 'wd')
fname <- file.path(ext_path, 'hdi', 'hdi.xlsx')
out_path <- file.path(Sys.getenv('PUB_PATH'), 'shiny_apps', 'wd_hdi')

# load datasets
download.file('http://hdr.undp.org/sites/default/files/2018_all_indicators.xlsx', destfile = fname, mode = 'wb')
excel_sheets(fname)
dts <- data.table( read_xlsx(fname, 'Data') )
dts[, indicator_id := as.integer(indicator_id)]
ftn <- data.table( read_xlsx(fname, 'Footnotes') ) 
dfn <- data.table( read_xlsx(fname, 'Definitions') ) 
src <- data.table( read_xlsx(fname, 'Sources') )
cnt <- fread(file.path(ext_path, 'countries.csv'))

# create "countries" table, with names and iso3 codes, use "iso3" and "country_name" from "Data"
countries <- cnt[iso3 %in% unique(dts[, iso3])]

# create "indicators" table using:
# - "indicator_id", "indicator_name", "dimension" from "Data"
# - "definition" from "Definitions"
# - "source" from "Sources"
indicators <- unique(dts[, .(indicator_id, name = indicator_name, dimension)])[order(dimension, name)]
indicators <- dfn[!is.na(definition)][, .(indicator_id = as.integer(indicator_id), definition)][indicators, on = 'indicator_id']
indicators <- src[, .(indicator_id = as.integer(indicator_id), source)][indicators, on = 'indicator_id']

# create "footnotes" table using "footnote_id" and "footnote" from "Footnotes"
footnotes <- unique(ftn[, .(footnote_id = as.integer(`footnote id`), footnote)])

# create "ind_foot" table using "indicator_id", "iso3", "year", "footnote id"  from "Footnotes"
ind_foot <- ftn[, .(indicator_id = as.integer(indicator_id), iso3, year, footnote_id = as.integer(`footnote id`))]

# delete "dimension", "indicator_name", "country_name", "9999" fom "Data"
dts[, `:=`(dimension = NULL, indicator_name = NULL, country_name = NULL, `9999` = NULL)]

# melt "Data" using all "XXXX" years columns, deleting all NA
dts <- melt(dts, id.vars = c('indicator_id', 'iso3'), variable.name = 'year', variable.factor = FALSE, na.rm = TRUE)
dts <- dts[, `:=`(iso3 = factor(iso3), year = as.integer(year))][order(indicator_id, iso3, year)]

# save final datasets
write_fst(countries, file.path(out_path, 'countries'))
write_fst(dts, file.path(out_path, 'dataset'))
write_fst(indicators, file.path(out_path, 'indicators'))
write_fst(footnotes, file.path(out_path, 'footnotes'))
write_fst(ind_foot, file.path(out_path, 'ind_foot'))
