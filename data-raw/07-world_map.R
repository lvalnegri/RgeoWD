#################################################
# CRAN - Download and merge country shapefiles
#################################################

dmpkg.funs::load_pkgs(dmp = FALSE, 'data.table', 'sf')

yc <- dd_dbm_do('cran', 'q', strSQL = 'SELECT iso3 FROM countries') 

tmpf <- tempfile()
tmpd <- tempdir()
missed <- character(0)
for(x in yc$iso3){
    tryCatch({
        message('Downloading ', x)
        download.file(paste0('https://geodata.ucdavis.edu/gadm/gadm4.0/shp/gadm40_', x, '_shp.zip'), tmpf, quiet = TRUE)
        unzip(tmpf, exdir = tmpd)
    }, error = function(err) {
        message(' >>> Sorry, could NOT do it!\n')
        missed <- c(missed, x)
    })
}
print('Job Done!')
print(paste('Missed Downloads:', missed))

# unzip all files keeping only the shapes for the whole country
znames <- list.files('shp', 'zip')
for(zn in znames){
    cat(paste('Decompressing', zn, '\n'))
    fnames <- unzip(paste0('shp/', zn), list = TRUE)[1]
    fnames <- fnames[grepl('0', fnames$Name),]
    fnames <- fnames[!grepl('c', fnames)]
    unzip(paste0('shp/', zn), files = fnames, exdir = 'shp')
}

# "+proj=utm +zone=10 +datum=WGS84"
proj.wgs <- '+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0'
wbnd <- SpatialPolygons(list())
proj4string(wbnd) <-CRS(proj.wgs)


# read, clean and merge all shapefiles
bnames <- list.files('shp', 'shp')
for(bn in bnames){
    cat(paste('Reading shapefile', zn, '\n'))
    bn = substr(bn, 1, nchar(bn) - 4)
    bnd <- readOGR('shp', bn)
    cat('Clean data slot and reassign id')
    bnd <- bnd[, 'ISO']
    colnames(bnd@data) <- c('id')
    bnd <- spChFIDs(bnd, as.character(bnd$id))
    cat('Transform to same reference system')
    bnd <- spTransform(bnd, CRS("+proj=utm +zone=10 +datum=WGS84"))
    cat('Merging with previous boundaries')
    wbnd <- spRbind(wbnd, bnd)
}
writeOGR(wbnd, dsn = 'shp', layer = 'world', driver = 'ESRI Shapefile')
