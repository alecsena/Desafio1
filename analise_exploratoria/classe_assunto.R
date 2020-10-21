library(dplyr)
library(tidyverse)
library(jsonlite)
library(readr)
library(lubridate)
library(data.table)

setwd("hackathon/base/")
sgt_assuntos <- read_delim("sgt_assuntos.csv", 
                           ";", escape_double = FALSE, col_types = cols(cod_filhos = col_character()), 
                           trim_ws = TRUE)

sgt_classes <- read_delim("sgt_classes.csv", 
                          ";", escape_double = FALSE, col_types = cols(cod_filhos = col_character(), codigo = col_character()), 
                          trim_ws = TRUE)

mpm_serventias <- read_delim("mpm_serventias.csv", 
                             ";", escape_double = FALSE, trim_ws = TRUE, col_types = cols(SEQ_ORGAO = col_character()))

trf1_1 <- data.frame()
jf<-list.files("justica_federal", full.names = T)
for (tr in jf ){
  trf<-list.files(tr, full.names = T)
  for(i in trf){
    temp_trf <- fromJSON(i, flatten = TRUE)%>%
      mutate_if(is.numeric,funs(as.character(.)))
    trf1_1 <- bind_rows(temp_trf, trf1_1)
    cat("Ok \n")
  }
  
}




trf1_1<- trf1_1%>%
  left_join(select(sgt_classes, codigo, descricao), by = c("dadosBasicos.classeProcessual"="codigo"))%>%
  mutate(descricao_classe = descricao)%>%
  left_join(select(mpm_serventias, SEQ_ORGAO, DSC_TIP_ORGAO), by = c("dadosBasicos.orgaoJulgador.codigoOrgao" = "SEQ_ORGAO"))

trf1_1<-group_by(trf1_1, siglaTribunal)

trfs<-group_split(trf1_1)

gera_df<- function(trf, sgt_assuntos){
  trf_assuntos<- trf %>% select(dadosBasicos.numero, dadosBasicos.assunto,
                                dadosBasicos.classeProcessual,
                                descricao_classe, dadosBasicos.orgaoJulgador.codigoOrgao,
                                dadosBasicos.orgaoJulgador.nomeOrgao,DSC_TIP_ORGAO)%>%
    unnest(dadosBasicos.assunto)
}


dfs_trf_list<-lapply(trfs, gera_df, sgt_assuntos)

df_trf<- do.call(bind_rows, dfs_trf_list)

trf_assuntos<- df_trf%>% 
  mutate(cod_assunto = ifelse(is.na(assuntoLocal.codigoPaiNacional),codigoNacional,assuntoLocal.codigoPaiNacional ))%>%
  select(-descricao)%>%
  left_join(select(sgt_assuntos, codigo, descricao), by = c("cod_assunto"="codigo"))%>%
  mutate(descricao_assunto = descricao)%>%
  select(-descricao)%>%
  select(-assuntoLocal.codigoAssunto, -assuntoLocal.codigoPaiNacional, -codigoNacional)
  

assuntos_classe<- trf_assuntos%>%
  group_by(dadosBasicos.numero)%>%
  mutate(cod_assunto_classe = paste(cod_assunto, dadosBasicos.classeProcessual))


assuntos_classe_percentual<- assuntos_classe%>%
  group_by(cod_assunto_classe, descricao_classe, descricao_assunto,DSC_TIP_ORGAO)%>%
  #filter(cod_mov != "85_85")%>%
  summarise(ocorrencia= n())%>%
  ungroup()%>%
  mutate(percentual = paste(as.character(round(ocorrencia/sum(ocorrencia)*100, digits = 3)), "%"))


save(trf1_1,df_trf,trf_assuntos, assuntos_classe, assuntos_classe_percentual, file="trf_todos.rda")
