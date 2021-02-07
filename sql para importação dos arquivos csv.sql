# Script contendo todos os SQLs utilizados para a importação dos arquivos csv
# para tabelas no MySQL para tratamento dos dados e geração da ABT

create schema tcc;
use tcc;

# Importação dos dados cadastrais das empresas
create table empresas (
	tipo_de_registro varchar(1),
	indicador_full_diario varchar(1),
	tipo_atualizacao varchar(1),
	cnpj varchar(14),
	identificador_matriz_filial varchar(1),
	razao_social varchar(150),
	nome_fantasia varchar(55),
	situacao_cadastral varchar(10),
	data_situacao_cadastral varchar(10),
	motivo_situacao_cadastral varchar(5),
	nome_cidade_exterior varchar(55),
	cod_pais varchar(3),
	nome_pais varchar(70),
	codigo_natureza_juridica varchar(15),
	data_inicio_atividade varchar(10),
	cnae_fiscal varchar(10),
	descricao_tipo_logradouro varchar(20),
	logradouro varchar(60),
	numero varchar(6),
	complemento varchar(156),
	bairro varchar(50),
	cep varchar(8),
	uf varchar(2),
	codigo_municipio varchar(5),
	municipio varchar(50),
	ddd_telefone_1 varchar(15),
	ddd_telefone_2 varchar(15),
	ddd_fax varchar(15),
	correio_eletronico varchar(115),
	qualificacao_do_responsavel int,
	capital_social double,
	porte varchar(2),
	opcao_pelo_simples varchar(1),
	data_opcao_pelo_simples varchar(10),
	data_exclusao_do_simples varchar(10),
	opcao_pelo_mei varchar(1),
	situacao_especial varchar(23),
	data_situacao_especial varchar(10),
	filler varchar(1),
	fim_de_registro varchar(1)
);

load data infile 'v:/tcc/cnpj_dados_cadastrais_pj.csv' ignore
into table empresas
fields terminated by '#'
lines terminated by '\n'
ignore 1 lines
(@dummy,@dummy,@dummy,cnpj,identificador_matriz_filial,razao_social,nome_fantasia,situacao_cadastral,
data_situacao_cadastral,motivo_situacao_cadastral,@dummy,@dummy,@dummy,codigo_natureza_juridica,data_inicio_atividade,
cnae_fiscal,@dummy,@dummy,@dummy,@dummy,@dummy,cep,uf,codigo_municipio,municipio,@dummy,@dummy,@dummy,@dummy,
qualificacao_do_responsavel,capital_social,porte,opcao_pelo_simples,data_opcao_pelo_simples,@dummy,
opcao_pelo_mei,@dummy,@dummy,@dummy,@dummy);

# Importação dos dados dos sócios
CREATE TABLE socios (
	tipo_de_registro int,
	indicador varchar(1),
	tipo_atualizacao varchar(1),
	cnpj varchar(14),
    identificador_socio int,
	nome_socio varchar(150),
	cnpj_cpf_socio varchar(14),
	cod_qualificacao_socio double,
	percentual_capital_socio int,
	data_entrada_sociedade date,
	cod_pais varchar(3),
	nome_pais_socio varchar(70),
	cpf_repr_legal varchar(11),
	nome_representante varchar(60),
	cod_qualificacao_repr_legal varchar(2),
	filler varchar(1),
	fim_registro varchar(1)
  );

load data infile 'V:/tcc/cnpj_dados_socios_pj.csv' ignore
into table socios
columns terminated by '#' 
lines terminated by '\n'
ignore 1 lines
(@dummy,@dummy,@dummy,cnpj,identificador_socio,@dummy,@dummy,cod_qualificacao_socio,
@dummy,data_entrada_sociedade,@dummy,@dummy,@dummy,@dummy,
cod_qualificacao_repr_legal,@dummy,@dummy);

# Importação das empresas inidôneas
create table inidoneas (
	tipo_pessoa	varchar(1),
	cpf_cnpj_sancionado	varchar(14),
	nome_informado varchar(255),
	razao_social varchar(255),
	nome_fantasia varchar(255),
	numero_processo	varchar(255),
	tipo_sancao	varchar(255),
	data_inicio_sancao	text,
	data_final_sancao	text,
	orgao_sancionador	varchar(255),
	uf_orgao_sancionador	varchar(2),
	origem_informacoes	varchar(255),
	data_origem_informacoes	text,
	data_publicacao text,
	publicacao	varchar(255),
	detalhamento	varchar(255),
	abrangencia varchar(255),
	fundamentacao_legal	varchar(255),
	descricao_fundamentacao_legal	varchar(255),
	data_transito_julgado	text,
	complemento_orgao	varchar(255),
	observacoes varchar(255)
);

load data infile 'V:/tcc/inidoneas.csv' ignore
into table inidoneas
character set 'utf8'
columns terminated by ';' 
enclosed by '"'
lines terminated by '\r\n'
ignore 1 lines
(tipo_pessoa, cpf_cnpj_sancionado, nome_informado, razao_social, nome_fantasia, @dummy,
@dummy, data_inicio_sancao, data_final_sancao, orgao_sancionador, uf_orgao_sancionador,@dummy,
data_origem_informacoes, data_publicacao,publicacao, @dummy, abrangencia, @dummy,
@dummy, data_transito_julgado, @dummy,@dummy);

# Importação das compras governamentais
create table compras (
	numero_Contrato text,
	Objeto text,
	Fundamento_Legal text,
	Modalidade_Compra text,
	Situacao_Contrato text,
	codigo_orgao_superior text,
	nome_orgao_Superior text,
	Codigo_orgao text,
	Nome_orgao text,
	codigo_UG text,
	Nome_UG text,
	Data_Assinatura_Contrato text,
	Data_Publicacao_DOU text,
	Data_inicio_vigencia text,
	Data_fim_vigencia text,
	CNPJ_Contratado text,
	Nome_Contratado text,
	Valor_Inicial_Compra decimal(18,2),
	Valor_Final_Compra decimal(18,2)
    );
    
load data infile 'V:/tcc/compras.csv' ignore
into table compras
character set 'utf8'
columns terminated by ';' 
enclosed by '"'
lines terminated by '\r\n'
ignore 1 lines
(numero_contrato,objeto,fundamento_legal,modalidade_compra,situacao_contrato,
codigo_orgao_superior,nome_orgao_superior,codigo_orgao,nome_orgao,codigo_ug,nome_ug,
data_assinatura_contrato,data_publicacao_dou,data_inicio_vigencia,data_fim_vigencia,
cnpj_contratado,nome_contratado,valor_inicial_compra,valor_final_compra);

# Importação das descrições do CNAE
create table cnae (
	cod_secao varchar(1),
	nm_secao varchar(100),
	cod_divisao int,
	nm_divisao varchar(200),
	cod_grupo varchar(5),
	nm_grupo varchar(200),
	cod_classe varchar(20),
	nm_classe varchar(200),
	cod_cnae varchar(10),
	nm_cnae varchar(200)
);

load data infile 'V:/tcc/tab_cnae.csv'
into table cnae
columns terminated by '#'
lines terminated by '\n'
ignore 1 lines;

# Importação das descrições das naturezas jurídicas
create table natureza_juridica (
	cod_nat_juridica int,
	nm_nat_juridica varchar(100),
	cod_subclas_nat_jur int,
	nm_subclas_nat_jur varchar(200)
);

load data infile 'V:/tcc/tab_natureza_juridica.csv'
into table natureza_juridica
columns terminated by '#'
lines terminated by '\n'
ignore 1 lines;


# Importação das descrições das qualificações dos sócios/responsáveis
create table qualificacao_socio (
	cod_qualif_socio int,
	nome_qualif_socio varchar(255),
	coletado_atualmente varchar(3)
);

load data infile 'V:/tcc/tab_qualificacao_responsavel_socio.csv'
into table qualificacao_socio
columns terminated by '#'
lines terminated by '\n'
ignore 1 lines;

# ====== Fim do script SQL =======




