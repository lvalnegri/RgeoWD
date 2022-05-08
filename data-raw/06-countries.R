##########################################################################
# CRAN - Source Data about Countries from CIA World Factbnook Website
##########################################################################

dmpkg.funs::load_pkgs(dmp = FALSE, 'data.table', 'rvest')
dbn <- 'cran'

url <- 'https://www.cia.gov'

yf <- paste0(url, '/the-world-factbook/references/guide-to-country-comparisons/') |> 
            read_html() |> 
            html_elements('.link-button')

yf <- data.table( fact = yf %>% html_text(), url = yf %>% html_attr('href') )[, `:=`( id = 1:.N, unit = NA_character_ )]

y <- rbindlist(
        lapply( 
            1:nrow(yf), 
            \(x) data.table( yf[x]$id, (paste0(url, yf[x]$url) |> read_html() |> html_table())[[1]] ) 
        ), 
        use.names = FALSE
)
setnames(y, c('fact_id', 'ordering', 'country', 'value', 'updated_at'))
y[, `:=`( value = as.numeric(gsub(',|\\$', '', value)), updated_at = gsub('.*([0-9]{4}).*', '\\1', updated_at) )]
y[!grepl('[0-9]{4}', updated_at), updated_at := NA]
dd_dbm_do(dbn, 'w', 'countries_facts', y)

for(x in 1:nrow(yf)) yf[x, unit := names(y[[yf[x, id]]])[4] ]
yf[unit == 'V1', unit := NA]
dd_dbm_do(dbn, 'w', 'facts', yf)


yt <- dd_dbm_do('cran', 'q', strSQL = 'SELECT iso2, name_cia AS country FROM countries')
values <- yt[y, on = 'country'][, country := NULL][!is.na(iso2)][order(fact_id, iso2)]

rm(list = ls())
gc()
