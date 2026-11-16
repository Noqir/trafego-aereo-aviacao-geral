# Saídas reais das consultas

Este documento registra a saída real de cada consulta de `sql/02_consultas.sql`, obtida em 16/11/2026 após carregar `sql/01_banco.sql` do zero em MySQL 8.0.46 (contêiner Docker). Os valores foram copiados da execução, sem edição. Quando uma consulta retorna mais de 15 linhas, são mostradas as 10 primeiras e informado o total.

Convenção usada nas consultas de atraso: o atraso de partida de um voo realizado é a diferença, em minutos, entre `partida_real` e `partida_prevista`, calculada com `TIMESTAMPDIFF(MINUTE, inicio, fim)`. A duração de um voo é a diferença entre `chegada_real` e `partida_real`.

## Resumo

| Consulta | Categoria | Tabelas | Linhas retornadas |
|---|---|---|---|
| Q1 | Simples | voo | 15 |
| Q2 | Simples | aerodromo | 5 |
| Q3 | Simples | modelo_aeronave | 8 |
| Q4 | Simples | operador | 7 |
| Q5 | Simples | ocorrencia | 5 |
| Q6 | JOIN, 2 tabelas | aerodromo, voo | 7 |
| Q7 | JOIN, 3 tabelas | voo, aeronave, operador | 14 |
| Q8 | JOIN, 3 tabelas | aeronave, modelo_aeronave, voo | 17 |
| Q9 | JOIN, 3 tabelas | piloto, voo_piloto, voo | 6 |
| Q10 | JOIN, 2 tabelas | setor_aereo, voo_setor | 7 |
| Q11 | Subconsulta (com JOIN de 3 tabelas) | voo, aeronave, operador | 6 |
| Q12 | LEFT JOIN | aeronave, operador, voo | 5 |

## Cobertura dos recursos exigidos

| Recurso | Q1 | Q2 | Q3 | Q4 | Q5 | Q6 | Q7 | Q8 | Q9 | Q10 | Q11 | Q12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SELECT | X | X | X | X | X | X | X | X | X | X | X | X |
| WHERE | X | X |  | X |  |  | X | X | X |  | X | X |
| ORDER BY | X | X | X | X | X | X | X | X | X | X | X | X |
| LIKE |  |  |  | X |  |  |  |  |  |  |  |  |
| BETWEEN | X |  |  |  |  |  |  |  |  |  |  |  |
| IN |  | X |  |  |  |  |  |  |  |  |  |  |
| DISTINCT |  |  | X |  |  |  |  |  |  |  |  |  |
| LIMIT |  |  |  |  | X |  |  |  |  |  |  |  |
| INNER JOIN (2 tabelas) |  |  |  |  |  | X |  |  |  | X |  |  |
| INNER JOIN (3 tabelas) |  |  |  |  |  |  | X | X | X |  | X |  |
| GROUP BY |  |  |  |  |  | X | X | X | X | X | X |  |
| HAVING |  |  |  |  |  | X |  |  | X | X | X |  |
| COUNT |  |  |  |  |  | X | X | X | X | X |  |  |
| SUM |  |  |  |  |  |  |  | X | X |  |  |  |
| AVG |  |  |  |  |  |  | X |  |  | X | X |  |
| MAX |  |  |  |  |  |  | X | X |  |  |  |  |
| MIN |  |  |  |  |  |  |  | X |  |  |  |  |
| Subconsulta |  |  |  |  |  |  |  |  |  |  | X |  |
| LEFT JOIN |  |  |  |  |  |  |  |  |  |  |  | X |

## Q1. Voos realizados em outubro de 2026

**Descrição:** lista os voos realizados com partida prevista entre 01/10/2026 e 31/10/2026, com finalidade e horários previstos e reais, em ordem cronológica.

**Recursos:** SELECT, WHERE, BETWEEN, ORDER BY.

```sql
SELECT id_voo,
       finalidade,
       partida_prevista,
       partida_real,
       chegada_real
FROM voo
WHERE situacao = 'realizado'
  AND partida_prevista BETWEEN '2026-10-01 00:00:00' AND '2026-10-31 23:59:59'
ORDER BY partida_prevista;
```

**Saída (15 linhas):**

| id_voo | finalidade | partida_prevista | partida_real | chegada_real |
| --- | --- | --- | --- | --- |
| 16 | traslado | 2026-10-02 13:00:00 | 2026-10-02 13:20:00 | 2026-10-02 14:38:00 |
| 17 | particular | 2026-10-03 08:00:00 | 2026-10-03 08:05:00 | 2026-10-03 09:33:00 |
| 18 | particular | 2026-10-05 16:00:00 | 2026-10-05 16:00:00 | 2026-10-05 17:28:00 |
| 19 | instrucao | 2026-10-06 07:00:00 | 2026-10-06 07:05:00 | 2026-10-06 09:00:00 |
| 20 | instrucao | 2026-10-06 13:00:00 | 2026-10-06 13:30:00 | 2026-10-06 15:25:00 |
| 22 | particular | 2026-10-12 08:00:00 | 2026-10-12 08:10:00 | 2026-10-12 10:32:00 |
| 23 | particular | 2026-10-14 15:00:00 | 2026-10-14 15:05:00 | 2026-10-14 17:22:00 |
| 24 | traslado | 2026-10-15 08:00:00 | 2026-10-15 08:00:00 | 2026-10-15 09:42:00 |
| 25 | traslado | 2026-10-16 14:00:00 | 2026-10-16 14:10:00 | 2026-10-16 15:45:00 |
| 26 | instrucao | 2026-10-19 09:00:00 | 2026-10-19 09:00:00 | 2026-10-19 09:58:00 |
| 27 | instrucao | 2026-10-20 08:00:00 | 2026-10-20 08:05:00 | 2026-10-20 09:00:00 |
| 28 | instrucao | 2026-10-22 08:00:00 | 2026-10-22 08:10:00 | 2026-10-22 09:22:00 |
| 29 | instrucao | 2026-10-22 14:00:00 | 2026-10-22 14:05:00 | 2026-10-22 16:05:00 |
| 32 | instrucao | 2026-10-27 07:30:00 | 2026-10-27 07:30:00 | 2026-10-27 08:45:00 |
| 33 | instrucao | 2026-10-27 11:00:00 | 2026-10-27 11:05:00 | 2026-10-27 12:18:00 |

**Interpretação:** em outubro foram realizados 15 voos, sendo 8 de instrução, 4 particulares e 3 traslados; os voos cancelados no mesmo mês não aparecem por causa do filtro de situação.

## Q2. Aeródromos fora de Minas Gerais

**Descrição:** lista os aeródromos cadastrados nos estados de São Paulo, Rio de Janeiro e Goiás, destinos possíveis de navegações e traslados, ordenados por UF e cidade.

**Recursos:** SELECT, WHERE, IN, ORDER BY.

```sql
SELECT codigo_icao,
       nome,
       cidade,
       uf
FROM aerodromo
WHERE uf IN ('SP', 'RJ', 'GO')
ORDER BY uf, cidade;
```

**Saída (5 linhas):**

| codigo_icao | nome | cidade | uf |
| --- | --- | --- | --- |
| SBGO | Aeroporto de Goiânia | Goiânia | GO |
| SBJR | Aeroporto de Jacarepaguá | Rio de Janeiro | RJ |
| SBRJ | Aeroporto Santos Dumont | Rio de Janeiro | RJ |
| SBRP | Aeroporto Leite Lopes | Ribeirão Preto | SP |
| SBMT | Aeroporto Campo de Marte | São Paulo | SP |

**Interpretação:** dos 20 aeródromos cadastrados, 5 ficam fora de Minas Gerais; 4 deles (todos exceto o Santos Dumont) recebem ou originam voos registrados, como navegações particulares, de instrução e traslados.

## Q3. Fabricantes do catálogo de modelos

**Descrição:** lista, sem repetição, os fabricantes presentes no catálogo de modelos de aeronaves leves.

**Recursos:** SELECT, DISTINCT, ORDER BY.

```sql
SELECT DISTINCT fabricante
FROM modelo_aeronave
ORDER BY fabricante;
```

**Saída (8 linhas):**

| fabricante |
| --- |
| Aero Boero |
| Cessna |
| Cirrus |
| Companhia Aeronáutica Paulista |
| Embraer |
| Neiva |
| Piper |
| Tecnam |

**Interpretação:** os 15 modelos cadastrados pertencem a 8 fabricantes distintos; o DISTINCT elimina as repetições de Cessna, Piper e Tecnam, que têm mais de um modelo.

## Q4. Operadores que são aeroclubes

**Descrição:** lista nome, cidade e UF dos operadores cujo nome começa com "Aeroclube", ordenados por UF e nome.

**Recursos:** SELECT, WHERE, LIKE, ORDER BY.

```sql
SELECT nome,
       cidade,
       uf
FROM operador
WHERE nome LIKE 'Aeroclube%'
ORDER BY uf, nome;
```

**Saída (7 linhas):**

| nome | cidade | uf |
| --- | --- | --- |
| Aeroclube Asas do Oeste Mineiro | Divinópolis | MG |
| Aeroclube Asas do Vale do Aço | Ipatinga | MG |
| Aeroclube Cerrado Mineiro | Uberlândia | MG |
| Aeroclube Céu do Sul de Minas | Varginha | MG |
| Aeroclube Horizonte Mineiro | Belo Horizonte | MG |
| Aeroclube Serra Geral do Norte | Montes Claros | MG |
| Aeroclube Vale do Paraibuna | Juiz de Fora | MG |

**Interpretação:** 7 dos 16 operadores são aeroclubes, todos sediados em cidades de Minas Gerais.

## Q5. As 5 ocorrências mais recentes

**Descrição:** lista as 5 ocorrências com data e hora mais recentes, da mais nova para a mais antiga.

**Recursos:** SELECT, ORDER BY (DESC), LIMIT.

```sql
SELECT id_ocorrencia,
       id_voo,
       tipo,
       gravidade,
       data_hora
FROM ocorrencia
ORDER BY data_hora DESC
LIMIT 5;
```

**Saída (5 linhas):**

| id_ocorrencia | id_voo | tipo | gravidade | data_hora |
| --- | --- | --- | --- | --- |
| 18 | 34 | cancelamento | baixa | 2026-11-07 08:30:00 |
| 17 | 31 | cancelamento | baixa | 2026-10-24 18:00:00 |
| 16 | 31 | condicao_meteorologica | baixa | 2026-10-24 17:50:00 |
| 15 | 30 | cancelamento | baixa | 2026-10-23 07:45:00 |
| 14 | 30 | falha_tecnica | media | 2026-10-23 07:35:00 |

**Interpretação:** a ocorrência mais recente é o cancelamento do voo 34 em 07/11/2026; os voos 30 e 31 aparecem cada um com duas ocorrências, uma causa (falha técnica e condição meteorológica) seguida do cancelamento.

## Q6. Aeródromos com mais partidas

**Descrição:** conta os voos com partida em cada aeródromo e mantém apenas os aeródromos com pelo menos 2 partidas, do mais movimentado para o menos movimentado.

**Recursos:** INNER JOIN (2 tabelas: aerodromo, voo), GROUP BY, COUNT, HAVING, ORDER BY.

```sql
SELECT a.codigo_icao,
       a.nome,
       COUNT(v.id_voo) AS total_partidas
FROM aerodromo a
INNER JOIN voo v ON v.id_aerodromo_origem = a.id_aerodromo
GROUP BY a.id_aerodromo, a.codigo_icao, a.nome
HAVING COUNT(v.id_voo) >= 2
ORDER BY total_partidas DESC, a.codigo_icao;
```

**Saída (7 linhas):**

| codigo_icao | nome | total_partidas |
| --- | --- | --- |
| SBBH | Aeroporto da Pampulha | 13 |
| SBJF | Aeroporto Francisco Álvares de Assis | 5 |
| SBUL | Aeroporto de Uberlândia | 5 |
| SNPD | Aeroporto de Patos de Minas | 3 |
| SBJR | Aeroporto de Jacarepaguá | 2 |
| SBMK | Aeroporto de Montes Claros | 2 |
| SBVG | Aeroporto de Varginha | 2 |

**Interpretação:** a Pampulha concentra 13 das 39 partidas registradas, seguida de Juiz de Fora e Uberlândia, com 5 cada.

## Q7. Atraso médio e maior atraso de partida por operador

**Descrição:** para os voos realizados, calcula por operador a quantidade de voos, o atraso médio e o maior atraso de partida, em minutos.

**Recursos:** INNER JOIN (3 tabelas: voo, aeronave, operador), WHERE, GROUP BY, COUNT, AVG, MAX, ORDER BY.

```sql
SELECT o.nome AS operador,
       COUNT(v.id_voo) AS voos_realizados,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, v.partida_prevista, v.partida_real)), 1) AS atraso_medio_min,
       MAX(TIMESTAMPDIFF(MINUTE, v.partida_prevista, v.partida_real)) AS maior_atraso_min
FROM voo v
INNER JOIN aeronave a ON a.id_aeronave = v.id_aeronave
INNER JOIN operador o ON o.id_operador = a.id_operador
WHERE v.situacao = 'realizado'
GROUP BY o.id_operador, o.nome
ORDER BY atraso_medio_min DESC, o.nome;
```

**Saída (14 linhas):**

| operador | voos_realizados | atraso_medio_min | maior_atraso_min |
| --- | --- | --- | --- |
| Agropecuária Santa Helena Ltda. | 2 | 22.5 | 40 |
| Aeroclube Céu do Sul de Minas | 1 | 20.0 | 20 |
| Escola de Aviação Rumo Certo | 5 | 16.6 | 40 |
| Helena Duarte Vasconcelos | 2 | 15.0 | 30 |
| Aeroclube Asas do Oeste Mineiro | 1 | 10.0 | 10 |
| Escola de Aviação Cruzeiro Mineiro | 2 | 10.0 | 20 |
| Construtora Vale Verde Ltda. | 2 | 7.5 | 10 |
| Aeroclube Vale do Paraibuna | 3 | 5.7 | 10 |
| Aeroclube Cerrado Mineiro | 2 | 5.0 | 10 |
| Escola de Aviação Planalto Central | 2 | 5.0 | 10 |
| Aeroclube Horizonte Mineiro | 4 | 3.8 | 5 |
| Escola de Aviação Mantiqueira Sul | 1 | 3.0 | 3 |
| Ricardo Albuquerque Nogueira | 2 | 2.5 | 5 |
| Escola de Aviação Altitude | 1 | 0.0 | 0 |

**Interpretação:** a Agropecuária Santa Helena tem o maior atraso médio (22,5 minutos em 2 voos, um deles com 40 minutos de atraso por condição meteorológica); a Escola de Aviação Rumo Certo, operador com mais voos realizados (5), tem atraso médio de 16,6 minutos.

## Q8. Tempo de voo acumulado por aeronave

**Descrição:** para os voos realizados, calcula por aeronave a quantidade de voos, o total de minutos voados e as durações do voo mais curto e do mais longo.

**Recursos:** INNER JOIN (3 tabelas: aeronave, modelo_aeronave, voo), WHERE, GROUP BY, COUNT, SUM, MIN, MAX, ORDER BY.

```sql
SELECT a.matricula,
       m.nome_modelo AS modelo,
       COUNT(v.id_voo) AS voos_realizados,
       SUM(TIMESTAMPDIFF(MINUTE, v.partida_real, v.chegada_real)) AS minutos_voados,
       MIN(TIMESTAMPDIFF(MINUTE, v.partida_real, v.chegada_real)) AS voo_mais_curto_min,
       MAX(TIMESTAMPDIFF(MINUTE, v.partida_real, v.chegada_real)) AS voo_mais_longo_min
FROM aeronave a
INNER JOIN modelo_aeronave m ON m.id_modelo_aeronave = a.id_modelo_aeronave
INNER JOIN voo v ON v.id_aeronave = a.id_aeronave
WHERE v.situacao = 'realizado'
GROUP BY a.id_aeronave, a.matricula, m.nome_modelo
ORDER BY minutos_voados DESC, a.matricula;
```

**Saída (10 primeiras de 17 linhas):**

| matricula | modelo | voos_realizados | minutos_voados | voo_mais_curto_min | voo_mais_longo_min |
| --- | --- | --- | --- | --- | --- |
| PR-RCC | 172 Skyhawk | 4 | 387 | 77 | 115 |
| PR-VVD | PA-28-181 Archer | 2 | 279 | 137 | 142 |
| PR-SHA | PA-28-181 Archer | 2 | 217 | 107 | 110 |
| PR-GNB | PA-28-161 Warrior | 2 | 197 | 95 | 102 |
| PR-SOB | PA-28-161 Warrior | 2 | 192 | 72 | 120 |
| PT-RAN | 172 Skyhawk | 2 | 176 | 88 | 88 |
| PR-CZP | 172 Skyhawk | 2 | 153 | 75 | 78 |
| PT-OJB | 172 Skyhawk | 2 | 148 | 73 | 75 |
| PR-JDA | 172 Skyhawk | 2 | 133 | 65 | 68 |
| PS-HDV | SR20 | 2 | 124 | 62 | 62 |

**Interpretação:** a PR-RCC, um Cessna 172 Skyhawk, é a aeronave que mais voou (387 minutos em 4 voos); o 172 Skyhawk aparece em 5 das 10 primeiras posições.

## Q9. Pilotos com pelo menos 3 voos realizados

**Descrição:** para cada piloto, conta os voos realizados de que participou e soma os minutos de voo, mantendo apenas quem tem pelo menos 3 voos.

**Recursos:** INNER JOIN (3 tabelas: piloto, voo_piloto, voo), WHERE, GROUP BY, COUNT, SUM, HAVING, ORDER BY.

```sql
SELECT p.nome,
       p.categoria,
       COUNT(vp.id_voo) AS voos_realizados,
       SUM(TIMESTAMPDIFF(MINUTE, v.partida_real, v.chegada_real)) AS minutos_voados
FROM piloto p
INNER JOIN voo_piloto vp ON vp.id_piloto = p.id_piloto
INNER JOIN voo v ON v.id_voo = vp.id_voo
WHERE v.situacao = 'realizado'
GROUP BY p.id_piloto, p.nome, p.categoria
HAVING COUNT(vp.id_voo) >= 3
ORDER BY voos_realizados DESC, minutos_voados DESC;
```

**Saída (6 linhas):**

| nome | categoria | voos_realizados | minutos_voados |
| --- | --- | --- | --- |
| Juliana Mendes Prado | PC | 5 | 445 |
| Gabriel Ferreira Nunes | aluno | 4 | 387 |
| Sérgio Paiva Monteiro | PC | 4 | 383 |
| Carlos Eduardo Ramos | PC | 4 | 260 |
| Rafael Augusto Siqueira | PC | 3 | 248 |
| Mariana Souza Teixeira | aluno | 3 | 248 |

**Interpretação:** a instrutora Juliana Mendes Prado lidera com 5 voos e 445 minutos; Gabriel Ferreira Nunes, Sérgio Paiva Monteiro e Carlos Eduardo Ramos têm 4 voos cada, mas Carlos acumula bem menos minutos (260), porque seus voos são mais curtos.

## Q10. Setores do espaço aéreo mais atravessados

**Descrição:** conta as travessias de cada setor do espaço aéreo e calcula o tempo médio de permanência no setor, mantendo apenas setores com pelo menos 3 travessias.

**Recursos:** INNER JOIN (2 tabelas: setor_aereo, voo_setor), GROUP BY, COUNT, AVG, HAVING, ORDER BY.

```sql
SELECT s.sigla,
       s.nome,
       s.tipo,
       COUNT(vs.id_voo_setor) AS travessias,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, vs.horario_entrada, vs.horario_saida)), 1) AS permanencia_media_min
FROM setor_aereo s
INNER JOIN voo_setor vs ON vs.id_setor_aereo = s.id_setor_aereo
GROUP BY s.id_setor_aereo, s.sigla, s.nome, s.tipo
HAVING COUNT(vs.id_voo_setor) >= 3
ORDER BY travessias DESC, s.sigla;
```

**Saída (7 linhas):**

| sigla | nome | tipo | travessias | permanencia_media_min |
| --- | --- | --- | --- | --- |
| FIR-SBBS | FIR Brasília | FIR | 22 | 59.3 |
| CTR-SBBH | CTR Pampulha | CTR | 15 | 16.2 |
| TMA-BH | TMA Belo Horizonte | TMA | 12 | 29.4 |
| ATZ-SBJF | ATZ Juiz de Fora | ATZ | 9 | 12.3 |
| CTR-SBUL | CTR Uberlândia | CTR | 6 | 7.7 |
| CTR-SBJR | CTR Jacarepaguá | CTR | 4 | 6.5 |
| TMA-RJ | TMA Rio de Janeiro | TMA | 4 | 24.3 |

**Interpretação:** a FIR Brasília é o setor mais atravessado (22 travessias) e o de maior permanência média (59,3 minutos), porque cobre uma área extensa; as CTR e a ATZ, menores, são atravessadas em poucos minutos.

## Q11. Operadores com atraso médio acima da média geral

**Descrição:** a subconsulta calcula o atraso médio de partida de todos os voos realizados; a consulta externa calcula o atraso médio por operador e mantém apenas os operadores acima dessa média geral.

**Recursos:** subconsulta no HAVING, INNER JOIN (3 tabelas: voo, aeronave, operador), WHERE, GROUP BY, AVG, ORDER BY.

```sql
SELECT o.nome AS operador,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, v.partida_prevista, v.partida_real)), 1) AS atraso_medio_min
FROM voo v
INNER JOIN aeronave a ON a.id_aeronave = v.id_aeronave
INNER JOIN operador o ON o.id_operador = a.id_operador
WHERE v.situacao = 'realizado'
GROUP BY o.id_operador, o.nome
HAVING AVG(TIMESTAMPDIFF(MINUTE, v.partida_prevista, v.partida_real)) >
       (SELECT AVG(TIMESTAMPDIFF(MINUTE, partida_prevista, partida_real))
        FROM voo
        WHERE situacao = 'realizado')
ORDER BY atraso_medio_min DESC, o.nome;
```

**Saída (6 linhas):**

| operador | atraso_medio_min |
| --- | --- |
| Agropecuária Santa Helena Ltda. | 22.5 |
| Aeroclube Céu do Sul de Minas | 20.0 |
| Escola de Aviação Rumo Certo | 16.6 |
| Helena Duarte Vasconcelos | 15.0 |
| Aeroclube Asas do Oeste Mineiro | 10.0 |
| Escola de Aviação Cruzeiro Mineiro | 10.0 |

**Interpretação:** a média geral de atraso dos 30 voos realizados é de 9,4 minutos (valor obtido executando a subconsulta isoladamente); 6 dos 14 operadores com voos realizados ficam acima dela.

## Q12. Aeronaves sem nenhum voo registrado

**Descrição:** lista as aeronaves que não aparecem em nenhum voo, com sua situação e o operador responsável.

**Recursos:** LEFT JOIN, INNER JOIN, WHERE ... IS NULL, ORDER BY.

```sql
SELECT a.matricula,
       a.situacao,
       o.nome AS operador
FROM aeronave a
INNER JOIN operador o ON o.id_operador = a.id_operador
LEFT JOIN voo v ON v.id_aeronave = a.id_aeronave
WHERE v.id_voo IS NULL
ORDER BY a.matricula;
```

**Saída (5 linhas):**

| matricula | situacao | operador |
| --- | --- | --- |
| PP-GVA | ativa | Aeroclube Horizonte Mineiro |
| PR-ALC | manutencao | Escola de Aviação Altitude |
| PT-AQX | inativa | Aeroclube Asas do Vale do Aço |
| PT-BRG | manutencao | Aeroclube Asas do Oeste Mineiro |
| PT-IJD | ativa | Aeroclube Cerrado Mineiro |

**Interpretação:** das 24 aeronaves, 5 não têm voo registrado; três estão em manutenção ou inativas, o que explica a ausência de voos, e a PP-GVA e a PT-IJD estão ativas, mas não foram utilizadas no período.
