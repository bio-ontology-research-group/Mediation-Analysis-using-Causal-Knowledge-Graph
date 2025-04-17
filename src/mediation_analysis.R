library("mediation")
library("glmnet")
library("car")
# Read the CSV file into R
args <- commandArgs(trailingOnly=TRUE)
fname <- args[1]
data <- read.csv(fname)
data <- na.omit(data)
data <- data[, apply(data, 2, sd) != 0]

#Get the names of the confounder columns, anything other than the indication, the drug, and the side effect is a confounder
additional_columns <- setdiff(names(data), c("IND","Drug","SE"))

subset_data <- data[, additional_columns]


alpha <- 0.05

response <- "SE"

additional_columns <- names(subset_data)
# Create the full formula dynamically
# Including the interaction term IND * Drug, without repeating Drug
mediator_columns <- additional_columns
treatment_columns <- additional_columns 

treatment_adj <- paste("IND", "~",
                      if (length(treatment_columns) > 0) paste("+", paste(treatment_columns, collapse = " + ")) else "")

mediator_adj <- paste("Drug", "~ IND+",
                      if (length(mediator_columns) > 0) paste("+", paste(mediator_columns, collapse = " + ")) else "")


print("Mediator formula")
print(mediator_adj)
print("Treatment formula")
print(treatment_adj)

mediator_adj <- as.formula(mediator_adj)
treatment_adj <- as.formula(treatment_adj)

# Confounders for treatment model (X)
X <- model.matrix(treatment_adj, data = data)[, -1]

# Confounders for mediator model (X and W combined)
XW <- model.matrix(mediator_adj, data = data)[, -1]

# Treatment variable
A <- data$IND

# Mediator variable
Z <- data$Drug

# Outcome variable
outcome <- data$SE


#Fitting the LASSO to preselect confounders
lasso_treatment <- cv.glmnet(
  x = X,
  y = A,
  family = binomial('logit'),
  alpha = 1,
  nfolds=10,
)

# Extract lambda values and cross-validation metrics
lambdas <- lasso_treatment$lambda          # Lambda values tested
cv_mean <- lasso_treatment$cvm             # Mean cross-validation error for each lambda
cv_sd <- lasso_treatment$cvsd              # Standard deviation of the CV error

# Extract the coefficients for each lambda
coefficients_matrix <- coef(lasso_treatment, s = lambdas)  # Coefficients for all lambdas


best_lambda <- lasso_treatment$lambda.1se

lasso_coefs <- coef(lasso_treatment, s = "lambda.min")

# Convert the sparse matrix to a regular matrix (as the coef object is a sparse matrix)
lasso_coefs_matrix <- as.matrix(lasso_coefs)

# Create a data frame of non-zero coefficients
coef_data <- data.frame(Variable = rownames(lasso_coefs_matrix), Coefficient = lasso_coefs_matrix[, 1])

# Filter to display only non-zero coefficients
non_zero_coef_data <- coef_data[lasso_coefs_matrix[, 1] != 0, ]
#print(non_zero_coef_data)
treatment_predictors <- non_zero_coef_data$Variable[non_zero_coef_data$Variable != "(Intercept)"]
print("Treatment predictors")
print(treatment_predictors)


# Fit LASSO logistic regression for mediator (P(Z | A, X, W))
lasso_mediator <- cv.glmnet(
  x = XW,
  y = Z,
  family = binomial('logit'),
  alpha = 1,  # LASSO regularization
  nfolds = 10,
)

lasso_coefs <- coef(lasso_mediator, s = "lambda.min")

# Convert the sparse matrix to a regular matrix (as the coef object is a sparse matrix)
lasso_coefs_matrix <- as.matrix(lasso_coefs)

# Create a data frame of non-zero coefficients
coef_data <- data.frame(Variable = rownames(lasso_coefs_matrix), Coefficient = lasso_coefs_matrix[, 1])

# Filter to display only non-zero coefficients
non_zero_coef_data <- coef_data[lasso_coefs_matrix[, 1] != 0, ]
mediator_predictors <- non_zero_coef_data$Variable[non_zero_coef_data$Variable != "(Intercept)"]
#print(non_zero_coef_data)
print("Mediator covariates")
print(mediator_predictors)

joint <- unique_predictors <- union(mediator_predictors, treatment_predictors)

#print("joint predictors")
#print(joint)


mediator_model <- paste("Drug", "~ IND",
                      if (length(joint) > 0) paste("+", paste(joint, collapse = " + ")) else "")

noint_outcome_model <- paste("SE", "~ IND+Drug",
                      if (length(joint) > 0) paste("+", paste(joint, collapse = " + ")) else "")
int_outcome_model <- paste("SE", "~ IND*Drug",
                      if (length(joint) > 0) paste("+", paste(joint, collapse = " + ")) else "")

print("Mediator model formula")
print(mediator_model)
print("Outcome model formula")
print(int_outcome_model)

mediator_model <- as.formula(mediator_model)
noint_outcome_model <- as.formula(noint_outcome_model)
int_outcome_model <- as.formula(int_outcome_model)

#fitting the mediator model
mediator.model <- glm( mediator_model, data=data,
            family=binomial(link="logit"))
summary_model <- summary(mediator.model)

#fitting the outcome model
outcome.model <- glm( int_outcome_model, data=data,
            family=binomial(link="logit"))
summary_model <- summary(outcome.model)

# Check if the interaction term "IND:Drug" is in the model and if it's significant
if ("IND:Drug" %in% rownames(summary_model$coefficients)) {
  p_value_interaction <- summary_model$coefficients["IND:Drug", "Pr(>|z|)"]

  if (p_value_interaction > alpha) {
    # Interaction term is not significant, so we fit the model without interaction
    d.bin <- glm(noint_outcome_model,
                 data = data, family = binomial(link = "logit"))
    print("Interaction term is not significant. Running model without interaction.")
    summary_model <- summary(d.bin)
  } else {
    print("Interaction term is significant. Proceeding with the model including interaction.")
  }
} else {
	d.bin <- glm(noint_outcome_model,
                 data = data, family = binomial(link = "logit"))
    	print("Interaction term is not significant. Running model without interaction.")
}

med_results <- mediate(mediator.model, outcome.model, sims=1000, treat="IND", mediator="Drug" ,robustSE=TRUE)#, boot=TRUE)
print(summary_model)
summary(med_results)
