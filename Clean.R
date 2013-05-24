# Clean the WesMaps data and transform it into an adjacency matrix.


dat <- read.csv("Data/Raw.csv", header = FALSE,
                col.names = c("department", "course", "prereqs"),
                stringsAsFactors = FALSE)

dat <- dat[dat$prereqs != "None", ]
dat <- dat[!(dat$department %in% c("NONS", "PHED")), ]

dat$prereqs <- gsub("[[:punct:]]", "", dat$prereqs)
dat$prereqs <- gsub(" AND | OR ", " ", dat$prereqs, ignore.case = TRUE)
dat$prereqs <- gsub("GRSTS", "GRST", dat$prereqs)  # WesMaps typo

# Remove duplicate prerequisites for each course.
dat$prereqs <- lapply(dat$prereqs, strsplit, split = "\\s+")
dat$prereqs <- lapply(dat$prereqs, unlist)
dat$prereqs <- lapply(dat$prereqs, unique)
dat$prereqs <- sapply(dat$prereqs, paste, collapse = " ")

dat$prereqs <- gsub("[[:digit:]]", "", dat$prereqs)

dat <- with(dat, by(prereqs, department, paste, collapse = " "))
dat <- lapply(dat, strsplit, split = "\\s+")
dat <- lapply(dat, unlist)
dat <- lapply(dat, table)

# Convert list of named vectors to a filled matrix.
# Adapted from: http://stackoverflow.com/a/14112736
departments <- sort(unique(unlist(lapply(dat, names))))
mat <- matrix(0, length(dat), length(departments),
              dimnames = list(names(dat), departments))
for(i in seq_along(dat)) mat[names(dat)[i], names(dat[[i]])] <- dat[[i]]

# Add rows and columns of empty vectors for departments with no
# prerequisites in other departments.
departments <- union(colnames(mat), rownames(mat))
dd <- departments[!(departments %in% rownames(mat))]
dd <- matrix(0, length(dd), ncol(mat), dimnames = list(dd, colnames(mat)))
mat <- rbind(mat, dd)
dd <- departments[!(departments %in% colnames(mat))]
dd <- matrix(0, nrow(mat), length(dd), dimnames = list(rownames(mat), dd))
mat <- cbind(mat, dd)

# Drop some extra groups.
dd <- c("CPLS", "GRSTS")
mat <- mat[setdiff(rownames(mat), dd), setdiff(colnames(mat), dd)]

# The order of group arc in the data visualization depends on the order
# of the data set. Rather than order departments alphabetically, we want
# to group them by division. Hence it is necessary to write the list of
# departments:
#
# writeLines(c("department", colnames(mat)), "Data/Departments_Raw.csv")
#
# and then manually label their divisions and sort them. Finally, import
# these sorted data and use them to rearrange the matrix.
departments <- read.csv("Data/Departments.csv", stringsAsFactors = FALSE)
mat <- mat[departments$department, departments$department]

# Hack some JSON output.
output <- apply(mat, 1, function(x) paste0(x, collapse = ","))
output <- lapply(output, function(x) paste0("[", x, "]"))
output <- paste0(output, collapse = ",")
output <- paste0("[", output, "]")
cat(output, file = "Data/Prerequisites.json")


