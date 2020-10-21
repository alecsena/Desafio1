require(DBI)
require(dplyr)
require(dendextend)
require(cluster)
require(factoextra)
args <- commandArgs(trailingOnly = T)

#para rodar via Rscript como argumentos.
#orgao_julgador <- args[1]
#diretorio_de_saida<-args[2]

#para rodar via Rstudio

orgao_julgador <- "16031"
diretorio_de_saida <- getwd()

db <- 'db_cnj'  #provide the name of your db

host_db <- '157.230.184.48' #i.e. # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'  

db_port <- '5432'  # or any other port specified by the DBA

db_user <- 'postgres'  

db_password <- '123456'

con <- dbConnect(RPostgres::Postgres(), dbname = db, host=host_db, port=db_port, user=db_user, password=db_password)  


tribunal_movimentos <- dbGetQuery(con, sprintf("SELECT p.numeroprocesso, m.* FROM public.processos p inner join public.movimentos m  on p.numeroprocesso = m.numeroprocesso and p.orgaojulgadorcodigoorgao = '%s'", orgao_julgador))







df_movimentos_processos <- tribunal_movimentos%>%
  group_by(numeroprocesso)%>%
  mutate(movimentonacionalcodigonacional = ifelse(is.na(movimentolocalcodigopainacional),movimentonacionalcodigonacional,movimentolocalcodigopainacional ))%>%
  mutate(mov_dif = length(unique(movimentonacionalcodigonacional)))%>%
  select(-qtd_movimentonacional,-qtd_movimentolocal,-orgaojulgadorinstancia,
         -movimentolocalcodigomovimento,-movimentoseq,-nivelsigilo,-codigocomplementonacional,descricaocomplementonacional)



df_movimentos <- df_movimentos_processos %>% 
  group_by(numeroprocesso)%>%
  summarise(qtd_mov = sum(qtd_movimento), qtd_dia = sum(qtd_dias), mov_dif = mov_dif) %>% 
  unique()

df <- df_movimentos %>% ungroup()
df_mov <- df[,-1]
row.names(df_mov) <- df$numeroprocesso




set.seed(123)
gap_stat <- clusGap(df_mov, FUN = kmeans, nstart = 1,
                    K.max = 20, B = 100, )
fviz_gap_stat(gap_stat)

k<-maxSE(f = gap_stat$Tab[, "gap"], SE.f = gap_stat$Tab[, "SE.sim"])



#k-means
x <- kmeans(df_mov, k, iter.max = 10, nstart = 1)

clusters<-table(x$cluster)%>%
  as.data.frame()
names(clusters)<- c("Name", "Count")
jsonlite::toJSON(list(children= clusters), pretty = T)%>%
  write(file = paste0(diretorio_de_saida, "/","cluster.json"))

medias<-aggregate(df_mov, by=list(cluster=x$cluster), mean)%>%
  round(digits = 2)

jsonlite::toJSON(list(medias=medias), pretty = T)%>%
  write(file = paste0(diretorio_de_saida, "/","cluster_medias.json"))
