# Figure_1.R
# Figure 1: Government formation with two issue dimensions.
# A conceptual illustration (no data): hypothetical ideal points of three
# parties A, B and C on economic (L-R) and "social" (Con-Lib) policy.
# Output: output/Figure_1.pdf

dir.create("output", showWarnings = FALSE)

pdf(file.path("output", "Figure_1.pdf"), width = 6, height = 6)
par(mar = rep(0.5, 4), family = "sans")
plot(NA, xlim = c(-1, 1), ylim = c(-1, 1), axes = FALSE, xlab = "", ylab = "", asp = 1)
box(lty = "dashed")
segments(-0.93, 0, 0.96, 0, lwd = 1.5)          # economic policy
segments(0, -0.94, 0, 0.93, lwd = 1.5)          # social policy
text(-0.92, -0.05, "L", adj = c(0, 1))
text(0.94, -0.05, "R", adj = c(1, 1))
text(0.04, -0.05, "Economic policy", adj = c(0, 1))
text(-0.05, 0.92, "Lib", srt = 90, adj = c(1, 0.5))
text(-0.05, -0.94, "Con", srt = 90, adj = c(0, 0.5))
text(-0.05, 0.05, "\"Social\" policy", srt = 90, adj = c(0, 0.5))
points(c(-0.21, 0.54, 0.54), c(-0.61, 0.69, -0.62), pch = 1, lwd = 3, cex = 0.9)
text(-0.25, -0.65, "A", adj = c(1, 1))
text(0.57, 0.72, "B", adj = c(0, 0))
text(0.57, -0.65, "C", adj = c(0, 1))
dev.off()
