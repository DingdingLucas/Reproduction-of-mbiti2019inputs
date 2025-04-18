# Load required packages
library(data.table)
library(haven)
library(psych)
library(fixest)
library(stargazer)
library(car)

# Set directories
data_dir <- "data/"
output_dir <- "output/"

# Load data
dt <- as.data.table(read_dta(file.path(data_dir, "Student_School_House_Teacher_Char.dta")))

# PCA
pca_result <- principal(dt[, .(Z_kiswahili_T8, Z_kiingereza_T8, Z_hisabati_T8)], nfactors = 1, rotate = "none")
dt[, Z_ScoreFocal_T8 := as.vector(scale(.SD) %*% pca_result$loadings), .SDcols = c("Z_kiswahili_T8", "Z_kiingereza_T8", "Z_hisabati_T8")]

# Group standardization
for (val in 1:4) {
  idx <- dt$GradeID_T7 == val & dt$treatarm == 4
  m <- mean(dt[idx, Z_ScoreFocal_T8], na.rm = TRUE)
  s <- sd(dt[idx, Z_ScoreFocal_T8], na.rm = TRUE)
  dt[idx, Z_ScoreFocal_T8 := (Z_ScoreFocal_T8 - m) / s]
}

# Define variable groups
AggregateDep_Karthik <- c("Z_hisabati", "Z_kiswahili", "Z_kiingereza", "Z_ScoreFocal")
treatmentlist <- c("TreatmentCG", "TreatmentCOD", "TreatmentBoth")
treatmentlist_int <- c("TreatmentCOD", "TreatmentBoth")
schoolcontrol <- c("PTR_T1", "SingleShift_T1", "IndexDistancia_T1", "InfrastructureIndex_T1", "IndexFacilities_T1", "s108_T1")
studentcontrol <- c("LagseenUwezoTests", "LagpreSchoolYN", "Lagmale", "LagAge", "LagGrade")
HHcontrol <- c("HHSize", "IndexPoverty", "IndexEngagement", "LagExpenditure")

# Low-stakes regressions (T3 and T7)
models_low <- list()
labels_low <- c()

for (time in c("T3", "T7")) {
  for (var in AggregateDep_Karthik) {
    depvar <- paste0(var, "_", time)
    fml <- as.formula(paste0(
      depvar, " ~ ",
      paste(c(treatmentlist, studentcontrol, schoolcontrol, HHcontrol, "factor(DistID)"), collapse = " + ")
    ))
    model <- feols(fml, data = dt, cluster = ~SchoolID)
    models_low[[paste0(var, "_", time)]] <- model
    labels_low <- c(labels_low, paste0(var, "_", time))
  }
}

# Export low-stakes results
stargazer(models_low,
          type = "latex",
          out = file.path(output_dir, "Reg_LowStakes.tex"),
          title = "Low-Stakes Test Score Regressions",
          column.labels = labels_low,
          header = FALSE,
          omit.stat = c("f", "adj.rsq"),
          float = TRUE,
          table.placement = "ht",
          no.space = TRUE,
          star.cutoffs = c(0.1, 0.05, 0.01))

# High-stakes regressions (T4 and T8)
models_high <- list()
labels_high <- c()

for (time in c("T4", "T8")) {
  for (var in AggregateDep_Karthik) {
    depvar <- paste0(var, "_", time)
    controls <- if (time == "T8") treatmentlist_int else NULL
    fml <- as.formula(paste0(
      depvar, " ~ ",
      paste(c(controls, schoolcontrol, paste0("factor(GradeID_", time, ")"), "factor(DistID)"), collapse = " + ")
    ))
    model <- feols(fml, data = dt, cluster = ~SchoolID)
    models_high[[paste0(var, "_", time)]] <- model
    labels_high <- c(labels_high, paste0(var, "_", time))
  }
}

# Export high-stakes results
stargazer(models_high,
          type = "latex",
          out = file.path(output_dir, "Reg_HighStakes.tex"),
          title = "High-Stakes Test Score Regressions",
          column.labels = labels_high,
          header = FALSE,
          omit.stat = c("f", "adj.rsq"),
          float = TRUE,
          table.placement = "ht",
          no.space = TRUE,
          star.cutoffs = c(0.1, 0.05, 0.01))

# Diff-in-diff residual regression (T3 vs T4 and T7 vs T8)
models_diff <- list()
labels_diff <- c()

diff_blocks <- list(
  list(pre = "T3", post = "T4"),
  list(pre = "T7", post = "T8")
)

for (block in diff_blocks) {
  for (var in AggregateDep_Karthik) {
    var_pre <- paste0(var, "_", block$pre)
    var_post <- paste0(var, "_", block$post)
    
    # Residualize pre
    model_pre <- feols(as.formula(paste0(var_pre, " ~ ", paste(c(schoolcontrol, studentcontrol, HHcontrol, "factor(DistID)"), collapse = " + "))), data = dt)
    dt[, paste0("resid_", block$pre) := resid(model_pre)]
    dt[, time := 0]
    dt[, resid := get(paste0("resid_", block$pre))]
    dt[, sample := "pre"]
    df_pre <- dt[!is.na(resid), .(resid, time, TreatmentCG, TreatmentCOD, TreatmentBoth, SchoolID)]
    
    # Residualize post
    model_post <- feols(as.formula(paste0(var_post, " ~ ", paste(c(schoolcontrol, "factor(DistID)", paste0("factor(GradeID_", block$post, ")")), collapse = " + "))), data = dt)
    dt[, paste0("resid_", block$post) := resid(model_post)]
    dt[, time := 1]
    dt[, resid := get(paste0("resid_", block$post))]
    dt[, sample := "post"]
    df_post <- dt[!is.na(resid), .(resid, time, TreatmentCG, TreatmentCOD, TreatmentBoth, SchoolID)]
    
    # Combine
    df_combined <- rbind(df_pre, df_post, fill = TRUE)
    df_combined[is.na(TreatmentCG), TreatmentCG := 0]
    
    # Diff regression with interactions
    fml_diff <- resid ~ TreatmentCG * time + TreatmentCOD * time + TreatmentBoth * time
    model_diff <- feols(fml_diff, data = df_combined, cluster = ~SchoolID)
    models_diff[[paste0(var, "_", block$pre, "_", block$post)]] <- model_diff
    labels_diff <- c(labels_diff, paste0(var, " (", block$pre, " vs ", block$post, ")"))
  }
}

# Export diff results
stargazer(models_diff,
          type = "latex",
          out = file.path(output_dir, "Reg_DiffTest.tex"),
          title = "Difference-in-Difference Residual Regressions",
          column.labels = labels_diff,
          header = FALSE,
          omit.stat = c("f", "adj.rsq"),
          float = TRUE,
          table.placement = "ht",
          no.space = TRUE,
          star.cutoffs = c(0.1, 0.05, 0.01))
