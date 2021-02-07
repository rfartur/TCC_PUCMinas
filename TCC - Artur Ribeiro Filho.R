#=======================================================
# Script em R para o TCC - Ciência de Dados e Big Data
# Autor: Artur Ribeiro Filho
#=======================================================

# Definindo o diretório de trabalho onde está a ABT
setwd("V:/tcc")

# Carregando as bibliotecas utilizadas no script
library(data.table)
library(caret)
library(ROCR)
library(pROC)
library(DMwR)
library(ROSE)
library(gmodels)
library(C50)
library(ggplot2)
library(Information)
library(Hmisc)

#-----------------------------------------------------
# PARTE - 1 - Importação dos dados
#-----------------------------------------------------

# Importando a tabela ABT trabalhada no MySql e exportada para csv. Muitos dados já foram
# tratados no uso do SQL e estão nos scripts SQLs anexados ao trabalho

# Utilizando fread para carregar a tabela
abt <- fread("v:/tcc/abt.csv", stringsAsFactors = F, sep = ";", header = T, encoding = 'UTF-8',
             colClasses = c(cnpj="character", identificador_matriz_filial="factor",
                            razao_social="character", ultima_data_entrada="Date",
                            inidonea="numeric"))

# Verificando os tipos de dados importados
str(abt)

# Alterando alguns tipos de dados
abt$qtde_meses_entr_socio <- as.integer(abt$qtde_meses_entr_socio)
abt$nro_socios <- as.integer(abt$nro_socios)
abt$codigo_natureza_juridica <- as.factor(abt$codigo_natureza_juridica)
abt$nm_porte <- as.factor(abt$nm_porte)
abt$qualificacao_do_responsavel <- as.factor(abt$qualificacao_do_responsavel)
abt$opcao_pelo_simples <- as.factor(abt$opcao_pelo_simples)

# Visualiza a tabela importada
View(abt)

#-----------------------------------------------------
# PARTE - 2 - Análise Exploratória
#-----------------------------------------------------

# Imprime tabela com estatísticas de algumas variáveis
estatisticas <- describe(abt)
for (i in 2:33) {print(estatisticas[i][1])}

# Variáveis numéricas
summary(abt$idade_empresa_meses)
boxplot(abt$idade_empresa_meses, col = 'blue')
hist(abt$idade_empresa_meses, col = 'green', breaks = 100)
abline(v = median(abt$idade_empresa_meses), col = "red", lwd = 4)
rug(abt$idade_empresa_meses)

# Esta variável possui # missings = 1330
summary(abt$qtde_meses_entr_socio)

# Substituindo os missings pela média
abt$qtde_meses_entr_socio[is.na(abt$qtde_meses_entr_socio)] <- round(mean(abt$qtde_meses_entr_socio, na.rm = TRUE))
summary(abt$qtde_meses_entr_socio)

boxplot(abt$qtde_meses_entr_socio, col = 'blue')
hist(abt$qtde_meses_entr_socio, col = 'green', breaks = 100)
abline(v = median(abt$qtde_meses_entr_socio), col = "red", lwd = 4)
rug(abt$qtde_meses_entr_socio)

# Esta variável possui # missings = 1330
summary(abt$nro_socios)

# Substituindo os missings pela média
abt$nro_socios[is.na(abt$nro_socios)] <- round(mean(abt$nro_socios, na.rm = TRUE))
summary(abt$nro_socios)

boxplot(abt$nro_socios, col = 'blue')
hist(abt$nro_socios, col = 'green', breaks = 500)
abline(v = median(abt$nro_socios), col = "red", lwd = 4)
rug(abt$nro_socios)

# Variáveis categóricas

# A coluna inidonea indica se a empresa cometeu alguma irregularidade no processo ou não, 
# sendo portanto nossa variável target.
# 0 indica que a empresa não cometeu irregularidade 
# 1 indica que a empresa cometeu alguma irregularidade e foi proibida de contratar pelo poder público

nome_qualif_socio_bar <- table(abt$nome_qualif_socio) 
barplot(nome_qualif_socio_bar, main="Qualificação dos Sócios", legend.text = TRUE,
        col = c("lightblue", "mistyrose", "lightcyan",
                "lavender", "cornsilk"),
        xlab="Qualificação",axis.lty=1)

nm_porte_bar <- table(abt$nm_porte) 
barplot(nm_porte_bar, main="Porte das Empresas", xlab="Descrição",axis.lty=1, col="yellow")

table(abt$uf)
uf_bar <- table(abt$uf)
barplot(uf_bar, main="Quantidade de Empresas por Estado", xlab="UF",axis.lty=1, col="purple")

table(abt$nm_optante_simples)
nm_optante_simples_bar <- table(abt$nm_optante_simples)
barplot(nm_optante_simples_bar, main="Quantidade de Empresas Optante pelo Simples", 
        xlab="Optante",axis.lty=1, col="red")

table(abt$modalidade_compra)
modalidade_compra_bar <- table(abt$modalidade_compra)
barplot(modalidade_compra_bar, main="Modalidade de Compra", 
        xlab="Modalidade",axis.lty=1, col="aquamarine")


#-------------------------------------------------
# Parte 3 - Estudo do IV
# Selecionando as melhores variáveis para utilizar 
# no modelo de classificação baseado no estudo de 
# Inormation Value - IV
#-------------------------------------------------

# Separa as variáveis a serem testadas 
abt_poder <- c('codigo_natureza_juridica','idade_empresa_meses', 'cnae_fiscal', 'qualificacao_do_responsavel',
                   'nro_socios', 'nm_porte', 'opcao_pelo_simples', 'qtde_meses_entr_socio', 'codigo_orgao', 
                   'valor_inicial_compra','valor_final_compra','diferenca_compra','aumento_valor_contrato',
                   'identificador_matriz_filial','capital_social','opcao_pelo_mei',
                    'codigo_ug','inidonea'
               )
abt_iv <- abt[, ..abt_poder]

infoTables  <- create_infotables(data = abt_iv, y = 'inidonea', bins = 10, parallel = T)

# Plotagem do gráfico com os IVs
plotFrame <- infoTables$Summary[order(-infoTables$Summary$IV), ]
plotFrame$Variable <- factor(plotFrame$Variable,levels = plotFrame$Variable[order(-plotFrame$IV)])

ggplot(plotFrame, aes(x = Variable, y = IV)) +
        geom_bar(width = .35, stat = 'identity', color = 'darkblue', fill = 'blue') +
        ggtitle('Information Value') +
        theme_bw() +
        theme(plot.title = element_text(size = 10)) +
        theme(axis.text.x = element_text(angle = 90))

#-----------------------------------------------------
# PARTE 4 - Dividindo a base em treinamento e teste
#-----------------------------------------------------

# Separando na base somente as variáveis que serão usadas na modelagem

abt_variaveis <- c('codigo_natureza_juridica','idade_empresa_meses', 'cnae_fiscal', 
                   'capital_social','nro_socios', 'qtde_meses_entr_socio', 'inidonea'
                   )

abt <- abt[, ..abt_variaveis]

# Converter a variável target para factor para modelagem
abt$inidonea <- as.factor(abt$inidonea)

# Distribuição da variável target para classificação
# A base está completamente desbalanceada
# Temos cerca de 98% de observações para a classe 0 e aproximadamente
# 2% para a classe 1
prop.table(table(abt$inidonea))

# Graficamente a diferença entre as classes:
barplot(prop.table(table(abt$inidonea)))

# Dividindo a base para construir os datasets de treino e de teste
# 70% para treinamento e 30% para teste
abt_sample <- sample(1:nrow(abt), 0.7 * nrow(abt))

abt_treino <- abt[abt_sample,]
abt_teste  <- abt[-abt_sample,]

# Verificando a proporção da variável target em treinamento e teste
prop.table(table(abt_treino$inidonea))
prop.table(table(abt_teste$inidonea))

# Manteve-se a proporção das classes em relação à base total.
# Portanto, esses datasets continuam desbalanceados

# Será criado um modelo utilizando as classes desbalanceadas e depois
# de balancear as classes será criado novo modelo com balanceamento

#-----------------------------------------------------
# PARTE 5 - Criação do Modelo - Arvore de Decisão
#             utilizando C5.0 - BASES DESBALANCEADAS
#-----------------------------------------------------

# Utilizando a opção noGlobalPruning = FALSE para realizar a poda
abt_modelo_com_poda <- C5.0(inidonea ~ codigo_natureza_juridica + idade_empresa_meses + cnae_fiscal +
                        capital_social + nro_socios + qtde_meses_entr_socio,
                        data = abt_treino,
                        method = "class",
                        control = C5.0Control(noGlobalPruning = FALSE, minCases = 5) 
                        )

# Verifica o modelo
abt_modelo_com_poda

# Imprime detalhes do modelo
summary(abt_modelo_com_poda)

# Plota toda a árvore criada
plot(abt_modelo_com_poda)

# Calcula a importância das variáveis para o modelo, o quanto cada uma contribui
C5imp(abt_modelo_com_poda)

#-----------------------------------------------------
# PARTE 6 - Fazendo a previsão na base de teste e
#             avaliando os resultados do modelo -
#             modelo com poda e
#             BASES DESBALANCEADAS
#-----------------------------------------------------

# Fazendo as previsões no dataset de teste
abt_previsao <- predict(abt_modelo_com_poda, abt_teste, type = "class")

# Verifica o modelo
abt_previsao

# Imprime detalhes do resultado
summary(abt_previsao)

# Confusion Matrix para analisar a acurácia do modelo
# O parâmetro positive = '1' indica que a classe 1 é a positiva, ou seja, indica que sim, a transação é fraudulenta
confusionMatrix(abt_teste$inidonea, abt_previsao, positive = '1')

# Curva ROC para encontrar a métrica AUC
roc.curve(abt_teste$inidonea, abt_previsao, plotit = T, col = "red")

# Com base somente na acurácia, o modelo estaria excelente. Mas o Score AUC mostra que não.

# Imprime a matriz de confusão - outra visão
CrossTable(abt_teste$inidonea, abt_previsao, 	prop.chisq = FALSE, 
           prop.c = FALSE, prop.r = FALSE, 	dnn = c("actual default", "predict default"))

#-----------------------------------------------------
# PARTE 7 - Criação do Modelo - Arvore de Decisão
#             utilizando C5.0 - BASES BALANCEADAS
#-----------------------------------------------------

# Com SMOTE (Synthetic Minority Oversampling Technique) as classes serão balanceadas usando a técnica de Oversampling. 
# O IDEAL É SEMPRE APLICAR O DESBALANCEAMENTO DEPOIS DE FAZER A DIVISÃO DOS DADOS EM TREINO E TESTE.
# Se fizermos antes, o padrão usado para aplicar o oversampling será o mesmo nos dados de treino e de teste e, assim,
# a avaliação do modelo ficará comprometida. 

# Aplicando SMOTE em dados de treino e checando a proporção de classes
abt_treino_smote <- SMOTE(inidonea ~ ., data = abt_treino, perc.over = 1000, k = 5, perc.under = 800)
prop.table(table(abt_treino_smote$inidonea))

# Verificando graficamente
barplot(prop.table(table(abt_treino_smote$inidonea)))

# Aplicando SMOTE em dados de teste e checando a proporção de classes
abt_teste_smote <- SMOTE(inidonea ~ ., data = abt_teste, perc.over = 1000, k = 5, perc.under = 800)
prop.table(table(abt_teste_smote$inidonea))

# Agora criamos o modelo usando dados de treino balanceados
abt_modelo_smote <- C5.0(inidonea ~ codigo_natureza_juridica + idade_empresa_meses + cnae_fiscal +
                                 capital_social + nro_socios + qtde_meses_entr_socio,
                         data = abt_treino_smote,
                         method = "class",
                         control = C5.0Control(noGlobalPruning = FALSE, minCases = 5) 
                        )

# Verifica o modelo
abt_modelo_smote

# Imprime detalhes do modelo
summary(abt_modelo_smote)

# Plota toda a árvore criada
plot(abt_modelo_smote)

# Calcula a importância das variáveis para o modelo, o quanto cada uma contribui
C5imp(abt_modelo_smote)

# E fazemos previsões usando dados de teste balanceados
abt_previsao_smote <- predict(abt_modelo_smote, abt_teste_smote)

# Verificando o modelo
abt_previsao_smote

# Imprime detalhes do modelo
summary(abt_previsao_smote)

# Vamos verificar a acurácia
confusionMatrix(abt_teste_smote$inidonea, abt_previsao_smote)

# Calculamos o Score AUC
roc.curve(abt_teste_smote$inidonea, abt_previsao_smote, plotit = T, col = "green", add.roc = T)

#============== FIM DO SCRIPT =================================================


