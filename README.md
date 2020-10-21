

# Desafio 1

## Equipe 
Bruno Ferreira, Bruno Justino, Micael Felipe, Michael Donath, Ricardo Sampaio, Wellington Carlos.

## Link da Solução 
https://hackathon.plurata.com.br/assets/pages/desafio1.html

## Requisitos para utilização do código

 - Rstudio: 1.2.5042
 - R version 4.0.0 (2020-04-24)

## Como executar o código
O código pode ser utilizado através da interface do Rstudio ou via RScript.


## Licença 
Os códigos foram gerados com linguagem de programação open source (R), e a ferramenta para os dashboards também é gratuita (Data studio).



Olá, nós somos a Equipe Plurata, o Team 5 no Shawee.

  

Na tentativa de solucionar o desafio “Tempo e Produtividade”, nossa equipe compreendeu que a movimentação dos processos seria a característica-chave a ser trabalhada, embora existam, segundo nossos especialistas, particularidades e diferenças relevantes entre as comarcas, varas, tribunais e as diversas áreas do direito.

  

Assim, diante dessa realidade, das necessidades jurídicas apontadas nos relatos e dos dados disponibilizados, a equipe Plurata idealizou e desenvolveu, então, uma solução denominada "Eficiência do Judiciário", onde os tipos, quantidade e tempo de movimentações dos e entre os processos são avaliados e comparações entre as diferentes entidades podem ser estabelecidas. O CNJ e os diversos tribunais do país são potenciais usuários desta solução.

  

Ela nada mais é do que um aplicativo via web e pode ser acessado através do endereço hackathon.plurata.com.br. O aplicativo contém 3 dashboards, implementados na ferramenta _open source_ Data Studio: “Tempo e Produtividade”, “Clusterização” e o “Gestão”. No dashboard “Tempo e Produtividade”, o juiz e o CNJ podem monitorar a taxa de morosidade e o % de movimentações repetidas de determinada vara, comparar a produtividade de uma mesma vara em diferentes tribunais do país e, ainda, mensurar a despesa de cada tribunal gerada por movimentações repetidas em demasia. No dashboard “Clusterização”, é possível agrupar as varas em _clusters_ baseados em dados de tempo do processo e quantidade de movimentações. Já no dashboard “Gestão”, indicadores genéricos são apresentados em relação ao tipo de Justiça e Unidade Federativa.

 
  

No que diz respeito à arquitetura, a figura esquemática demonstra as diferentes soluções utilizadas.

  

Do ponto de vista tecnológico, nossa solução é composta de:

-   Uma aplicação web escrita nas linguagens HTML 5 + Javascript;
    
-   Um modelo de clusterização escrito na linguagem R;
    
-   Um banco de dados Postgres;
    
-   Uma API REST (Representational State Transfer) para interoperabilidade de recursos entre os componentes distribuídos;
    
-   Um dashboard desenvolvido na ferramenta Data Studio.
    

  
![Imgur](https://i.imgur.com/3u2pXx6.jpg)

  

Visto que adotamos diferentes tecnologias e padrões baseados na Internet e na necessidade de armazenamento, processamento e integração de grandes volumes de dados, optamos pela adoção de um estilo de arquitetura de software distribuído. Como pode ser visto, temos diversos sistemas funcionando paralelamente que se comunicam através de um servidor de notificações instantâneas e uma API REST para interoperar recursos informacionais.

  

![Imgur](https://i.imgur.com/rD7MaE4.png)

  

O modelo de dados usado para a organização e armazenamento dos dados disponibilizados pelo CNJ foi o modelo dimensional. Nesse contexto, existem 3 tabelas principais: tabela de processos, de movimentos e de assuntos. Além delas, tem-se as dimensões: tribunal, vara, tempo, classe processual, localidade, entre outras. Por fim, tem-se as métricas, as quais representam informações processadas/agregadas, ajudando a quantificar todas as combinações possíveis entre as dimensões. Devido a questões de desempenho e de volume, as dimensões foram incluídas nas tabelas principais. 

Para realizar a leitura dos arquivos JSON disponibilizados, foi desenvolvida uma rotina de ETL usando a ferramenta Pentaho Data Integration (PDI). O tratamento dos dados foi realizado em três fases. Primeiramente, a conversão de formato dos arquivos JSON para CSV via Python para ganhar velocidade de leitura dos arquivos de entrada. Posteriormente, processamento dos arquivos CSV através de ETL e armazenamento no banco de dados Postgres no mesmo esquema dimensional mencionado. Por fim, é realizado o cálculo das métricas para serem utilizados nas tabelas de processos e movimentações. 

Após a organização do banco de dados, iniciou-se uma análise exploratória dos dados em R: tratamento, limpeza, entendimento, interpretação e visualização dos mesmos para elaboração dos dashboards.  

Durante o processo de exploração e tratamentos dos dados, nos deparamos com diversas inconsistências relacionadas à base de dados e tabelas do SGT e do MPM, como, por exemplo, a não correspondência entre as variáveis “codigoNacional” e “codigoPaiNacional” de assuntos e movimentos, necessitando assim, de conferência manual dessas variáveis para posteriormente relacioná-las corretamente às tabelas do SGT. Além disso, diversos processos apresentaram inconsistências em suas movimentações e código do órgão julgador, tais quais: um único tipo de movimentação sendo repetida do início ao fim do processo; processos com mais de 10 anos e apenas uma movimentação; processos cujo código do órgão julgador era 0. Essas foram apenas algumas das inconsistências encontradas.

  

A Equipe Plurata espera que a solução “Eficiência do Judiciário” idealizada para este Hackathon cumpra seu propósito e consiga auxiliar o CNJ e os diversos tribunais do Brasil em suas necessidades jurídicas.

  
