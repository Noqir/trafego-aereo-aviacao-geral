# Dicionário de dados

Banco de dados `trafego_aereo`, MySQL 8.0.16 ou superior, motor InnoDB, charset utf8mb4. Todas as chaves primárias são `INT AUTO_INCREMENT`. Todas as chaves estrangeiras declaram `ON UPDATE CASCADE`; a ação `ON DELETE` de cada uma está indicada na coluna de restrições. Abreviações: PK (chave primária), FK (chave estrangeira), NN (NOT NULL), UQ (UNIQUE), CK (CHECK), DF (DEFAULT). O banco tem 10 restrições CHECK; nas colunas marcadas "sem CHECK", os valores aceitos são regra de negócio respeitada na massa de dados, sem restrição declarada no DDL.

## Tabela 1 – `aerodromo`

Aeródromos brasileiros (públicos ou privados) onde os voos partem ou pousam.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_aerodromo` | INT | PK, AUTO_INCREMENT | Identificador do aeródromo |
| `codigo_icao` | CHAR(4) | NN, UQ | Código ICAO de quatro letras (ex.: SBBH) |
| `nome` | VARCHAR(120) | NN | Nome oficial do aeródromo |
| `cidade` | VARCHAR(80) | NN | Município onde o aeródromo está localizado |
| `uf` | CHAR(2) | NN | Sigla da unidade da federação |
| `tipo` | VARCHAR(10) | NN, DF 'publico', valores aceitos (sem CHECK): 'publico', 'privado' | Classificação de uso do aeródromo |

Fonte: elaborado pelos autores.

## Tabela 2 – `pista`

Pistas de pouso e decolagem de cada aeródromo.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_pista` | INT | PK, AUTO_INCREMENT | Identificador da pista |
| `id_aerodromo` | INT | NN, FK `aerodromo` (ON DELETE CASCADE) | Aeródromo ao qual a pista pertence |
| `designacao` | VARCHAR(7) | NN, UQ composto com `id_aerodromo` | Designação das cabeceiras (ex.: 09/27) |
| `comprimento_m` | INT | NN, CK > 0 | Comprimento da pista em metros |
| `tipo_piso` | VARCHAR(10) | NN, valores aceitos (sem CHECK): 'asfalto', 'concreto', 'grama', 'terra', 'cascalho' | Tipo de revestimento da pista |
| `situacao` | VARCHAR(12) | NN, DF 'ativa', valores aceitos (sem CHECK): 'ativa', 'interditada', 'em_obras' | Situação operacional atual da pista |

Fonte: elaborado pelos autores.

## Tabela 3 – `operador`

Entidades responsáveis pelas aeronaves e às quais os pilotos se vinculam: aeroclubes, escolas de aviação e proprietários particulares.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_operador` | INT | PK, AUTO_INCREMENT | Identificador do operador |
| `nome` | VARCHAR(120) | NN, UQ | Nome do aeroclube, da escola ou do proprietário |
| `tipo` | VARCHAR(12) | NN, valores aceitos (sem CHECK): 'aeroclube', 'escola', 'particular' | Natureza do operador |
| `cidade` | VARCHAR(80) | NN | Município sede do operador |
| `uf` | CHAR(2) | NN | Sigla da unidade da federação |

Fonte: elaborado pelos autores.

## Tabela 4 – `modelo_aeronave`

Catálogo de modelos de aeronaves leves monomotoras. Resulta da decomposição para a 3FN (ver `docs/modelagem.md`, seção 7.2).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_modelo_aeronave` | INT | PK, AUTO_INCREMENT | Identificador do modelo |
| `fabricante` | VARCHAR(60) | NN, UQ composto com `nome_modelo` | Fabricante da aeronave (ex.: Cessna, Piper, Tecnam) |
| `nome_modelo` | VARCHAR(60) | NN | Designação do modelo (ex.: 172 Skyhawk) |
| `numero_assentos` | TINYINT | NN, CK BETWEEN 1 AND 6 | Quantidade de assentos, incluindo o do piloto |
| `potencia_hp` | SMALLINT | NN, valor positivo (sem CHECK) | Potência do motor em cavalos (hp) |

Fonte: elaborado pelos autores.

## Tabela 5 – `aeronave`

Aeronaves individuais, identificadas pela matrícula do Registro Aeronáutico Brasileiro.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_aeronave` | INT | PK, AUTO_INCREMENT | Identificador da aeronave |
| `matricula` | VARCHAR(6) | NN, UQ | Matrícula da aeronave (ex.: PR-EKA) |
| `id_modelo_aeronave` | INT | NN, FK `modelo_aeronave` (ON DELETE RESTRICT) | Modelo da aeronave |
| `id_operador` | INT | NN, FK `operador` (ON DELETE RESTRICT) | Operador responsável pela aeronave |
| `ano_fabricacao` | SMALLINT | NN, a partir de 1940 (sem CHECK) | Ano de fabricação da unidade |
| `situacao` | VARCHAR(12) | NN, DF 'ativa', valores aceitos (sem CHECK): 'ativa', 'manutencao', 'inativa' | Situação de disponibilidade da aeronave |

Fonte: elaborado pelos autores.

## Tabela 6 – `piloto`

Pilotos, alunos e instrutores que atuam nos voos.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_piloto` | INT | PK, AUTO_INCREMENT | Identificador do piloto |
| `nome` | VARCHAR(120) | NN | Nome completo (fictício) |
| `numero_licenca` | VARCHAR(10) | NN, UQ | Número de licença ou código de cadastro (fictício) |
| `categoria` | VARCHAR(6) | NN, valores aceitos (sem CHECK): 'aluno', 'PP', 'PC' | Categoria: aluno piloto, piloto privado ou piloto comercial |
| `instrutor` | BOOLEAN | NN, DF FALSE | Indica se possui habilitação de instrutor de voo |
| `situacao` | VARCHAR(8) | NN, DF 'ativo', valores aceitos (sem CHECK): 'ativo', 'inativo' | Situação do piloto no cadastro |
| `id_operador` | INT | NULL, FK `operador` (ON DELETE SET NULL) | Aeroclube ou escola ao qual o piloto está vinculado; NULL se não houver vínculo |

Fonte: elaborado pelos autores.

## Tabela 7 – `setor_aereo`

Setores do espaço aéreo brasileiro atravessados pelos voos.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_setor_aereo` | INT | PK, AUTO_INCREMENT | Identificador do setor |
| `sigla` | VARCHAR(20) | NN, UQ | Sigla do setor (ex.: TMA-BH) |
| `nome` | VARCHAR(120) | NN | Nome por extenso do setor |
| `tipo` | CHAR(3) | NN, valores aceitos (sem CHECK): 'FIR', 'TMA', 'CTR', 'ATZ' | Tipo de espaço aéreo: região de informação de voo, área de controle terminal, zona de controle ou zona de tráfego de aeródromo |

Fonte: elaborado pelos autores.

## Tabela 8 – `voo`

Operação aérea de uma aeronave, com horários previstos e realizados. Origem e destino podem coincidir (circuito de tráfego).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_voo` | INT | PK, AUTO_INCREMENT | Identificador do voo |
| `id_aeronave` | INT | NN, FK `aeronave` (ON DELETE RESTRICT) | Aeronave que executa o voo |
| `id_aerodromo_origem` | INT | NN, FK `aerodromo` (ON DELETE RESTRICT) | Aeródromo de partida |
| `id_aerodromo_destino` | INT | NN, FK `aerodromo` (ON DELETE RESTRICT) | Aeródromo de destino |
| `finalidade` | VARCHAR(10) | NN, CK IN ('instrucao', 'passeio', 'particular', 'traslado') | Finalidade da operação |
| `partida_prevista` | DATETIME | NN, UQ composto com `id_aeronave` | Data e hora previstas de partida |
| `chegada_prevista` | DATETIME | NN, CK `chegada_prevista > partida_prevista` | Data e hora previstas de chegada |
| `partida_real` | DATETIME | NULL | Data e hora reais de partida; NULL se o voo não ocorreu |
| `chegada_real` | DATETIME | NULL, CK `chegada_real > partida_real` quando ambas preenchidas | Data e hora reais de chegada; NULL se o voo não ocorreu |
| `situacao` | VARCHAR(10) | NN, DF 'previsto', CK IN ('previsto', 'realizado', 'cancelado') | Situação do voo |

Fonte: elaborado pelos autores.

## Tabela 9 – `voo_piloto`

Tabela associativa do relacionamento N:N entre voo e piloto.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_voo_piloto` | INT | PK, AUTO_INCREMENT | Identificador da participação |
| `id_voo` | INT | NN, FK `voo` (ON DELETE CASCADE), UQ composto com `id_piloto` | Voo em que o piloto atuou |
| `id_piloto` | INT | NN, FK `piloto` (ON DELETE RESTRICT) | Piloto participante |
| `funcao` | VARCHAR(10) | NN, CK IN ('comandante', 'instrutor', 'aluno', 'copiloto') | Função exercida a bordo nesse voo |

Fonte: elaborado pelos autores.

## Tabela 10 – `voo_setor`

Tabela associativa do relacionamento N:N entre voo e setor aéreo, com os horários de cada travessia.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_voo_setor` | INT | PK, AUTO_INCREMENT | Identificador da travessia |
| `id_voo` | INT | NN, FK `voo` (ON DELETE CASCADE), UQ composto com `id_setor_aereo`, UQ composto com `ordem_travessia` | Voo que atravessou o setor |
| `id_setor_aereo` | INT | NN, FK `setor_aereo` (ON DELETE RESTRICT) | Setor atravessado |
| `ordem_travessia` | TINYINT | NN, a partir de 1 (sem CHECK) | Posição do setor na sequência do voo |
| `horario_entrada` | DATETIME | NN | Data e hora de entrada no setor |
| `horario_saida` | DATETIME | NN, CK `horario_saida > horario_entrada` | Data e hora de saída do setor |

Fonte: elaborado pelos autores.

## Tabela 11 – `ocorrencia`

Eventos registrados durante a preparação ou a execução de um voo.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_ocorrencia` | INT | PK, AUTO_INCREMENT | Identificador da ocorrência |
| `id_voo` | INT | NN, FK `voo` (ON DELETE RESTRICT) | Voo ao qual a ocorrência se refere |
| `tipo` | VARCHAR(25) | NN, valores aceitos (sem CHECK): 'atraso', 'cancelamento', 'desvio', 'falha_tecnica', 'condicao_meteorologica', 'pouso_alternativo' | Tipo da ocorrência |
| `gravidade` | VARCHAR(5) | NN, DF 'baixa', valores aceitos (sem CHECK): 'baixa', 'media', 'alta' | Grau de gravidade |
| `descricao` | VARCHAR(255) | NN | Relato resumido do ocorrido |
| `data_hora` | DATETIME | NN | Data e hora do registro da ocorrência |
| `minutos_atraso` | SMALLINT | NN, DF 0, CK >= 0 | Atraso atribuído a essa ocorrência, em minutos |

Fonte: elaborado pelos autores.

## Tabela 12 – `plano_voo`

Plano de voo apresentado para um voo. Relacionamento 1:1 com `voo`.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id_plano_voo` | INT | PK, AUTO_INCREMENT | Identificador do plano |
| `id_voo` | INT | NN, UQ, FK `voo` (ON DELETE CASCADE) | Voo a que o plano se refere (no máximo um plano por voo) |
| `regra_voo` | CHAR(3) | NN, DF 'VFR', CK IN ('VFR', 'IFR') | Regras de voo: visual ou por instrumentos |
| `altitude_cruzeiro_pes` | SMALLINT | NN, entre 4.500 e 8.000 pés nos dados (sem CHECK) | Altitude de cruzeiro planejada, em pés |
| `velocidade_cruzeiro_kt` | SMALLINT | NN, valor positivo (sem CHECK) | Velocidade de cruzeiro planejada, em nós |
| `autonomia_min` | SMALLINT | NN, valor positivo (sem CHECK) | Autonomia de combustível declarada, em minutos |
| `pessoas_a_bordo` | TINYINT | NN, a partir de 1 (sem CHECK) | Número de pessoas a bordo declarado |

Fonte: elaborado pelos autores.
