# This script demonstrates using Groovy and Deeplearning4j (DL4J). The large 
# number of dependencies are acquired by Apache Maven. See "Using Java libraries
# with complex dependencies" in the jsr223 User Manual.
# 
# This script requires 'dl4j.groovy'.

library(jsr223)

# Read the class path created by the Maven command:
# mvn dependency:build-classpath -Dmdep.outputFile="jsr223.classpath"
file.name <- "jsr223.classpath"
class.path <- readChar(file.name, file.info(file.name)$size)

# Supply the class path to create a Groovy script engine.
engine <- ScriptEngine$new("groovy", class.path)

# Set a seed for reproducable results. The seed variable will also be used by
# the Groovy script.
seed <- 10
set.seed(seed)

# Split the iris data set into train and test sets. Note that each data set 
# is scaled. The labels are converted to a binary matrix.
train.idx <- sample(nrow(iris), nrow(iris) * 0.65)
train <- scale(as.matrix(iris[train.idx, 1:4]))
train.labels <- model.matrix(~ -1 + Species, iris[train.idx, ])
test <- scale(as.matrix(iris[-train.idx, 1:4]))
test.labels <- model.matrix(~ -1 + Species, iris[-train.idx, ])

# Execute the Groovy script and display the results. The Groovy script retrieves
# the data and other variables from this R script via callbacks.
result <- engine$source("dl4j.groovy")
cat(result)

engine$terminate()
