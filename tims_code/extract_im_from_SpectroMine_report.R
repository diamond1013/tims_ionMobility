library(readr)

psmReportFile = list.files(pattern = 'PSMReport\\.csv$')[1]

psmReport = read_csv(psmReportFile)

psmReport = local({
  psmReport = psmReport[order(psmReport$PSM.Qvalue), c(
    'PEP.StrippedSequence',
    if ('PEP.ModifiedSequence' %in% colnames(psmReport))
      'PEP.ModifiedSequence'
    else
      NULL,
    'PP.Charge',
    'PSM.IonMobility'
  )]
  psmReport = subset(psmReport, !duplicated(subset(psmReport, select = -PSM.IonMobility)))
})

ionMobility = data.frame(
  sequence = psmReport$PEP.StrippedSequence, 
  modification = if (!('PEP.ModifiedSequence' %in% colnames(psmReport))) NA 
  else sapply(
    gsub('(^_)|(_(.[0-9]+)?$)', '', psmReport$PEP.ModifiedSequence), function(modseq) {
    if (!grepl('\\[.*\\]', modseq)) {
      NA
    }
    else {
      loc = stringr::str_locate_all(modseq, '\\[[^\\[\\]]*\\]')[[1]]
      if (nrow(loc) == 0) {
        NA
      }
      else {
        mods = sapply(1:nrow(loc), function(j) {
          modname = substring(modseq, loc[j, 1] + 1, loc[j, 2] - 1)
          name = sub(' \\([A-Z]+\\)$', '', modname)
          aa = substring(modseq, loc[j, 1] - 1, loc[j, 1] - 1)
          nTermAa = gsub('\\[[A-Za-z0-9\\(\\)_ \\-]*\\]', '', substring(modseq, 1, loc[j, 1] - 1))
          if (grepl('[^A-Z]', nTermAa)) {
            stop(paste0(rowIndexes[1], ': ', modseq))
          }
          if (aa == 'C' && name == 'Carbamidomethyl') {
            return (NA)
          }
          pos = nchar(nTermAa)
          paste0(aa, pos, '(', name, ')')
        })
        mods = mods[!is.na(mods)]
        if (length(mods) == 0) {
          NA
        }
        else {
          paste0(mods, collapse = ';')
        }
      }
    }
  }),
  charge = psmReport$PP.Charge, 
  ionMobility = psmReport$PSM.IonMobility, 
  stringsAsFactors = FALSE
)

ionMobility = subset(ionMobility, is.na(modification))

lapply(2:3, function(ch) {
  write.csv(
    subset(ionMobility, charge == ch),
    paste0(sub('PSMReport\\.csv$', '', psmReportFile), '_charge', ch, '.ionMobility.csv'),
    row.names = FALSE
  )
})
