##################################################
# WD GEOGRAPHY * 01 - Create database and tables #
##################################################

library(dmpkg.funs)

dbn <- 'geography_wd'

dd_create_db(dbn)

# COUNTRIES ---------------------------
x = "
    name char(55) NOT NULL,
    alt_name char(45) NOT NULL,
    cia_name char(50) DEFAULT NULL,
    iso3 char(3) NOT NULL,
    iso2 char(2) NOT NULL,
    isoN smallint(3) unsigned NOT NULL,
    fips char(2) DEFAULT NULL,
    x_lon decimal(10,3) DEFAULT NULL,
    y_lat decimal(10,3) DEFAULT NULL,
    area int(10) unsigned DEFAULT NULL,
    pop int(11) DEFAULT NULL,
    gdp int(11) DEFAULT NULL,
    gdp_ppp int(11) DEFAULT NULL,
    hdi int(11) DEFAULT NULL,
    cpi int(11) DEFAULT NULL,
    currency char(3) DEFAULT NULL,
    capital char(25) DEFAULT NULL,
    pop_cap int(11) DEFAULT NULL,
    tld char(2) DEFAULT NULL,
    tz char(20) DEFAULT NULL,
    phone char(10) DEFAULT NULL,
    iso_aff char(2) DEFAULT NULL,
    region char(35) NOT NULL,
    continent char(10) NOT NULL,
    who_region char(3) DEFAULT NULL,
    who_subregion char(1) DEFAULT NULL,
    income_group char(20) DEFAULT NULL,
    PRIMARY KEY (iso3),
    UNIQUE KEY iso2 (iso2),
    KEY continent (continent),
    KEY region (region),
    KEY income_group (income_group),
    KEY who_region (who_region),
    KEY who_subregion (who_subregion),
    KEY isoN (isoN),
    KEY fips (fips),
    KEY currency (currency)
"
y <- fread(file.path(in_path, 'countries.csv'))
dd_create_dbtable('countries', 'geography_wd', x, y)
cols <- c('iso3', 'iso2', 'fips', 'currency', 'iso_aff', 'region', 'continent', 'who_region', 'who_subregion', 'income_group')
y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
write_fst(y, file.path(out_path, 'countries'))

# NEIGHBOURS --------------------------
x = "
    iso3a char(3) NOT NULL,
    iso3b char(3) NOT NULL
"
y <- fread(file.path(in_path, 'neighbours.csv'))
dd_create_dbtable('neighbours', 'geography_wd', x, y)
cols <- c('iso3a', 'iso3b')
y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
write_fst(y, file.path(out_path, 'neighbours'))

# GROUPS ------------------------------
x = "
    code char(3) NOT NULL,
    name char(55) NOT NULL
"
y <- fread(file.path(in_path, 'groups.csv'))
dd_create_dbtable('groups', 'geography_wd', x, y)
cols <- c('code')
y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
write_fst(y, file.path(out_path, 'groups'))

# GROUPS_COUNTRIES --------------------
x = "
    group_code char(3) NOT NULL,
    iso3 char(3) NOT NULL
"
y <- fread(file.path(in_path, 'groups_countries.csv'))
dd_create_dbtable('groups_countries', 'geography_wd', x, y)
cols <- c('group_code', 'iso3')
y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
write_fst(y, file.path(out_path, 'groups_countries'))

# CURRENCIES --------------------------
x = "
    code char(3) NOT NULL,
    name char(20) NOT NULL,
    symbol char(10) NOT NULL
"
y <- fread(file.path(in_path, 'currencies.csv'))
dd_create_dbtable('currencies', 'geography_wd', x, y)
cols <- c('code')
y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
write_fst(y, file.path(out_path, 'currencies'))

# FACTBOOK ----------------------------
x = "
    var_id char(3) NOT NULL,
    name char(60) NOT NULL,
    domain char(25) NOT NULL
"
dd_create_dbtable('factbook', 'geography_wd', x)

# FACTVALUES --------------------------
x = "
    var_id char(3) NOT NULL,
    iso3 char(3) NOT NULL,
    value DECIMAL(15, 2) NOT NULL,
    updated_at char(25) DEFAULT NULL
"
dd_create_dbtable('factvalues', 'geography_wd', x)

# LANGUAGES ---------------------------
# x = "
#     language_code char(5) NOT NULL,
#     name char(60) NOT NULL,
#     root char(25) NOT NULL
# "
# y <- fread(file.path(in_path, 'languages.csv'))
# dd_create_dbtable('languages', 'geography_wd', x, y)
# cols <- c('code')
# y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
# write_fst(y, file.path(out_path, 'languages'))

# COUNTRIES_LANGUAGES -----------------
# x = "
#     iso3 char(3) NOT NULL,
#     language_code char(5) NOT NULL,
#     is_official CHAR(1) DEFAULT NULL,
#     pct TINYINT(3) DEFAULT NULL
# "
# y <- fread(file.path(in_path, 'countries_languages.csv'))
# dd_create_dbtable('countries_languages', 'geography_wd', x, y)
# cols <- c('iso3', 'language_code')
# y[, (cols) := lapply(.SD, as.factor), .SDcols = cols]
# write_fst(y, file.path(out_path, 'countries_languages'))

# CLEAN & EXIT ------------------------
rm(list = ls())
gc()
