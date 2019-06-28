########################################################
# WD GEOGRAPHY * 16 - Download flags from CIA FactBook #
########################################################

# load packages
library(data.table)

# Set constants
data_path <- file.path(Sys.getenv('PUB_PATH'), 'ancillaries', 'wd')

# load data
countries <- fread(file.path(data_path, 'geography', 'countries.csv'))
countries <- countries[fips != '' | !is.na(fips)]

# download images
for(idx in 1:nrow(countries)){
    message('Downloading ', countries[idx, short_name], '...')
    tryCatch({
            download.file(
                paste0(
                    'https://www.cia.gov/library/publications/resources/the-world-factbook/attachments/flags/', 
                    countries[idx, fips], 
                    '-flag.gif'
                ),
                destfile = file.path(data_path, 'flags', paste0(countries[idx, iso3], '.gif'))
            )
        }, error = function(err) {
            message('NOT FOUND!\n')
    })
}
