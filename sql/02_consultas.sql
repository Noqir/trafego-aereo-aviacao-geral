-- =====================================================================
-- Projeto Final de Banco de Dados
-- Sistema de registro e análise de operações de tráfego aéreo
-- Arquivo de consultas (executar após sql/01_banco.sql)
--
-- Q1 a Q5:  consultas simples (uma tabela)
-- Q6 a Q10: consultas com INNER JOIN e agregação
-- Q11:      consulta com subconsulta
-- Q12:      consulta com LEFT JOIN
--
-- Convenção usada nas consultas de atraso: o atraso de partida de um
-- voo realizado é a diferença, em minutos, entre a partida real e a
-- partida prevista, calculada com TIMESTAMPDIFF(MINUTE, inicio, fim).
-- =====================================================================

-- Garante a leitura e a exibição corretas dos acentos (UTF-8),
-- independentemente da configuração padrão do cliente.
SET NAMES utf8mb4;

USE trafego_aereo;

-- ---------------------------------------------------------------------
-- Q1. Quais voos foram realizados em outubro de 2026?
-- Retorna id do voo, finalidade e horários previstos e reais de partida,
-- em ordem cronológica.
-- Recursos: SELECT, WHERE, BETWEEN, ORDER BY.
-- ---------------------------------------------------------------------
SELECT id_voo,
       finalidade,
       partida_prevista,
       partida_real,
       chegada_real
FROM voo
WHERE situacao = 'realizado'
  AND partida_prevista BETWEEN '2026-10-01 00:00:00' AND '2026-10-31 23:59:59'
ORDER BY partida_prevista;

-- ---------------------------------------------------------------------
-- Q2. Quais aeródromos fora de Minas Gerais (estados de SP, RJ e GO)
-- estão cadastrados como destinos possíveis de navegações e traslados?
-- Retorna código ICAO, nome, cidade e UF, ordenados por UF e cidade.
-- Recursos: SELECT, WHERE, IN, ORDER BY.
-- ---------------------------------------------------------------------
SELECT codigo_icao,
       nome,
       cidade,
       uf
FROM aerodromo
WHERE uf IN ('SP', 'RJ', 'GO')
ORDER BY uf, cidade;

-- ---------------------------------------------------------------------
-- Q3. Quais fabricantes de aeronaves leves aparecem no catálogo de modelos?
-- Retorna a lista de fabricantes sem repetição, em ordem alfabética.
-- Recursos: SELECT, DISTINCT, ORDER BY.
-- ---------------------------------------------------------------------
SELECT DISTINCT fabricante
FROM modelo_aeronave
ORDER BY fabricante;

-- ---------------------------------------------------------------------
-- Q4. Quais operadores são aeroclubes?
-- Retorna nome, cidade e UF dos operadores cujo nome começa com
-- "Aeroclube", ordenados por UF e nome.
-- Recursos: SELECT, WHERE, LIKE, ORDER BY.
-- ---------------------------------------------------------------------
SELECT nome,
       cidade,
       uf
FROM operador
WHERE nome LIKE 'Aeroclube%'
ORDER BY uf, nome;

-- ---------------------------------------------------------------------
-- Q5. Quais foram as 5 ocorrências registradas mais recentemente?
-- Retorna id da ocorrência, voo, tipo, gravidade e data/hora, da mais
-- recente para a mais antiga.
-- Recursos: SELECT, ORDER BY (DESC), LIMIT.
-- ---------------------------------------------------------------------
SELECT id_ocorrencia,
       id_voo,
       tipo,
       gravidade,
       data_hora
FROM ocorrencia
ORDER BY data_hora DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- Q6. Quais aeródromos concentram mais partidas (pelo menos 2 voos)?
-- Retorna código ICAO, nome e quantidade de voos com partida no
-- aeródromo, do mais movimentado para o menos movimentado.
-- Recursos: INNER JOIN (2 tabelas: aerodromo, voo), GROUP BY, COUNT,
-- HAVING, ORDER BY.
-- ---------------------------------------------------------------------
SELECT a.codigo_icao,
       a.nome,
       COUNT(v.id_voo) AS total_partidas
FROM aerodromo a
INNER JOIN voo v ON v.id_aerodromo_origem = a.id_aerodromo
GROUP BY a.id_aerodromo, a.codigo_icao, a.nome
HAVING COUNT(v.id_voo) >= 2
ORDER BY total_partidas DESC, a.codigo_icao;

-- ---------------------------------------------------------------------
-- Q7. Qual é o atraso médio e o maior atraso de partida por operador?
-- Considera apenas voos realizados. Retorna o operador, a quantidade de
-- voos realizados, o atraso médio e o atraso máximo, em minutos.
-- Recursos: INNER JOIN (3 tabelas: voo, aeronave, operador), GROUP BY,
-- COUNT, AVG, MAX, ORDER BY.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Q8. Quanto tempo de voo cada aeronave acumulou?
-- Considera apenas voos realizados. Retorna matrícula, modelo,
-- quantidade de voos, total de minutos voados e a duração do voo mais
-- curto e do mais longo, da aeronave que mais voou para a que menos voou.
-- Recursos: INNER JOIN (3 tabelas: aeronave, modelo_aeronave, voo),
-- GROUP BY, COUNT, SUM, MIN, MAX, ORDER BY.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Q9. Quais pilotos participaram de pelo menos 3 voos realizados, e
-- quantos minutos voaram no total?
-- Retorna nome, categoria, quantidade de voos e soma dos minutos de voo.
-- Recursos: INNER JOIN (3 tabelas: piloto, voo_piloto, voo), GROUP BY,
-- COUNT, SUM, HAVING, ORDER BY.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Q10. Quais setores do espaço aéreo são atravessados por mais voos
-- (pelo menos 3 travessias), e quanto tempo os voos permanecem neles?
-- Retorna sigla, nome, tipo do setor, quantidade de travessias e tempo
-- médio de permanência no setor, em minutos.
-- Recursos: INNER JOIN (2 tabelas: setor_aereo, voo_setor), GROUP BY,
-- COUNT, AVG, HAVING, ORDER BY.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Q11. Quais operadores têm atraso médio de partida acima da média
-- geral de todos os voos realizados?
-- A subconsulta calcula a média geral de atraso; a consulta externa
-- calcula a média por operador e mantém só as que ficam acima dela.
-- Retorna operador e atraso médio, em minutos.
-- Recursos: subconsulta no HAVING, INNER JOIN (3 tabelas), GROUP BY, AVG.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Q12. Quais aeronaves não têm nenhum voo registrado?
-- O LEFT JOIN mantém todas as aeronaves; as que não têm voo ficam com
-- as colunas de voo nulas e são selecionadas por v.id_voo IS NULL.
-- Retorna matrícula, situação da aeronave e operador responsável.
-- Recursos: LEFT JOIN, INNER JOIN, WHERE ... IS NULL, ORDER BY.
-- ---------------------------------------------------------------------
SELECT a.matricula,
       a.situacao,
       o.nome AS operador
FROM aeronave a
INNER JOIN operador o ON o.id_operador = a.id_operador
LEFT JOIN voo v ON v.id_aeronave = a.id_aeronave
WHERE v.id_voo IS NULL
ORDER BY a.matricula;
