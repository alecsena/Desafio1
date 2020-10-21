library(dplyr)
library(tidyverse)
library(jsonlite)
library(readr)
library(lubridate)
library(data.table)
library(tidyfast)
library(factoextra)
library(NbClust)
options(scipen=999)

setwd("base_datajud/")

sgt_movimentos <- read_delim("sgt_movimentos.csv", 
                             ";", escape_double = FALSE, col_types = cols(cod_filhos = col_character()), 
                             trim_ws = TRUE)

sgt_assuntos <- read_delim("sgt_assuntos.csv", 
                           ";", escape_double = FALSE, col_types = cols(cod_filhos = col_character()), 
                           trim_ws = TRUE)

sgt_classes <- read_delim("sgt_classes.csv", 
                          ";", escape_double = FALSE, col_types = cols(cod_filhos = col_character()), 
                          trim_ws = TRUE)

mpm_serventias <- read_delim("mpm_serventias.csv", 
                             ";", escape_double = FALSE, trim_ws = TRUE, col_types = cols(SEQ_ORGAO = col_character()))
diretorios<-list.dirs(".")
lapply(diretorios, list.files, full.names =T)
jf<-list.files("justica_federal/processos-trf1/", full.names = T)

trf1_1 <- data.frame()
trf_movimentos <- data.frame()

for(i in jf){
  
  temp_trf <- fromJSON(i, flatten = TRUE)
  trf1_1 <- bind_rows(temp_trf, trf1_1)
  movimentos_temp <- temp_trf %>% select(dadosBasicos.numero, movimento)%>%
    unnest()
  trf_movimentos <- bind_rows(movimentos_temp, trf_movimentos)
  cat("Ok \n")
}

#save(trf_movimentos, file = "movimentos_trf.rda") 
load("movimentos_trf.rda")

trf1_1<- trf1_1%>%
  left_join(select(sgt_classes, codigo, descricao), by = c("dadosBasicos.classeProcessual"="codigo"))%>%
  mutate(descricao_classe = descricao)%>%
  left_join(select(mpm_serventias, SEQ_ORGAO, DSC_TIP_ORGAO), by = c("dadosBasicos.orgaoJulgador.codigoOrgao" = "SEQ_ORGAO"))

trf_assuntos<- trf1_1 %>% select(dadosBasicos.numero, dadosBasicos.assunto, dadosBasicos.classeProcessual, descricao_classe, dadosBasicos.orgaoJulgador.codigoOrgao,dadosBasicos.orgaoJulgador.nomeOrgao,DSC_TIP_ORGAO)%>%
  unnest(dadosBasicos.assunto)%>%
  mutate(cod_assunto = ifelse(is.na(assuntoLocal.codigoPaiNacional),codigoNacional,assuntoLocal.codigoPaiNacional ))%>%
  left_join(select(sgt_assuntos, codigo, descricao), by = c("cod_assunto"="codigo"))%>%
  select(-assuntoLocal.codigoAssunto, -assuntoLocal.codigoPaiNacional, -codigoNacional)%>%
  mutate(descricao_assunto = descricao)%>%
  select(-descricao)
  




  


trf_movimentos<-trf_movimentos%>%
  mutate(cod_mov = ifelse(is.na(movimentoLocal.codigoPaiNacional),movimentoNacional.codigoNacional,movimentoLocal.codigoPaiNacional ))%>%
  left_join(select(sgt_movimentos, codigo, descricao), by = c("cod_mov"="codigo"))%>%
  select(-movimentoLocal.codigoMovimento,-movimentoLocal.codigoPaiNacional,-movimentoNacional.codigoNacional)





trf_movimentos$dataHora <- ymd_hms(trf_movimentos$dataHora,tz = "America/Sao_Paulo")

movimentos_processo <- trf_movimentos%>%
  group_by(dadosBasicos.numero)%>%
  count()%>%
  inner_join(trf_movimentos)%>%
  mutate(mov_unico = ifelse(n==1,"S","N"))

movimentos_processo<- movimentos_processo%>%
  bind_rows(movimentos_processo%>%
              filter(mov_unico == "S")%>%
              mutate(dataHora = now(), cod_mov = cod_mov, descricao = descricao))




tempo_processo <- movimentos_processo%>%
  group_by(dadosBasicos.numero)%>%
  arrange(dataHora)%>%
  mutate(movimentos = paste(descricao, collapse = " -> "))%>%
  filter(row_number()==1 | row_number()==n())%>%
  group_by(dadosBasicos.numero)%>%
  mutate(data_tipo = ifelse(row_number()==1, "inicio", "fim"))%>%
  group_by(dadosBasicos.numero)%>%
  mutate(descricao_mov = paste(descricao, collapse = "_"), cod_mov = paste(cod_mov, collapse = "_"))%>%
  select(-descricao)%>%
  group_by(dadosBasicos.numero)%>%
  spread(data_tipo, dataHora)


tempo_processo$tempo <- interval(tempo_processo$inicio, tempo_processo$fim)%>%
  as.period()



assuntos_classe<- trf_assuntos%>%
  group_by(dadosBasicos.numero)%>%
  arrange(cod_assunto)%>%
  mutate(principal = ifelse(principal == "TRUE", paste(cod_assunto, descricao_assunto, sep = "_"), NA))%>%
  mutate(sem_principal = ifelse(is.na(principal), "sim", "nao"))%>%
  mutate(sem_principal = paste(sem_principal, collapse = " "))%>%
  mutate(principal = ifelse(grepl("nao", sem_principal),principal, "sem_principal" ))%>%
  select(-sem_principal)%>%
  mutate(cod_assunto = paste(cod_assunto, collapse = "_"),
        descricao_assunto = paste(descricao_assunto, collapse = "_"))%>%
  na.omit(principal)%>%
  unique()%>%
  mutate(cod_assunto_classe = paste(cod_assunto, dadosBasicos.classeProcessual))
    
    
    
classe_assunto_tempo<-tempo_processo%>%
left_join(assuntos_classe)


ocorrencia_assunto_classe_tempo <- classe_assunto_tempo%>%
  group_by(cod_assunto_classe, descricao_classe, descricao_assunto,DSC_TIP_ORGAO)#%>%
ocorrencia_assunto_classe_tempo$tempo <-time_length(ocorrencia_assunto_classe_tempo$tempo, unit = "year")
ocorrencia_assunto_classe_tempo<- ocorrencia_assunto_classe_tempo%>%
  filter(cod_mov != "85_85")%>%
  summarise(media_tempo = round(mean(tempo), digits = 3),
            desvio_tempo = round(sd(tempo), digits = 3),
            q1_tempo = round(quantile(tempo, prob = .25), digits = 3),
            mediana_tempo = round(median(tempo), digits = 3),
            q3_tempo = round(quantile(tempo, prob = .75), digits = 3),
            min_tempo = round(min(tempo), digits = 3),
            max_tempo = round(max(tempo), digits = 3),
            media_movimento = round(mean(n), digits = 3),
            desvio_movimento= round(sd(n), digits = 3),
            q1_movimento = round(quantile(n, prob = .25), digits = 3),
            mediana_movimento = round(median(n), digits = 3),
            q3_movimento = round(quantile(n, prob = .75), digits = 3),
            min_movimento = round(min(n), digits = 3), 
            max_movimento = round(max(n), digits = 3))


ocorrencia_assunto_classe <- classe_assunto_tempo%>%
  group_by(cod_assunto_classe, descricao_classe, descricao_assunto,DSC_TIP_ORGAO)%>%
  filter(cod_mov != "85_85")%>%
  summarise(ocorrencia= n())%>%
  ungroup()%>%
  mutate(percentual = paste(as.character(round(ocorrencia/sum(ocorrencia)*100, digits = 3)), "%"))


tempo_entre_movimento <- movimentos_processo %>%
  filter(mov_unico == "N")%>%
  group_by(dadosBasicos.numero)%>%
  arrange(dataHora)%>%
  mutate(mov_inicio = dataHora, mov_fim = lead(dataHora))%>%
  select(-dataHora)%>%
  left_join(select(classe_assunto_tempo,
                   dadosBasicos.numero,
                   dadosBasicos.classeProcessual,
                   descricao_classe,
                   cod_assunto,
                   descricao_assunto,
                   cod_assunto_classe))

tempo_entre_movimento$tempo_anos <- interval(tempo_entre_movimento$mov_inicio, tempo_entre_movimento$mov_fim)%>%
  as.period()
tempo_entre_movimento$tempo <- time_length(tempo_entre_movimento$tempo_anos, unit = "days")

tempo_entre_movimento<-tempo_entre_movimento%>%
  select(-tempo_anos, n)%>%
  filter(!is.na(descricao))%>%
  filter(!is.na(tempo))%>%
  group_by(cod_mov,descricao,cod_assunto_classe,dadosBasicos.classeProcessual,descricao_classe,cod_assunto,descricao_assunto )%>%
  summarise(media_tempo = round(mean(tempo), digits = 3),
          desvio_tempo = round(sd(tempo), digits = 3),
          q1_tempo = round(quantile(tempo, prob = .25), digits = 3),
          mediana_tempo = round(median(tempo), digits = 3),
          q3_tempo = round(quantile(tempo, prob = .75), digits = 3),
          min_tempo = round(min(tempo), digits = 3),
          max_tempo = round(max(tempo), digits = 3),
          ocorrencia=n()
          )%>%
  ungroup()%>%
  mutate(percentual = paste(as.character(round(ocorrencia/sum(ocorrencia)*100, digits = 3)), "%"))



#openxlsx::write.xlsx(ocorrencia_assunto_classe,"percentual_assunto_classe.xlsx")
#openxlsx::write.xlsx(ocorrencia_assunto_classe_tempo,"tempo_movimento_assunto_classe.xlsx")
#openxlsx::write.xlsx(tempo_processo,"tempo_processo.xlsx")

#openxlsx::write.xlsx(tempo_entre_movimento,"tempo_entre_movimento.xlsx")

tmp_mov<-tempo_entre_movimento%>%
  select(cod_mov, cod_assunto_classe, mediana_tempo)%>%
  mutate(cod_mov_assunto_classe = paste(cod_mov, cod_assunto_classe, collapse = "-" ))%>%
  select(cod_mov_assunto_classe, mediana_tempo)



