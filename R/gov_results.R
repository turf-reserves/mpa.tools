#' Governance Results
#'
#' @description Analyzes all the required governance indicators at once
#'
#' @param data The data to be analyzed
#' @param reserva The name of the reserve
#' @param values A list, created within the Shiny app, that contains the list of indicators selected and the community
#'
#' @return results, a tibble containing the name of the indicator as well as DiD estimates, p values, a string to be used as input for valueBox, the color of the valueBox, and the lm object fit to the indicator extracted from the data
#' @export
#'

gov_results <- function(values, data, reserva){
  library(tidyverse)

  gov <- data %>%
    filter(Community == values$comunidad, Q2_Name %in% c(reserva, NA))

  results <- tibble(Ind = c("Acceso a la pesqueria",
                            "Numero de pescadores",
                            "Reconocimiento legal",
                            "Grado de pesca ilegal",
                            "Plan de manejo",
                            "Procuracion",
                            "Tamano de la reserva",
                            "Organizacion pesquera",
                            "Reglamentacion interna",
                            "Efectividad percibida"),
                    e = NA,
                    color = "yellow",
                    string = "No disponible",
                    plot = list(NA))

  ####
  if ("Acceso a la pesqueria" %in% values$indG) {
    results$e[1] <- ifelse(any(gov$Q7 == "Open Access", na.rm = T), 0, 1)
    results$color[1] <- ifelse(any(gov$Q7 == "Open Access", na.rm = T), "red", "olive")
    results$string[1] <- ifelse(any(gov$Q7 == "Open Access", na.rm = T), "La pesqueria no tiene restricciones. Esto puede causar efectos negativos a largo plazo.", "Bien!")
  }

  if ("Numero de pescadores" %in% values$indG) {
    results$e[2] <- ifelse(mean(gov$Q10Aft - gov$Q10Bef, na.rm = T) > 0, 0, 1)
    results$color[2] <- ifelse(mean(gov$Q10Aft - gov$Q10Bef, na.rm = T) > 0, "red", "olive")
    results$string[2] <- ifelse(mean(gov$Q10Aft - gov$Q10Bef, na.rm = T) > 0, "Si el esfuerzo pesquero incrementa, la abundancia de tus productos puede reducir.", "Bien!")
  }

  if ("Reconocimiento legal de la reserva" %in% values$indG) {
    results$e[3] <- ifelse(any(gov$Q5 == "No", na.rm = T), 0, 1)
    results$color[3] <- ifelse(any(gov$Q5 == "No", na.rm = T), "red", "olive")
    results$string[3] <- ifelse(any(gov$Q5 == "No", na.rm = T), "Reconocer su reserva legalmente es importante para fortalecer su procuracion.", "Bien!")
  }

  if ("Grado de pesca ilegal" %in% values$indG) {
    levels <- data.frame(levels = c("Very High", "High", "Moderate", "Restricted", "Low", "Null"),
                         values = c(5, 4, 3, 2, 1, 0), stringsAsFactors = F)
    change <- gov %>%
      select(Interviewee, contains("Q19")) %>%
      gather(question, levels, -Interviewee) %>%
      left_join(levels, by = "levels") %>%
      select(-levels) %>%
      spread(question, values) %>%
      mutate(change = Q19Aft - Q19Bef) %>%
      {.$change} %>%
      mean(na.rm = T)

    results$e[4] <- ifelse(change >= 0, 0, 1)
    results$color[4] <- ifelse(change >= 0, "red", "olive")
    results$string[4] <- ifelse(change >= 0, "La pesca ilegal suele disminuir las abundancias y biomasas de tus recursos.", "Bien!")
  }

  if ("Plan de manejo" %in% values$indG) {

    answer <- gov %>%
      filter(!is.na(Q6)) %>%
      group_by(Q6) %>%
      count() %>%
      filter(n == max(n), !is.na(Q6)) %>%
      {.$Q6}

    results$e[5] <- ifelse(answer == "No", 0, 1)
    results$color[5] <- ifelse(answer == "No", "red", "olive")
    results$string[5] <- ifelse(answer == "No", "Puede que los usuarios no esten al tanto de las reglas. Es mejor tener las reglas por escrito.", "Puede que los usuarios conozcan las reglas y por lo tanto las obedezcan.")
  }

  if ("Procuracion de la reserva" %in% values$indG) {

    answer <- gov %>%
      filter(!is.na(Q15)) %>%
      group_by(Q15) %>%
      count() %>%
      filter(n == max(n), !is.na(Q15)) %>%
      {.$Q15}

    results$e[6] <- ifelse(answer == "Increased", 1, 0)
    results$color[6] <- ifelse(answer == "Increased", "olive", "red")
    results$string[6] <- ifelse(answer == "Increased", "Bien!", "Puede que incrementar la vigilancia de las reservas ayude a que sean mas efectivas.")
  }

  if ("Tamano de la reserva" %in% values$indG) {

    size <- reserve_size(data = values$fish_data, spp = values$objsp, width = values$res.width, length = values$res.length)

    results$e[7] <- size$e
    results$color[7] <- size$color
    results$string[7] <- size$string
    results$plot[[7]] <- size$plot
  }

  if ("Organizacion pesquera" %in% values$indG) {
    answer <- unique(gov$Q1)

    results$e[8] <- ifelse(any(answer %in% c("Cooperative", "Union", "Association", "Federation")), 1, 0)
    results$color[8] <- ifelse(any(answer %in% c("Cooperative", "Union", "Association", "Federation")), "olive", "red")
    results$string[8] <- ifelse(any(answer %in% c("Cooperative", "Union", "Association", "Federation")), "Bien!", "La presencia de organizaciones promueve la comunicacion.")
  }

  if ("Reglamentacion interna" %in% values$indG) {

    answer <- gov %>%
      filter(!is.na(Q9)) %>%
      group_by(Q9) %>%
      count() %>%
      filter(n == max(n), !is.na(Q9)) %>%
      {.$Q9}

    results$e[9] <- ifelse(answer == "No", 0, 1)
    results$color[9] <- ifelse(answer == "No", "red", "olive")
    results$string[9] <- ifelse(answer == "No", "Las regulaciones formales por lo general no son suficiente. Considera implementar reglas internas.", "Bien!")
  }

  if ("Efectividad percibida" %in% values$indG) {

    answer <- gov %>%
      filter(!is.na(Q23)) %>%
      group_by(Q23) %>%
      count() %>%
      filter(n == max(n), !is.na(Q23)) %>%
      {.$Q23}

    results$e[10] <- ifelse(answer == "No", 0, 1)
    results$color[10] <- ifelse(answer == "No", "red", "olive")
    results$string[10] <- ifelse(answer == "No", "Si los usuarios no creen que la reserva funciona, es importante escuchar su opinion para encontrar posibles areas de mejora.", "Bien! Mientras la percepcion y la realidad sean similares.")
  }

  return(results)
}
