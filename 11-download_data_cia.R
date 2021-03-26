#######################################################
# WD GEOGRAPHY * 11 - Download data from CIA FactBook #
#######################################################

# Load packages
pkgs <- c('data.table', 'htmltab', 'RMySQL', 'rvest')
lapply(pkgs, require, char = TRUE)

# Set constants
data_path <- file.path(Sys.getenv('PUB_PATH'), 'datasets', 'wd', 'geography')

# download variable list
y <- read_html('https://www.cia.gov/library/publications/resources/the-world-factbook/docs/rankorderguide.html') 
vars <- cbind(
            y %>% 
                html_nodes('.field_label a') %>%
                html_attr('href'),
            y %>% 
                html_nodes('.field_label') %>%
                html_text() %>% 
                trimws()
        ) %>% 
            as.data.table() %>% 
            setnames(c('var_id', 'name'))

# add variable domain
dom <- y %>% 
    html_nodes('#profileguide div') %>%
    html_text() %>% 
    trimws() %>% 
    as.data.table() %>% 
    setnames('name')
dom[, domain := ifelse(grepl('::', name), name, NA)][, domain := zoo::na.locf(domain)]
vars <- dom[vars, on = 'name']
vars[, `:=`( var_id = gsub('[^0-9]', '', var_id), name = gsub(':', '', name), domain = gsub(':', '', domain) )]
setcolorder(vars, 'var_id')

# download data
dts <- data.table(var_id = integer(0), 'country' = character(0), 'value' = numeric(0), 'updated_at' = character(0))
for(idx in 1:nrow(vars)){
    message('Processing <', vars[idx, name], '>...')
    url <- paste0('https://www.cia.gov/library/publications/resources/the-world-factbook/fields/', vars[idx, var_id], 'rank.html')
    y <- read_html(url) %>% 
            html_nodes('td') %>% 
            html_text() %>% 
            trimws() %>% 
            matrix(ncol = 4, byrow = TRUE) %>% 
            as.data.table()
    y[, V3 := gsub('[^0-9.]', '', V3)][, V1 := NULL][, var_id := vars[idx, var_id]]
    setnames(y, c('country', 'value', 'updated_at', 'var_id'))
    dts <- rbindlist(list( dts, y ), use.names = TRUE)
}

# recode country as iso3
cnt <- read_fst(file.path(data_path, 'countries'), columns = c('iso3', 'cia_name'), as.data.table = TRUE)
setnames(cnt, c('iso3', 'country'))
dts <- cnt[dts, on = 'country'][!is.na(iso3)][, country := NULL]
setcolorder(dts, c('var_id', 'iso3'))

# save in database
dbc <- dbConnect(MySQL(), group = 'dataOps', dbname = 'geography_wd')
dbSendQuery(dbc, "TRUNCATE TABLE factbook")
dbWriteTable(dbc, 'factbook', vars, row.names = FALSE, append = TRUE)
dbSendQuery(dbc, "TRUNCATE TABLE factvalues")
dbWriteTable(dbc, 'factvalues', dts, row.names = FALSE, append = TRUE)
dbDisconnect(dbc)

# update geodemo columns in countries table
var_ids <- c('area' = 279, 'pop' = 335, 'gdp' = 208, 'life_exp' = 355)
dbc <- dbConnect(MySQL(), group = 'dataOps', dbname = 'geography_wd')
for(idx in 1:length(var_ids))
    dbSendQuery(dbc, paste0("
        UPDATE countries c 
            JOIN (SELECT iso3, value FROM factvalues WHERE var_id = ", var_ids[idx], ") t on t.iso3 = c.iso3 
        SET c.", names(var_ids)[idx], " = t.value", ifelse(var_ids[idx] %in% c(208), '/1000000', '')
    ))
dbDisconnect(dbc)
  
# retrieve updated countries table, then save as fst
dbc <- dbConnect(MySQL(), group = 'dataOps', dbname = 'geography_wd')
cnt <- dbReadTable(dbc, 'countries')
dbDisconnect(dbc)
write_fst(cnt, file.path(data_path, 'countries'))

# clean and exit
rm(list = ls())
gc()
