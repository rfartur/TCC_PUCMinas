# Este script SQL é para montagem de uma ABT com as compras totais,
# não se restringindo a nenhum órgão em específico

# cria tabela com as pessoas_juridicas apenas marcadas como inidoneas
drop table maus;
create table maus as
select distinct cpf_cnpj_sancionado, nome_informado, orgao_sancionador, uf_orgao_sancionador
	from inidoneas
    where tipo_pessoa = 'J';
------------------------------------------------
# Cria tabela com todas as compras efetuadas pelos órgãos selecionando apenas as pessoas jurídicas
drop table compras_totais;
create table compras_totais as
select 
	if(length(cnpj_contratado)=13,lpad(cnpj_contratado,14,'0'),cnpj_contratado) as cnpj_contratado,
	nome_contratado,
	modalidade_compra,
	objeto,
	codigo_orgao,
	nome_orgao,
	codigo_ug,
	nome_ug,
	valor_inicial_compra,
	valor_final_compra
from compras where length(cnpj_contratado)>=13;
---------------------------------------------------
# Cria tabela auxiliar com os cnpjs dos fornecedores
drop table cnpj_compras_totais;
create table cnpj_compras_totais as
select distinct 
	cnpj_contratado
from compras_totais;
---------------------------------------------------
# Verifica quantos cnpjs fornecedores estão na lista de maus
select count(distinct cnpj_contratado) from compras_totais;
select t1.cnpj_contratado, t2.nome_informado, t2.orgao_sancionador, t2.uf_orgao_sancionador
from cnpj_compras_totais t1 join maus t2 on t1.cnpj_contratado = t2.cpf_cnpj_sancionado;
---------------------------------------------------
# Começa montagem da tabela ABT. Cria primeira tabela com dados cadastrais
drop table empresas_compras_totais_1;
create table empresas_compras_totais_1 as
select 
	cnpj,
	identificador_matriz_filial,
	razao_social,
	situacao_cadastral,
	data_situacao_cadastral,
	motivo_situacao_cadastral,
	codigo_natureza_juridica,
	data_inicio_atividade,
	cnae_fiscal,
	cep,
	uf,
	codigo_municipio,
	municipio,
	qualificacao_do_responsavel,
	capital_social,
	porte,
	opcao_pelo_simples,
	opcao_pelo_mei
from empresas where cnpj in (select cnpj_contratado from cnpj_compras_totais);
---------------------------------------------------
# Acrescenta mais informações à tabela ABT e também já 
# resolve alguns problemas de representação de dados
drop table empresas_compras_totais_2;

create table empresas_compras_totais_2 as
select 
	t1.cnpj,
	t1.identificador_matriz_filial,
	t1.razao_social,
	t1.situacao_cadastral,
	t1.data_situacao_cadastral,
	t1.motivo_situacao_cadastral,
	t1.codigo_natureza_juridica,
    t2.nm_subclas_nat_jur,
	t1.data_inicio_atividade,
	t1.cnae_fiscal,
    t3.nm_cnae,
	t1.cep,
	t1.uf,
	t1.codigo_municipio,
	t1.municipio,
	t1.qualificacao_do_responsavel,
    t4.nome_qualif_socio,
	t1.capital_social,
	t1.porte,
    case t1.porte
		when '00' then 'Não Informado'
		when '01' then 'Micro Empresa'
		when '03' then 'Empresa Pequeno Porte'
		when '05' then 'Demais' 
    end as nm_porte,
    t1.opcao_pelo_simples,
    case t1.opcao_pelo_simples
		when '0' then 'Não Optante'
        when ' ' then 'Não Optante'
        when '5' then 'Optante'
        when '7' then 'Optante'
        when '6' then 'Excluido'
        when '8' then 'Excluido'
	end as nm_optante_simples,
	t1.opcao_pelo_mei
from empresas_compras_totais_1 t1 
left join natureza_juridica t2 on t1.codigo_natureza_juridica = t2.cod_subclas_nat_jur
left join cnae t3 on t1.cnae_fiscal=t3.cod_cnae
left join qualificacao_socio t4 on t1.qualificacao_do_responsavel = t4.cod_qualif_socio
;
-------------------------------------------------
# Cria tabela com informações dos sócios para juntar à ABT
# Cria variável: 1-qtde_meses_entr_socio
drop table socios_resumo_compras_totais_t;
create table socios_resumo_compras_totais_t as
select
	cnpj,
    data_entrada_sociedade
from socios where cnpj in (select cnpj_contratado from cnpj_compras_totais);

drop table socios_resumo_compras_totais;
create table socios_resumo_compras_totais as
SELECT 
	cnpj, 
    max(data_entrada_sociedade) as ultima_data_entrada, 
    timestampdiff(month, max(data_entrada_sociedade), curdate()) as qtde_meses_entr_socio,
    count(*) as nro_socios
FROM socios_resumo_compras_totais_t 
group by cnpj;
-----------------------------------------------------
# Acrescenta as informações dos sócios à tabela cadastro das empresas
# Cria uma variável: 1-idade_empresa_meses
drop table empresas_compras_totais_3;
create table empresas_compras_totais_3 as
select 
	t1.cnpj,
	t1.identificador_matriz_filial,
	t1.razao_social,
	t1.situacao_cadastral,
    str_to_date(t1.data_situacao_cadastral, '%Y-%m-%d') as data_situacao_cadastral,
	t1.motivo_situacao_cadastral,
	t1.codigo_natureza_juridica,
	t1.nm_subclas_nat_jur,
	str_to_date(t1.data_inicio_atividade, '%Y-%m-%d') as data_inicio_atividade,
    timestampdiff(month, str_to_date(t1.data_inicio_atividade, '%Y-%m-%d'), curdate()) as idade_empresa_meses,
	t1.cnae_fiscal,
	t1.nm_cnae,
	t1.cep,
	t1.uf,
	t1.codigo_municipio,
	t1.municipio,
	t1.qualificacao_do_responsavel,
	t1.nome_qualif_socio,
	t1.capital_social,
	t1.porte,
	t1.nm_porte,
	t1.opcao_pelo_simples,
	t1.nm_optante_simples,
	t1.opcao_pelo_mei,
    t2.ultima_data_entrada,
    t2.qtde_meses_entr_socio,
    t2.nro_socios
from empresas_compras_totais_2 t1 left join socios_resumo_compras_totais t2 on t1.cnpj=t2.cnpj;
---------------------------------------------------
# Cria ABT juntando as informações cadastrais das empresas com as
# informações das contratações/compras
# Cria 2 variáveis: 1-diferença_compra e 2-aumento_valor_contrato

drop table abt_compras_totais_1;
create table abt_compras_totais_1 as
select
	t1.cnpj,
	t1.identificador_matriz_filial,
	t1.razao_social,
	t1.situacao_cadastral,
	t1.data_situacao_cadastral,
	t1.motivo_situacao_cadastral,
	t1.codigo_natureza_juridica,
	t1.nm_subclas_nat_jur,
	t1.data_inicio_atividade,
	t1.idade_empresa_meses,
	t1.cnae_fiscal,
	t1.nm_cnae,
	t1.cep,
	t1.uf,
	t1.codigo_municipio,
	t1.municipio,
	t1.qualificacao_do_responsavel,
	t1.nome_qualif_socio,
	t1.capital_social,
	t1.porte,
	t1.nm_porte,
	t1.opcao_pelo_simples,
	t1.nm_optante_simples,
	t1.opcao_pelo_mei,
	t1.ultima_data_entrada,
	t1.qtde_meses_entr_socio,
	t1.nro_socios,
	-- t2.cnpj_contratado,
	-- t2.nome_contratado,
	t2.modalidade_compra,
	t2.objeto,
	t2.codigo_orgao,
	t2.nome_orgao,
	t2.codigo_ug,
	t2.nome_ug,
	t2.valor_inicial_compra,
	t2.valor_final_compra,
    (t2.valor_final_compra - t2.valor_inicial_compra) as diferenca_compra,
    if((t2.valor_final_compra - t2.valor_inicial_compra) > 0,'S','N') as aumento_valor_contrato
from compras_totais t2 left join empresas_compras_totais_3 t1 on t2.cnpj_contratado=t1.cnpj;
----------------------------------------------------
# Cria a tabela ABT final pronta para exportar e analisar e criar modelos no R
# Adiciona a variável target que marca as observações como inidôneas ou não para
# o aprendizado supervisionado do modelo

drop table abt_compras_totais_final;
create table abt_compras_totais_final as
select 
	t1.cnpj,
	t1.identificador_matriz_filial,
	t1.razao_social,
	t1.situacao_cadastral,
	t1.data_situacao_cadastral,
	t1.motivo_situacao_cadastral,
	t1.codigo_natureza_juridica,
	t1.nm_subclas_nat_jur,
	t1.data_inicio_atividade,
	t1.idade_empresa_meses,
	t1.cnae_fiscal,
	t1.nm_cnae,
	t1.cep,
	t1.uf,
	t1.codigo_municipio,
	t1.municipio,
	t1.qualificacao_do_responsavel,
	t1.nome_qualif_socio,
	t1.capital_social,
	t1.porte,
	t1.nm_porte,
	t1.opcao_pelo_simples,
	t1.nm_optante_simples,
	t1.opcao_pelo_mei,
	t1.ultima_data_entrada,
	t1.qtde_meses_entr_socio,
	t1.nro_socios,
	t1.modalidade_compra,
	t1.objeto,
	t1.codigo_orgao,
	t1.nome_orgao,
	t1.codigo_ug,
	t1.nome_ug,
	t1.valor_inicial_compra,
	t1.valor_final_compra,
    t1.diferenca_compra,
	t1.aumento_valor_contrato,
    if(t1.cnpj=t2.cpf_cnpj_sancionado,1,0) as inidonea
from abt_compras_totais_1 t1 left join maus t2 on t1.cnpj=t2.cpf_cnpj_sancionado
where cnpj is not null;
------------------------------------------------------------------

# Exporta a tabela ABT para arquivo csv para posterior importação pelo R
select 
	'cnpj','identificador_matriz_filial','razao_social','codigo_natureza_juridica',
    'nm_subclas_nat_jur','data_inicio_atividade','idade_empresa_meses','cnae_fiscal',
    'nm_cnae','cep','uf','codigo_municipio','municipio','qualificacao_do_responsavel',
    'nome_qualif_socio','capital_social','porte','nm_porte','opcao_pelo_simples',
    'nm_optante_simples','opcao_pelo_mei','ultima_data_entrada','qtde_meses_entr_socio',
    'nro_socios','modalidade_compra','codigo_orgao','nome_orgao','codigo_ug',
    'nome_ug','valor_inicial_compra','valor_final_compra','diferenca_compra','aumento_valor_contrato',
    'inidonea'
union all
select 
	cnpj,
	identificador_matriz_filial,
	razao_social,
	codigo_natureza_juridica,
	nm_subclas_nat_jur,
	data_inicio_atividade,
	idade_empresa_meses,
	cnae_fiscal,
	nm_cnae,
	cep,
	uf,
	codigo_municipio,
	municipio,
	qualificacao_do_responsavel,
	nome_qualif_socio,
	capital_social,
	porte,
	nm_porte,
	opcao_pelo_simples,
	nm_optante_simples,
	opcao_pelo_mei,
	ultima_data_entrada,
	qtde_meses_entr_socio,
	nro_socios,
	modalidade_compra,
	codigo_orgao,
	nome_orgao,
	codigo_ug,
	nome_ug,
	valor_inicial_compra,
	valor_final_compra,
	diferenca_compra,
    aumento_valor_contrato,
	inidonea
from abt_compras_totais_final
into outfile 'v:/tcc/abt.csv'
charset 'utf8mb4'
fields terminated by ';'
enclosed by '"'
lines terminated by '\r\n';

#-----------  FIM DO SCRIPT SQL ---------------------#

