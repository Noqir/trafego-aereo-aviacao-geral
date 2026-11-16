-- =====================================================================
-- Projeto Final de Banco de Dados
-- Sistema de registro e análise de operações de tráfego aéreo
-- (aviação geral com aeronaves leves monomotoras)
--
-- Script único: cria o banco, as tabelas e insere a massa de dados.
-- Requer MySQL 8.0.16 ou superior (CHECK só é aplicado a partir dessa versão).
-- Pode ser executado do zero quantas vezes for necessário.
-- =====================================================================

-- Garante que o cliente envie o texto em utf8mb4 (acentos gravados corretamente)
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS trafego_aereo;
CREATE DATABASE trafego_aereo DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE trafego_aereo;

-- =====================================================================
-- PARTE 1: CRIAÇÃO DAS TABELAS (DDL), EM ORDEM DE DEPENDÊNCIA
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabela 1: aerodromo
-- Aeródromos brasileiros reais, identificados pelo código ICAO.
-- ---------------------------------------------------------------------
CREATE TABLE aerodromo (
  id_aerodromo  INT AUTO_INCREMENT PRIMARY KEY,
  codigo_icao   CHAR(4) NOT NULL,                   -- código ICAO de 4 letras (ex.: SBMT)
  nome          VARCHAR(120) NOT NULL,
  cidade        VARCHAR(80) NOT NULL,
  uf            CHAR(2) NOT NULL,
  tipo          VARCHAR(10) NOT NULL DEFAULT 'publico', -- 'publico' ou 'privado'
  CONSTRAINT uq_aerodromo_codigo_icao UNIQUE (codigo_icao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 2: pista
-- Pistas de cada aeródromo (1:N com aerodromo).
-- ---------------------------------------------------------------------
CREATE TABLE pista (
  id_pista       INT AUTO_INCREMENT PRIMARY KEY,
  id_aerodromo   INT NOT NULL,
  designacao     VARCHAR(7) NOT NULL,                -- cabeceiras, ex.: 12/30 ou 02R/20L
  comprimento_m  INT NOT NULL,                       -- comprimento em metros
  tipo_piso      VARCHAR(10) NOT NULL,               -- asfalto, concreto, grama, terra, cascalho
  situacao       VARCHAR(12) NOT NULL DEFAULT 'ativa', -- ativa, interditada, em_obras
  CONSTRAINT fk_pista_aerodromo
    FOREIGN KEY (id_aerodromo) REFERENCES aerodromo(id_aerodromo)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT uq_pista_aerodromo_designacao UNIQUE (id_aerodromo, designacao),
  CONSTRAINT ck_pista_comprimento_m CHECK (comprimento_m > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 3: operador
-- Aeroclubes, escolas de aviação e proprietários particulares.
-- ---------------------------------------------------------------------
CREATE TABLE operador (
  id_operador  INT AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(120) NOT NULL,
  tipo         VARCHAR(12) NOT NULL,                 -- aeroclube, escola, particular
  cidade       VARCHAR(80) NOT NULL,
  uf           CHAR(2) NOT NULL,
  CONSTRAINT uq_operador_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 4: modelo_aeronave
-- Catálogo de modelos de aeronaves leves. Extraída de aeronave para
-- atender a 3FN (fabricante, assentos e potência dependem do modelo).
-- ---------------------------------------------------------------------
CREATE TABLE modelo_aeronave (
  id_modelo_aeronave  INT AUTO_INCREMENT PRIMARY KEY,
  fabricante          VARCHAR(60) NOT NULL,
  nome_modelo         VARCHAR(60) NOT NULL,
  numero_assentos     TINYINT NOT NULL,              -- inclui o assento do piloto
  potencia_hp         SMALLINT NOT NULL,             -- potência do motor em hp
  CONSTRAINT uq_modelo_aeronave_fabricante_modelo UNIQUE (fabricante, nome_modelo),
  -- limite de 6 assentos: mantém o escopo em aeronaves leves
  CONSTRAINT ck_modelo_aeronave_numero_assentos CHECK (numero_assentos BETWEEN 1 AND 6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 5: aeronave
-- Aeronaves individuais, identificadas pela matrícula (1:N com modelo
-- e 1:N com operador).
-- ---------------------------------------------------------------------
CREATE TABLE aeronave (
  id_aeronave         INT AUTO_INCREMENT PRIMARY KEY,
  matricula           VARCHAR(6) NOT NULL,           -- formato PP-XXX, PR-XXX, PS-XXX, PT-XXX
  id_modelo_aeronave  INT NOT NULL,
  id_operador         INT NOT NULL,
  ano_fabricacao      SMALLINT NOT NULL,
  situacao            VARCHAR(12) NOT NULL DEFAULT 'ativa', -- ativa, manutencao, inativa
  CONSTRAINT uq_aeronave_matricula UNIQUE (matricula),
  CONSTRAINT fk_aeronave_modelo_aeronave
    FOREIGN KEY (id_modelo_aeronave) REFERENCES modelo_aeronave(id_modelo_aeronave)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aeronave_operador
    FOREIGN KEY (id_operador) REFERENCES operador(id_operador)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 6: piloto
-- Pilotos, alunos e instrutores. O vínculo com operador é opcional.
-- ---------------------------------------------------------------------
CREATE TABLE piloto (
  id_piloto       INT AUTO_INCREMENT PRIMARY KEY,
  nome            VARCHAR(120) NOT NULL,
  numero_licenca  VARCHAR(10) NOT NULL,              -- código fictício de 6 dígitos
  categoria       VARCHAR(6) NOT NULL,               -- aluno, PP (privado), PC (comercial)
  instrutor       BOOLEAN NOT NULL DEFAULT FALSE,    -- possui habilitação de instrutor (INVA)
  situacao        VARCHAR(8) NOT NULL DEFAULT 'ativo', -- ativo, inativo
  id_operador     INT NULL,                          -- NULL: piloto sem vínculo
  CONSTRAINT uq_piloto_numero_licenca UNIQUE (numero_licenca),
  CONSTRAINT fk_piloto_operador
    FOREIGN KEY (id_operador) REFERENCES operador(id_operador)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 7: setor_aereo
-- Setores do espaço aéreo: FIR, TMA, CTR e ATZ.
-- ---------------------------------------------------------------------
CREATE TABLE setor_aereo (
  id_setor_aereo  INT AUTO_INCREMENT PRIMARY KEY,
  sigla           VARCHAR(20) NOT NULL,
  nome            VARCHAR(120) NOT NULL,
  tipo            CHAR(3) NOT NULL,                  -- FIR, TMA, CTR, ATZ
  CONSTRAINT uq_setor_aereo_sigla UNIQUE (sigla)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 8: voo
-- Operação aérea planejada ou realizada. Origem e destino podem ser o
-- mesmo aeródromo (circuito de tráfego e voo local de instrução).
-- ---------------------------------------------------------------------
CREATE TABLE voo (
  id_voo                INT AUTO_INCREMENT PRIMARY KEY,
  id_aeronave           INT NOT NULL,
  id_aerodromo_origem   INT NOT NULL,
  id_aerodromo_destino  INT NOT NULL,
  finalidade            VARCHAR(10) NOT NULL,
  partida_prevista      DATETIME NOT NULL,
  chegada_prevista      DATETIME NOT NULL,
  partida_real          DATETIME NULL,               -- NULL: voo previsto ou cancelado
  chegada_real          DATETIME NULL,               -- NULL: voo previsto ou cancelado
  situacao              VARCHAR(10) NOT NULL DEFAULT 'previsto',
  CONSTRAINT fk_voo_aeronave
    FOREIGN KEY (id_aeronave) REFERENCES aeronave(id_aeronave)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_voo_aerodromo_origem
    FOREIGN KEY (id_aerodromo_origem) REFERENCES aerodromo(id_aerodromo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_voo_aerodromo_destino
    FOREIGN KEY (id_aerodromo_destino) REFERENCES aerodromo(id_aerodromo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  -- a mesma aeronave não pode ter dois voos com a mesma partida prevista
  CONSTRAINT uq_voo_aeronave_partida UNIQUE (id_aeronave, partida_prevista),
  CONSTRAINT ck_voo_finalidade CHECK (finalidade IN ('instrucao', 'passeio', 'particular', 'traslado')),
  CONSTRAINT ck_voo_situacao CHECK (situacao IN ('previsto', 'realizado', 'cancelado')),
  CONSTRAINT ck_voo_chegada_prevista CHECK (chegada_prevista > partida_prevista),
  CONSTRAINT ck_voo_chegada_real CHECK (chegada_real IS NULL OR partida_real IS NULL OR chegada_real > partida_real)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 9: voo_piloto (associativa, N:N entre voo e piloto)
-- Registra quem estava a bordo e com qual função.
-- ---------------------------------------------------------------------
CREATE TABLE voo_piloto (
  id_voo_piloto  INT AUTO_INCREMENT PRIMARY KEY,
  id_voo         INT NOT NULL,
  id_piloto      INT NOT NULL,
  funcao         VARCHAR(10) NOT NULL,
  CONSTRAINT fk_voo_piloto_voo
    FOREIGN KEY (id_voo) REFERENCES voo(id_voo)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_voo_piloto_piloto
    FOREIGN KEY (id_piloto) REFERENCES piloto(id_piloto)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  -- o mesmo piloto não aparece duas vezes no mesmo voo
  CONSTRAINT uq_voo_piloto_par UNIQUE (id_voo, id_piloto),
  CONSTRAINT ck_voo_piloto_funcao CHECK (funcao IN ('comandante', 'instrutor', 'aluno', 'copiloto'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 10: voo_setor (associativa, N:N entre voo e setor_aereo)
-- Registra a travessia de cada setor, com ordem e horários.
-- ---------------------------------------------------------------------
CREATE TABLE voo_setor (
  id_voo_setor     INT AUTO_INCREMENT PRIMARY KEY,
  id_voo           INT NOT NULL,
  id_setor_aereo   INT NOT NULL,
  ordem_travessia  TINYINT NOT NULL,                 -- 1, 2, 3... em ordem cronológica
  horario_entrada  DATETIME NOT NULL,
  horario_saida    DATETIME NOT NULL,
  CONSTRAINT fk_voo_setor_voo
    FOREIGN KEY (id_voo) REFERENCES voo(id_voo)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_voo_setor_setor_aereo
    FOREIGN KEY (id_setor_aereo) REFERENCES setor_aereo(id_setor_aereo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  -- cada setor é registrado uma única vez por voo
  CONSTRAINT uq_voo_setor_par UNIQUE (id_voo, id_setor_aereo),
  -- duas travessias do mesmo voo não ocupam a mesma posição na sequência
  CONSTRAINT uq_voo_setor_ordem UNIQUE (id_voo, ordem_travessia),
  CONSTRAINT ck_voo_setor_horario_saida CHECK (horario_saida > horario_entrada)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 11: ocorrencia
-- Ocorrências registradas em um voo (1:N com voo).
-- ---------------------------------------------------------------------
CREATE TABLE ocorrencia (
  id_ocorrencia   INT AUTO_INCREMENT PRIMARY KEY,
  id_voo          INT NOT NULL,
  tipo            VARCHAR(25) NOT NULL,              -- atraso, cancelamento, desvio, falha_tecnica,
                                                     -- condicao_meteorologica, pouso_alternativo
  gravidade       VARCHAR(5) NOT NULL DEFAULT 'baixa', -- baixa, media, alta
  descricao       VARCHAR(255) NOT NULL,
  data_hora       DATETIME NOT NULL,
  minutos_atraso  SMALLINT NOT NULL DEFAULT 0,       -- atraso atribuído a esta ocorrência
  -- RESTRICT: um voo com ocorrências não pode ser excluído
  CONSTRAINT fk_ocorrencia_voo
    FOREIGN KEY (id_voo) REFERENCES voo(id_voo)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_ocorrencia_minutos_atraso CHECK (minutos_atraso >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Tabela 12: plano_voo
-- Plano de voo apresentado para um voo (1:1, garantido pelo UNIQUE em id_voo).
-- ---------------------------------------------------------------------
CREATE TABLE plano_voo (
  id_plano_voo            INT AUTO_INCREMENT PRIMARY KEY,
  id_voo                  INT NOT NULL,
  regra_voo               CHAR(3) NOT NULL DEFAULT 'VFR', -- VFR (visual) ou IFR (instrumentos)
  altitude_cruzeiro_pes   SMALLINT NOT NULL,         -- altitude de cruzeiro em pés
  velocidade_cruzeiro_kt  SMALLINT NOT NULL,         -- velocidade de cruzeiro em nós
  autonomia_min           SMALLINT NOT NULL,         -- autonomia de combustível em minutos
  pessoas_a_bordo         TINYINT NOT NULL,
  CONSTRAINT fk_plano_voo_voo
    FOREIGN KEY (id_voo) REFERENCES voo(id_voo)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT uq_plano_voo_id_voo UNIQUE (id_voo),
  CONSTRAINT ck_plano_voo_regra_voo CHECK (regra_voo IN ('VFR', 'IFR'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =====================================================================
-- PARTE 2: INSERÇÃO DOS DADOS (DML), EM ORDEM DE DEPENDÊNCIA
-- Aeródromos e setores são reais, com predominância de Minas Gerais;
-- operadores, aeronaves, pilotos, voos e ocorrências são fictícios.
-- Período dos voos: setembro a novembro de 2026; os voos previstos são
-- posteriores a 16/11/2026. Cada aeronave parte sempre do aeródromo em
-- que terminou o voo realizado anterior (ida e volta quando necessário).
-- =====================================================================

-- ---------------------------------------------------------------------
-- aerodromo (20 linhas): 15 em MG e 5 em estados vizinhos (SP, RJ, GO).
-- A coluna tipo é omitida e recebe o DEFAULT 'publico'.
-- ---------------------------------------------------------------------
INSERT INTO aerodromo (codigo_icao, nome, cidade, uf) VALUES
('SBBH', 'Aeroporto da Pampulha',                         'Belo Horizonte',        'MG'),  -- 1
('SBCF', 'Aeroporto Internacional de Confins',            'Confins',               'MG'),  -- 2
('SBUL', 'Aeroporto de Uberlândia',                       'Uberlândia',            'MG'),  -- 3
('SBUR', 'Aeroporto de Uberaba',                          'Uberaba',               'MG'),  -- 4
('SBMK', 'Aeroporto de Montes Claros',                    'Montes Claros',         'MG'),  -- 5
('SBIP', 'Aeroporto de Ipatinga',                         'Ipatinga',              'MG'),  -- 6
('SBJF', 'Aeroporto Francisco Álvares de Assis',          'Juiz de Fora',          'MG'),  -- 7
('SBZM', 'Aeroporto Regional da Zona da Mata',            'Goianá',                'MG'),  -- 8
('SBGV', 'Aeroporto de Governador Valadares',             'Governador Valadares',  'MG'),  -- 9
('SBVG', 'Aeroporto de Varginha',                         'Varginha',              'MG'),  -- 10
('SBPC', 'Aeroporto de Poços de Caldas',                  'Poços de Caldas',       'MG'),  -- 11
('SNDV', 'Aeroporto Brigadeiro Cabral',                   'Divinópolis',           'MG'),  -- 12
('SNPD', 'Aeroporto de Patos de Minas',                   'Patos de Minas',        'MG'),  -- 13
('SBBQ', 'Aeroporto de Barbacena',                        'Barbacena',             'MG'),  -- 14
('SBAX', 'Aeroporto de Araxá',                            'Araxá',                 'MG'),  -- 15
('SBMT', 'Aeroporto Campo de Marte',                      'São Paulo',             'SP'),  -- 16
('SBRP', 'Aeroporto Leite Lopes',                         'Ribeirão Preto',        'SP'),  -- 17
('SBJR', 'Aeroporto de Jacarepaguá',                      'Rio de Janeiro',        'RJ'),  -- 18
('SBRJ', 'Aeroporto Santos Dumont',                       'Rio de Janeiro',        'RJ'),  -- 19
('SBGO', 'Aeroporto de Goiânia',                          'Goiânia',               'GO');  -- 20

-- ---------------------------------------------------------------------
-- pista (21 linhas). SBRJ tem duas pistas; as demais, uma.
-- A situação das pistas é fictícia (pistas sem voos marcadas como
-- interditada ou em_obras).
-- ---------------------------------------------------------------------
INSERT INTO pista (id_aerodromo, designacao, comprimento_m, tipo_piso, situacao) VALUES
(1,  '13/31',   2540, 'asfalto', 'ativa'),
(2,  '16/34',   3600, 'asfalto', 'ativa'),
(3,  '04/22',   2100, 'asfalto', 'ativa'),
(4,  '17/35',   1770, 'asfalto', 'ativa'),
(5,  '12/30',   2100, 'asfalto', 'ativa'),
(6,  '13/31',   2000, 'asfalto', 'ativa'),
(7,  '03/21',   1535, 'asfalto', 'ativa'),
(8,  '03/21',   2525, 'asfalto', 'em_obras'),
(9,  '09/27',   1900, 'asfalto', 'interditada'),
(10, '07/25',   2000, 'asfalto', 'ativa'),
(11, '09/27',   1300, 'asfalto', 'ativa'),
(12, '03/21',   1800, 'asfalto', 'ativa'),
(13, '02/20',   1650, 'asfalto', 'ativa'),
(14, '03/21',   2000, 'asfalto', 'ativa'),
(15, '05/23',   1900, 'asfalto', 'ativa'),
(16, '12/30',   1600, 'asfalto', 'ativa'),
(17, '18/36',   2100, 'asfalto', 'ativa'),
(18, '02/20',    900, 'asfalto', 'ativa'),
(19, '02R/20L', 1323, 'asfalto', 'ativa'),
(19, '02L/20R', 1260, 'asfalto', 'em_obras'),
(20, '14/32',   2500, 'asfalto', 'ativa');

-- ---------------------------------------------------------------------
-- operador (16 linhas): 7 aeroclubes, 5 escolas e 4 particulares
-- (fictícios), 14 deles sediados em Minas Gerais.
-- O aeroclube 7 (Vale do Aço) não tem voos registrados.
-- ---------------------------------------------------------------------
INSERT INTO operador (nome, tipo, cidade, uf) VALUES
('Aeroclube Horizonte Mineiro',          'aeroclube',  'Belo Horizonte',   'MG'),  -- 1  base SBBH
('Aeroclube Vale do Paraibuna',          'aeroclube',  'Juiz de Fora',     'MG'),  -- 2  base SBJF
('Aeroclube Cerrado Mineiro',            'aeroclube',  'Uberlândia',       'MG'),  -- 3  base SBUL
('Aeroclube Asas do Oeste Mineiro',      'aeroclube',  'Divinópolis',      'MG'),  -- 4  base SNDV
('Aeroclube Céu do Sul de Minas',        'aeroclube',  'Varginha',         'MG'),  -- 5  base SBVG
('Aeroclube Serra Geral do Norte',       'aeroclube',  'Montes Claros',    'MG'),  -- 6  base SBMK
('Aeroclube Asas do Vale do Aço',        'aeroclube',  'Ipatinga',         'MG'),  -- 7  base SBIP
('Escola de Aviação Rumo Certo',         'escola',     'Belo Horizonte',   'MG'),  -- 8  base SBBH
('Escola de Aviação Altitude',           'escola',     'Uberaba',          'MG'),  -- 9  base SBUR
('Escola de Aviação Cruzeiro Mineiro',   'escola',     'Juiz de Fora',     'MG'),  -- 10 base SBJF
('Escola de Aviação Mantiqueira Sul',    'escola',     'Poços de Caldas',  'MG'),  -- 11 base SBPC
('Escola de Aviação Planalto Central',   'escola',     'Goiânia',          'GO'),  -- 12 base SBGO
('Agropecuária Santa Helena Ltda.',      'particular', 'Patos de Minas',   'MG'),  -- 13 base SNPD
('Ricardo Albuquerque Nogueira',         'particular', 'Uberlândia',       'MG'),  -- 14 base SBUL
('Construtora Vale Verde Ltda.',         'particular', 'Belo Horizonte',   'MG'),  -- 15 base SBBH
('Helena Duarte Vasconcelos',            'particular', 'Rio de Janeiro',   'RJ');  -- 16 base SBJR

-- ---------------------------------------------------------------------
-- modelo_aeronave (15 linhas): somente monomotores leves.
-- Cessna 182 Skylane e Piper PA-38 Tomahawk ainda sem aeronave cadastrada.
-- ---------------------------------------------------------------------
INSERT INTO modelo_aeronave (fabricante, nome_modelo, numero_assentos, potencia_hp) VALUES
('Cessna',                           '150',               2, 100),
('Cessna',                           '152',               2, 110),
('Cessna',                           '172 Skyhawk',       4, 180),
('Cessna',                           '182 Skylane',       4, 230),
('Piper',                            'PA-18 Super Cub',   2, 150),
('Piper',                            'PA-28-161 Warrior', 4, 160),
('Piper',                            'PA-28-181 Archer',  4, 180),
('Piper',                            'PA-38 Tomahawk',    2, 112),
('Tecnam',                           'P2008 JC',          2, 100),
('Tecnam',                           'P2002 Sierra',      2, 100),
('Companhia Aeronáutica Paulista',   'CAP-4 Paulistinha', 2,  65),
('Neiva',                            'P-56 Paulistinha',  2,  90),
('Aero Boero',                       'AB-115',            3, 115),
('Embraer',                          'EMB-712 Tupi',      4, 180),
('Cirrus',                           'SR20',              4, 200);

-- ---------------------------------------------------------------------
-- aeronave (24 linhas). Matrículas fictícias. O comentário indica a
-- base da aeronave (aeródromo do operador).
-- Sem voos: PP-GVA e PT-IJD (ativas), PT-BRG e PR-ALC (manutencao),
-- PT-AQX (inativa).
-- ---------------------------------------------------------------------
INSERT INTO aeronave (matricula, id_modelo_aeronave, id_operador, ano_fabricacao, situacao) VALUES
('PR-EKA', 3,  1,  2008, 'ativa'),       -- 1  SBBH
('PT-OJB', 3,  1,  1998, 'ativa'),       -- 2  SBBH
('PP-GVA', 2,  1,  1981, 'ativa'),       -- 3  SBBH
('PT-NRS', 2,  2,  1979, 'ativa'),       -- 4  SBJF
('PR-SOB', 6,  2,  2002, 'ativa'),       -- 5  SBJF
('PT-IJD', 12, 3,  1963, 'ativa'),       -- 6  SBUL
('PR-JDA', 3,  3,  2012, 'ativa'),       -- 7  SBUL
('PT-BRG', 13, 4,  1978, 'manutencao'),  -- 8  SNDV
('PT-KQM', 11, 4,  1946, 'ativa'),       -- 9  SNDV
('PR-HBM', 3,  5,  2010, 'ativa'),       -- 10 SBVG
('PT-VZE', 14, 6,  1985, 'ativa'),       -- 11 SBMK
('PR-GNB', 6,  12, 2005, 'ativa'),       -- 12 SBGO
('PT-AQX', 5,  7,  1974, 'inativa'),     -- 13 SBIP
('PR-ARC', 2,  5,  1982, 'ativa'),       -- 14 SBVG
('PS-RCA', 9,  8,  2021, 'ativa'),       -- 15 SBBH
('PR-RCC', 3,  8,  2015, 'ativa'),       -- 16 SBBH
('PS-ALT', 10, 9,  2018, 'ativa'),       -- 17 SBUR
('PR-ALC', 1,  9,  1977, 'manutencao'),  -- 18 SBUR
('PR-CZP', 3,  10, 2011, 'ativa'),       -- 19 SBJF
('PS-VPA', 9,  11, 2022, 'ativa'),       -- 20 SBPC
('PR-SHA', 7,  13, 2016, 'ativa'),       -- 21 SNPD
('PT-RAN', 3,  14, 2000, 'ativa'),       -- 22 SBUL
('PR-VVD', 7,  15, 2019, 'ativa'),       -- 23 SBBH
('PS-HDV', 15, 16, 2020, 'ativa');       -- 24 SBJR

-- ---------------------------------------------------------------------
-- piloto (26 linhas). Nomes e licenças fictícios.
-- 7 instrutores (PC), 10 alunos, demais PP/PC; 2 inativos; 2 sem operador.
-- ---------------------------------------------------------------------
INSERT INTO piloto (nome, numero_licenca, categoria, instrutor, situacao, id_operador) VALUES
('Carlos Eduardo Ramos',          '412305', 'PC',    TRUE,  'ativo',   1),    -- 1
('Juliana Mendes Prado',          '418772', 'PC',    TRUE,  'ativo',   8),    -- 2
('Rafael Augusto Siqueira',       '420118', 'PC',    TRUE,  'ativo',   2),    -- 3
('Marcelo Tavares Lins',          '409841', 'PC',    TRUE,  'ativo',   3),    -- 4
('Patrícia Gomes Arruda',         '425560', 'PC',    TRUE,  'ativo',   5),    -- 5
('André Luiz Fontana',            '416093', 'PC',    TRUE,  'ativo',   9),    -- 6
('Renata Cardoso Vieira',         '429307', 'PC',    TRUE,  'ativo',   11),   -- 7
('Lucas Henrique Moraes',         '451122', 'aluno', FALSE, 'ativo',   1),    -- 8
('Beatriz Oliveira Campos',       '452870', 'aluno', FALSE, 'ativo',   8),    -- 9
('Gabriel Ferreira Nunes',        '453301', 'aluno', FALSE, 'ativo',   8),    -- 10
('Mariana Souza Teixeira',        '454019', 'aluno', FALSE, 'ativo',   2),    -- 11
('Thiago Almeida Rocha',          '455246', 'aluno', FALSE, 'ativo',   3),    -- 12
('Larissa Pereira Duarte',        '456781', 'aluno', FALSE, 'ativo',   5),    -- 13
('Vinícius Barbosa Leal',         '457093', 'aluno', FALSE, 'ativo',   9),    -- 14
('Camila Rezende Furtado',        '458410', 'aluno', FALSE, 'ativo',   11),   -- 15
('Felipe Antunes Correia',        '448215', 'PP',    FALSE, 'ativo',   1),    -- 16 PP em formação para PC
('Roberto Silveira Matos',        '398420', 'PC',    FALSE, 'ativo',   13),   -- 17
('Ricardo Albuquerque Nogueira',  '405562', 'PP',    FALSE, 'ativo',   14),   -- 18
('Helena Duarte Vasconcelos',     '411938', 'PP',    FALSE, 'ativo',   16),   -- 19
('Sérgio Paiva Monteiro',         '387654', 'PC',    FALSE, 'ativo',   NULL), -- 20 piloto autônomo de traslado
('Daniela Couto Ribeiro',         '433018', 'PP',    FALSE, 'ativo',   6),    -- 21
('Gustavo Henrique Lacerda',      '427745', 'PP',    FALSE, 'ativo',   12),   -- 22
('Wagner Lopes Fagundes',         '431590', 'PP',    FALSE, 'ativo',   4),    -- 23
('Paulo Roberto Esteves',         '392207', 'PC',    FALSE, 'ativo',   15),   -- 24
('Otávio Machado Brandão',        '372119', 'PC',    FALSE, 'inativo', 4),    -- 25
('Aline Moreira Santana',         '459902', 'aluno', FALSE, 'inativo', NULL); -- 26

-- ---------------------------------------------------------------------
-- setor_aereo (18 linhas): FIR, TMA, CTR e ATZ, com predominância de
-- setores de Minas Gerais. Sigla no padrão <tipo>-<referência>.
-- Sem travessias: FIR-SBCW, TMA-BR, CTR-SBCF e ATZ-SBGV.
-- ---------------------------------------------------------------------
INSERT INTO setor_aereo (sigla, nome, tipo) VALUES
('FIR-SBBS', 'FIR Brasília',                'FIR'),  -- 1
('FIR-SBCW', 'FIR Curitiba',                'FIR'),  -- 2
('TMA-BH',   'TMA Belo Horizonte',          'TMA'),  -- 3
('TMA-SP',   'TMA São Paulo',               'TMA'),  -- 4
('TMA-RJ',   'TMA Rio de Janeiro',          'TMA'),  -- 5
('TMA-BR',   'TMA Brasília',                'TMA'),  -- 6
('CTR-SBBH', 'CTR Pampulha',                'CTR'),  -- 7
('CTR-SBCF', 'CTR Confins',                 'CTR'),  -- 8
('CTR-SBUL', 'CTR Uberlândia',              'CTR'),  -- 9
('ATZ-SBUR', 'ATZ Uberaba',                 'ATZ'),  -- 10
('ATZ-SBMK', 'ATZ Montes Claros',           'ATZ'),  -- 11
('ATZ-SBJF', 'ATZ Juiz de Fora',            'ATZ'),  -- 12
('ATZ-SBVG', 'ATZ Varginha',                'ATZ'),  -- 13
('ATZ-SBIP', 'ATZ Ipatinga',                'ATZ'),  -- 14
('ATZ-SBGV', 'ATZ Governador Valadares',    'ATZ'),  -- 15
('CTR-SBGO', 'CTR Goiânia',                 'CTR'),  -- 16
('ATZ-SBMT', 'ATZ Campo de Marte',          'ATZ'),  -- 17
('CTR-SBJR', 'CTR Jacarepaguá',             'CTR');  -- 18

-- ---------------------------------------------------------------------
-- voo (39 linhas): 30 realizados, 4 cancelados e 5 previstos.
-- Referências de aeródromo: 1 SBBH, 3 SBUL, 4 SBUR, 5 SBMK, 6 SBIP,
-- 7 SBJF, 10 SBVG, 11 SBPC, 12 SNDV, 13 SNPD, 16 SBMT, 17 SBRP,
-- 18 SBJR, 20 SBGO.
-- ---------------------------------------------------------------------
INSERT INTO voo (id_aeronave, id_aerodromo_origem, id_aerodromo_destino, finalidade,
                 partida_prevista, chegada_prevista, partida_real, chegada_real, situacao) VALUES
-- setembro de 2026
(1,  1,  1,  'instrucao',  '2026-09-02 08:00:00', '2026-09-02 09:00:00', '2026-09-02 08:05:00', '2026-09-02 09:02:00', 'realizado'), -- 1
(4,  7,  7,  'instrucao',  '2026-09-03 08:00:00', '2026-09-03 09:00:00', '2026-09-03 08:02:00', '2026-09-03 08:58:00', 'realizado'), -- 2
(10, 10, 10, 'instrucao',  '2026-09-05 08:00:00', '2026-09-05 09:00:00', '2026-09-05 08:20:00', '2026-09-05 09:15:00', 'realizado'), -- 3
(9,  12, 12, 'passeio',    '2026-09-06 09:00:00', '2026-09-06 09:45:00', '2026-09-06 09:10:00', '2026-09-06 09:50:00', 'realizado'), -- 4
(15, 1,  1,  'instrucao',  '2026-09-08 09:00:00', '2026-09-08 10:00:00', '2026-09-08 09:03:00', '2026-09-08 10:01:00', 'realizado'), -- 5
(16, 1,  7,  'instrucao',  '2026-09-10 08:00:00', '2026-09-10 09:20:00', '2026-09-10 08:40:00', '2026-09-10 10:00:00', 'realizado'), -- 6
(16, 7,  1,  'instrucao',  '2026-09-10 13:00:00', '2026-09-10 14:20:00', '2026-09-10 13:05:00', '2026-09-10 14:22:00', 'realizado'), -- 7
(20, 11, 11, 'instrucao',  '2026-09-11 08:00:00', '2026-09-11 09:00:00', '2026-09-11 08:03:00', '2026-09-11 09:01:00', 'realizado'), -- 8
(24, 18, 7,  'particular', '2026-09-13 10:00:00', '2026-09-13 11:00:00', '2026-09-13 10:00:00', '2026-09-13 11:02:00', 'realizado'), -- 9
(24, 7,  18, 'particular', '2026-09-14 16:00:00', '2026-09-14 17:00:00', '2026-09-14 16:30:00', '2026-09-14 17:32:00', 'realizado'), -- 10
(7,  3,  13, 'instrucao',  '2026-09-17 09:00:00', '2026-09-17 10:10:00', '2026-09-17 09:10:00', '2026-09-17 10:18:00', 'realizado'), -- 11
(7,  13, 3,  'instrucao',  '2026-09-17 13:00:00', '2026-09-17 14:10:00', '2026-09-17 13:00:00', '2026-09-17 14:05:00', 'realizado'), -- 12
(21, 13, 1,  'particular', '2026-09-18 07:00:00', '2026-09-18 08:50:00', '2026-09-18 07:05:00', '2026-09-18 08:52:00', 'realizado'), -- 13
(21, 1,  13, 'particular', '2026-09-18 17:00:00', '2026-09-18 18:50:00', '2026-09-18 17:40:00', '2026-09-18 19:30:00', 'realizado'), -- 14
(19, 7,  1,  'traslado',   '2026-09-25 08:00:00', '2026-09-25 09:20:00', '2026-09-25 08:00:00', '2026-09-25 09:15:00', 'realizado'), -- 15
-- outubro de 2026
(19, 1,  7,  'traslado',   '2026-10-02 13:00:00', '2026-10-02 14:20:00', '2026-10-02 13:20:00', '2026-10-02 14:38:00', 'realizado'), -- 16
(22, 3,  17, 'particular', '2026-10-03 08:00:00', '2026-10-03 09:30:00', '2026-10-03 08:05:00', '2026-10-03 09:33:00', 'realizado'), -- 17
(22, 17, 3,  'particular', '2026-10-05 16:00:00', '2026-10-05 17:30:00', '2026-10-05 16:00:00', '2026-10-05 17:28:00', 'realizado'), -- 18
(16, 1,  5,  'instrucao',  '2026-10-06 07:00:00', '2026-10-06 08:50:00', '2026-10-06 07:05:00', '2026-10-06 09:00:00', 'realizado'), -- 19
(16, 5,  1,  'instrucao',  '2026-10-06 13:00:00', '2026-10-06 14:50:00', '2026-10-06 13:30:00', '2026-10-06 15:25:00', 'realizado'), -- 20
(2,  1,  1,  'instrucao',  '2026-10-09 09:00:00', '2026-10-09 10:00:00', NULL,                  NULL,                  'cancelado'), -- 21
(23, 1,  16, 'particular', '2026-10-12 08:00:00', '2026-10-12 10:20:00', '2026-10-12 08:10:00', '2026-10-12 10:32:00', 'realizado'), -- 22
(23, 16, 1,  'particular', '2026-10-14 15:00:00', '2026-10-14 17:20:00', '2026-10-14 15:05:00', '2026-10-14 17:22:00', 'realizado'), -- 23
(12, 20, 3,  'traslado',   '2026-10-15 08:00:00', '2026-10-15 09:40:00', '2026-10-15 08:00:00', '2026-10-15 09:42:00', 'realizado'), -- 24
(12, 3,  20, 'traslado',   '2026-10-16 14:00:00', '2026-10-16 15:40:00', '2026-10-16 14:10:00', '2026-10-16 15:45:00', 'realizado'), -- 25
(17, 4,  4,  'instrucao',  '2026-10-19 09:00:00', '2026-10-19 10:00:00', '2026-10-19 09:00:00', '2026-10-19 09:58:00', 'realizado'), -- 26
(1,  1,  1,  'instrucao',  '2026-10-20 08:00:00', '2026-10-20 09:00:00', '2026-10-20 08:05:00', '2026-10-20 09:00:00', 'realizado'), -- 27
(5,  7,  18, 'instrucao',  '2026-10-22 08:00:00', '2026-10-22 09:10:00', '2026-10-22 08:10:00', '2026-10-22 09:22:00', 'realizado'), -- 28
(5,  18, 7,  'instrucao',  '2026-10-22 14:00:00', '2026-10-22 15:10:00', '2026-10-22 14:05:00', '2026-10-22 16:05:00', 'realizado'), -- 29
(14, 10, 10, 'instrucao',  '2026-10-23 08:00:00', '2026-10-23 09:00:00', NULL,                  NULL,                  'cancelado'), -- 30
(11, 5,  5,  'passeio',    '2026-10-25 09:00:00', '2026-10-25 09:50:00', NULL,                  NULL,                  'cancelado'), -- 31
(2,  1,  6,  'instrucao',  '2026-10-27 07:30:00', '2026-10-27 08:40:00', '2026-10-27 07:30:00', '2026-10-27 08:45:00', 'realizado'), -- 32
(2,  6,  1,  'instrucao',  '2026-10-27 11:00:00', '2026-10-27 12:10:00', '2026-10-27 11:05:00', '2026-10-27 12:18:00', 'realizado'), -- 33
-- novembro de 2026
(22, 3,  17, 'particular', '2026-11-07 10:00:00', '2026-11-07 11:30:00', NULL,                  NULL,                  'cancelado'), -- 34
(1,  1,  1,  'instrucao',  '2026-11-18 08:00:00', '2026-11-18 09:00:00', NULL,                  NULL,                  'previsto'),  -- 35
(15, 1,  1,  'instrucao',  '2026-11-19 09:00:00', '2026-11-19 10:00:00', NULL,                  NULL,                  'previsto'),  -- 36
(21, 13, 1,  'particular', '2026-11-20 07:00:00', '2026-11-20 08:50:00', NULL,                  NULL,                  'previsto'),  -- 37
(7,  3,  3,  'instrucao',  '2026-11-21 07:00:00', '2026-11-21 08:00:00', NULL,                  NULL,                  'previsto'),  -- 38
(16, 1,  1,  'passeio',    '2026-11-22 08:00:00', '2026-11-22 08:50:00', NULL,                  NULL,                  'previsto');  -- 39

-- ---------------------------------------------------------------------
-- voo_piloto (63 linhas). Instrução: instrutor + aluno.
-- Demais finalidades: comandante e, em dois voos, copiloto.
-- ---------------------------------------------------------------------
INSERT INTO voo_piloto (id_voo, id_piloto, funcao) VALUES
(1,  1,  'instrutor'),  (1,  8,  'aluno'),
(2,  3,  'instrutor'),  (2,  11, 'aluno'),
(3,  5,  'instrutor'),  (3,  13, 'aluno'),
(4,  23, 'comandante'),
(5,  2,  'instrutor'),  (5,  9,  'aluno'),
(6,  2,  'instrutor'),  (6,  10, 'aluno'),
(7,  2,  'instrutor'),  (7,  10, 'aluno'),
(8,  7,  'instrutor'),  (8,  15, 'aluno'),
(9,  19, 'comandante'),
(10, 19, 'comandante'),
(11, 4,  'instrutor'),  (11, 12, 'aluno'),
(12, 4,  'instrutor'),  (12, 12, 'aluno'),
(13, 17, 'comandante'),
(14, 17, 'comandante'),
(15, 20, 'comandante'),
(16, 20, 'comandante'),
(17, 18, 'comandante'),
(18, 18, 'comandante'), (18, 20, 'copiloto'),
(19, 2,  'instrutor'),  (19, 10, 'aluno'),
(20, 2,  'instrutor'),  (20, 10, 'aluno'),
(21, 1,  'instrutor'),  (21, 8,  'aluno'),
(22, 24, 'comandante'), (22, 20, 'copiloto'),
(23, 24, 'comandante'),
(24, 22, 'comandante'),
(25, 22, 'comandante'),
(26, 6,  'instrutor'),  (26, 14, 'aluno'),
(27, 1,  'instrutor'),  (27, 8,  'aluno'),
(28, 3,  'instrutor'),  (28, 11, 'aluno'),
(29, 3,  'instrutor'),  (29, 11, 'aluno'),
(30, 5,  'instrutor'),  (30, 13, 'aluno'),
(31, 21, 'comandante'),
(32, 1,  'instrutor'),  (32, 16, 'aluno'),
(33, 1,  'instrutor'),  (33, 16, 'aluno'),
(34, 18, 'comandante'),
(35, 1,  'instrutor'),  (35, 8,  'aluno'),
(36, 2,  'instrutor'),  (36, 9,  'aluno'),
(37, 17, 'comandante'),
(38, 4,  'instrutor'),  (38, 12, 'aluno'),
(39, 2,  'comandante');

-- ---------------------------------------------------------------------
-- voo_setor (83 linhas). Somente voos realizados; horários dentro do
-- intervalo real do voo e em ordem cronológica.
-- Setores: 1 FIR-SBBS, 3 TMA-BH, 4 TMA-SP, 5 TMA-RJ,
-- 7 CTR-SBBH, 9 CTR-SBUL, 10 ATZ-SBUR, 11 ATZ-SBMK, 12 ATZ-SBJF,
-- 13 ATZ-SBVG, 14 ATZ-SBIP, 16 CTR-SBGO, 17 ATZ-SBMT, 18 CTR-SBJR.
-- Voos locais em aeródromos sem órgão de controle (SNDV, SBPC) ficam
-- registrados apenas na FIR.
-- ---------------------------------------------------------------------
INSERT INTO voo_setor (id_voo, id_setor_aereo, ordem_travessia, horario_entrada, horario_saida) VALUES
(1,  7,  1, '2026-09-02 08:06:00', '2026-09-02 09:00:00'),
(2,  12, 1, '2026-09-03 08:03:00', '2026-09-03 08:57:00'),
(3,  13, 1, '2026-09-05 08:21:00', '2026-09-05 09:14:00'),
(4,  1,  1, '2026-09-06 09:11:00', '2026-09-06 09:49:00'),
(5,  7,  1, '2026-09-08 09:04:00', '2026-09-08 10:00:00'),
(6,  7,  1, '2026-09-10 08:40:00', '2026-09-10 08:46:00'),
(6,  3,  2, '2026-09-10 08:46:00', '2026-09-10 09:10:00'),
(6,  1,  3, '2026-09-10 09:10:00', '2026-09-10 09:52:00'),
(6,  12, 4, '2026-09-10 09:52:00', '2026-09-10 10:00:00'),
(7,  12, 1, '2026-09-10 13:05:00', '2026-09-10 13:12:00'),
(7,  1,  2, '2026-09-10 13:12:00', '2026-09-10 13:55:00'),
(7,  3,  3, '2026-09-10 13:55:00', '2026-09-10 14:15:00'),
(7,  7,  4, '2026-09-10 14:15:00', '2026-09-10 14:22:00'),
(8,  1,  1, '2026-09-11 08:05:00', '2026-09-11 08:58:00'),
(9,  18, 1, '2026-09-13 10:01:00', '2026-09-13 10:07:00'),
(9,  5,  2, '2026-09-13 10:07:00', '2026-09-13 10:30:00'),
(9,  1,  3, '2026-09-13 10:30:00', '2026-09-13 10:54:00'),
(9,  12, 4, '2026-09-13 10:54:00', '2026-09-13 11:02:00'),
(10, 12, 1, '2026-09-14 16:30:00', '2026-09-14 16:36:00'),
(10, 1,  2, '2026-09-14 16:36:00', '2026-09-14 17:00:00'),
(10, 5,  3, '2026-09-14 17:00:00', '2026-09-14 17:25:00'),
(10, 18, 4, '2026-09-14 17:25:00', '2026-09-14 17:32:00'),
(11, 9,  1, '2026-09-17 09:10:00', '2026-09-17 09:18:00'),
(11, 1,  2, '2026-09-17 09:18:00', '2026-09-17 10:18:00'),
(12, 1,  1, '2026-09-17 13:01:00', '2026-09-17 13:57:00'),
(12, 9,  2, '2026-09-17 13:57:00', '2026-09-17 14:05:00'),
(13, 1,  1, '2026-09-18 07:08:00', '2026-09-18 08:20:00'),
(13, 3,  2, '2026-09-18 08:20:00', '2026-09-18 08:45:00'),
(13, 7,  3, '2026-09-18 08:45:00', '2026-09-18 08:52:00'),
(14, 7,  1, '2026-09-18 17:40:00', '2026-09-18 17:46:00'),
(14, 3,  2, '2026-09-18 17:46:00', '2026-09-18 18:15:00'),
(14, 1,  3, '2026-09-18 18:15:00', '2026-09-18 19:30:00'),
(15, 12, 1, '2026-09-25 08:01:00', '2026-09-25 08:08:00'),
(15, 1,  2, '2026-09-25 08:08:00', '2026-09-25 08:50:00'),
(15, 3,  3, '2026-09-25 08:50:00', '2026-09-25 09:08:00'),
(15, 7,  4, '2026-09-25 09:08:00', '2026-09-25 09:15:00'),
(16, 7,  1, '2026-10-02 13:21:00', '2026-10-02 13:27:00'),
(16, 3,  2, '2026-10-02 13:27:00', '2026-10-02 13:50:00'),
(16, 1,  3, '2026-10-02 13:50:00', '2026-10-02 14:30:00'),
(16, 12, 4, '2026-10-02 14:30:00', '2026-10-02 14:38:00'),
(17, 9,  1, '2026-10-03 08:05:00', '2026-10-03 08:12:00'),
(17, 1,  2, '2026-10-03 08:12:00', '2026-10-03 09:33:00'),
(18, 1,  1, '2026-10-05 16:02:00', '2026-10-05 17:20:00'),
(18, 9,  2, '2026-10-05 17:20:00', '2026-10-05 17:28:00'),
(19, 7,  1, '2026-10-06 07:05:00', '2026-10-06 07:12:00'),
(19, 3,  2, '2026-10-06 07:12:00', '2026-10-06 07:40:00'),
(19, 1,  3, '2026-10-06 07:40:00', '2026-10-06 08:52:00'),
(19, 11, 4, '2026-10-06 08:52:00', '2026-10-06 09:00:00'),
(20, 11, 1, '2026-10-06 13:30:00', '2026-10-06 13:37:00'),
(20, 1,  2, '2026-10-06 13:37:00', '2026-10-06 14:50:00'),
(20, 3,  3, '2026-10-06 14:50:00', '2026-10-06 15:18:00'),
(20, 7,  4, '2026-10-06 15:18:00', '2026-10-06 15:25:00'),
(22, 7,  1, '2026-10-12 08:10:00', '2026-10-12 08:16:00'),
(22, 3,  2, '2026-10-12 08:16:00', '2026-10-12 08:45:00'),
(22, 1,  3, '2026-10-12 08:45:00', '2026-10-12 10:00:00'),
(22, 4,  4, '2026-10-12 10:00:00', '2026-10-12 10:32:00'),
(23, 17, 1, '2026-10-14 15:05:00', '2026-10-14 15:11:00'),
(23, 4,  2, '2026-10-14 15:11:00', '2026-10-14 15:40:00'),
(23, 1,  3, '2026-10-14 15:40:00', '2026-10-14 16:55:00'),
(23, 3,  4, '2026-10-14 16:55:00', '2026-10-14 17:15:00'),
(23, 7,  5, '2026-10-14 17:15:00', '2026-10-14 17:22:00'),
(24, 16, 1, '2026-10-15 08:01:00', '2026-10-15 08:10:00'),
(24, 1,  2, '2026-10-15 08:10:00', '2026-10-15 09:34:00'),
(24, 9,  3, '2026-10-15 09:34:00', '2026-10-15 09:42:00'),
(25, 9,  1, '2026-10-16 14:10:00', '2026-10-16 14:17:00'),
(25, 1,  2, '2026-10-16 14:17:00', '2026-10-16 15:37:00'),
(25, 16, 3, '2026-10-16 15:37:00', '2026-10-16 15:45:00'),
(26, 10, 1, '2026-10-19 09:01:00', '2026-10-19 09:57:00'),
(27, 7,  1, '2026-10-20 08:06:00', '2026-10-20 08:59:00'),
(28, 12, 1, '2026-10-22 08:10:00', '2026-10-22 08:16:00'),
(28, 1,  2, '2026-10-22 08:16:00', '2026-10-22 08:50:00'),
(28, 5,  3, '2026-10-22 08:50:00', '2026-10-22 09:15:00'),
(28, 18, 4, '2026-10-22 09:15:00', '2026-10-22 09:22:00'),
(29, 18, 1, '2026-10-22 14:05:00', '2026-10-22 14:11:00'),
(29, 5,  2, '2026-10-22 14:11:00', '2026-10-22 14:35:00'),
(29, 1,  3, '2026-10-22 14:35:00', '2026-10-22 15:58:00'),
(29, 12, 4, '2026-10-22 15:58:00', '2026-10-22 16:05:00'),
(32, 7,  1, '2026-10-27 07:30:00', '2026-10-27 07:36:00'),
(32, 3,  2, '2026-10-27 07:36:00', '2026-10-27 08:30:00'),
(32, 14, 3, '2026-10-27 08:30:00', '2026-10-27 08:45:00'),
(33, 14, 1, '2026-10-27 11:05:00', '2026-10-27 11:15:00'),
(33, 3,  2, '2026-10-27 11:15:00', '2026-10-27 12:10:00'),
(33, 7,  3, '2026-10-27 12:10:00', '2026-10-27 12:18:00');

-- ---------------------------------------------------------------------
-- ocorrencia (18 linhas) concentradas em 13 voos.
-- Todo voo cancelado tem uma ocorrência do tipo cancelamento.
-- ---------------------------------------------------------------------
INSERT INTO ocorrencia (id_voo, tipo, gravidade, descricao, data_hora, minutos_atraso) VALUES
(3,  'atraso',                 'baixa', 'Abastecimento atrasado: caminhão de combustível em atendimento a outra aeronave', '2026-09-05 08:10:00', 20),
(6,  'condicao_meteorologica', 'baixa', 'Nevoeiro na Pampulha; decolagem aguardou visibilidade mínima para voo VFR', '2026-09-10 08:00:00', 40),
(10, 'condicao_meteorologica', 'baixa', 'Teto baixo sobre a Serra do Mar; saída aguardou melhora das condições na rota', '2026-09-14 16:00:00', 30),
(14, 'condicao_meteorologica', 'media', 'Trovoadas na TMA Belo Horizonte; decolagem adiada por orientação do controle', '2026-09-18 17:10:00', 40),
(14, 'desvio',                 'baixa', 'Desvio a oeste da rota planejada para contornar formação convectiva', '2026-09-18 18:30:00', 0),
(15, 'desvio',                 'baixa', 'Desvio de rota solicitado pelo controle para separação de tráfego na TMA Belo Horizonte', '2026-09-25 08:55:00', 0),
(16, 'atraso',                 'baixa', 'Liberação da aeronave atrasada pela conferência da documentação de manutenção', '2026-10-02 13:05:00', 20),
(19, 'falha_tecnica',          'alta',  'Oscilação na indicação de pressão do óleo em voo; prosseguimento ao destino com monitoramento e inspeção após o pouso', '2026-10-06 08:15:00', 0),
(20, 'atraso',                 'baixa', 'Retorno liberado somente após a conclusão da inspeção do sistema de óleo', '2026-10-06 13:00:00', 30),
(21, 'cancelamento',           'baixa', 'Voo cancelado por teto abaixo dos mínimos VFR na Pampulha', '2026-10-09 07:30:00', 0),
(29, 'condicao_meteorologica', 'media', 'Chuva moderada e visibilidade reduzida na rota sobre a serra', '2026-10-22 14:40:00', 0),
(29, 'pouso_alternativo',      'media', 'Pouso preventivo no Aeroporto Regional da Zona da Mata; prosseguimento após melhora do tempo', '2026-10-22 14:50:00', 0),
(29, 'atraso',                 'baixa', 'Chegada a Juiz de Fora com atraso em razão da parada no aeródromo alternativo', '2026-10-22 16:05:00', 55),
(30, 'falha_tecnica',          'media', 'Rádio VHF inoperante no teste realizado antes do acionamento do motor', '2026-10-23 07:35:00', 0),
(30, 'cancelamento',           'baixa', 'Voo cancelado até o reparo do rádio VHF', '2026-10-23 07:45:00', 0),
(31, 'condicao_meteorologica', 'baixa', 'Previsão de chuva forte e teto baixo em Montes Claros para a manhã do voo', '2026-10-24 17:50:00', 0),
(31, 'cancelamento',           'baixa', 'Voo cancelado pelo comandante em razão da previsão meteorológica', '2026-10-24 18:00:00', 0),
(34, 'cancelamento',           'baixa', 'Voo cancelado pelo proprietário por mudança de agenda', '2026-11-07 08:30:00', 0);

-- ---------------------------------------------------------------------
-- plano_voo (24 linhas): no máximo um plano por voo; 3 IFR, demais VFR.
-- pessoas_a_bordo não excede os assentos do modelo da aeronave.
-- ---------------------------------------------------------------------
INSERT INTO plano_voo (id_voo, regra_voo, altitude_cruzeiro_pes, velocidade_cruzeiro_kt, autonomia_min, pessoas_a_bordo) VALUES
(6,  'VFR', 5500, 110, 240, 2),
(7,  'VFR', 4500, 110, 240, 2),
(9,  'VFR', 6500, 150, 300, 3),
(10, 'VFR', 6500, 150, 300, 2),
(11, 'VFR', 5500, 110, 240, 2),
(12, 'VFR', 6500, 110, 240, 2),
(13, 'IFR', 7000, 125, 300, 3),
(14, 'IFR', 7000, 125, 300, 2),
(15, 'VFR', 6500, 110, 240, 1),
(16, 'VFR', 5500, 110, 240, 1),
(17, 'VFR', 6500, 110, 280, 2),
(18, 'VFR', 5500, 110, 280, 2),
(19, 'VFR', 7500, 110, 270, 2),
(20, 'VFR', 6500, 110, 270, 2),
(22, 'IFR', 8000, 125, 330, 4),
(23, 'VFR', 7500, 125, 330, 3),
(24, 'VFR', 6500, 105, 300, 1),
(25, 'VFR', 7500, 105, 300, 1),
(28, 'VFR', 5500, 105, 240, 2),
(29, 'VFR', 5500, 105, 240, 2),
(32, 'VFR', 5500, 110, 240, 2),
(33, 'VFR', 6500, 110, 240, 2),
(34, 'VFR', 6500, 110, 280, 2),
(37, 'VFR', 6500, 125, 300, 2);
